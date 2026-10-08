import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Timer "mo:core/Timer";
import { type Result } "mo:core/Result";
import Debug "mo:core/Debug";
import Error "mo:core/Error";
import Time "mo:core/Time";
import Principal "mo:core/Principal";
import Iter "mo:core/Iter";
import { Job = {type Job} } "../../models/Job";
import Configs "../../Configs";
import { type HandlerErr } "../Errors";

mixin<system>(recurringDelay: Nat, executeJob: (Job) -> async Result<(), Text>) {
  // ===== STRUCTURES =====

  type JobWrapper = {
    jobId: Nat;
    job: Job;
    nbRetry: Nat;
    retryAt: Time.Time;
  };

  type InspectParamsMsg = {
    #handlerRequeueFailedJobImmediatly : () -> (jobId : Nat);
    #handlerRequeueAllFailedJobs : () -> ();
    #handlerGetFailedJobs : () -> ();
  };

  // ===== MEMORY =====
  
  var nextJobId = 0;
  let memJobs = Map.empty<Nat, JobWrapper>();
  let memJobRunning = Map.empty<Nat, ()>();
  let memJobFailed = Map.empty<Nat, JobWrapper>();

  // ===== HELPERS =====

  func createJob(job: Job) : JobWrapper {
    let jobId = nextJobId;

    var jobWrapper : JobWrapper = {
      jobId = jobId;
      job = job;
      nbRetry = 0;
      retryAt = Time.now();
    };
    
    memJobs.add(jobId, jobWrapper);
    nextJobId += 1;
    jobWrapper
  };

  func processJob(jobWrapper: JobWrapper) : async () {
    if (memJobRunning.size() > Configs.JOB_MAX_CONCURRENT) return;
    if (memJobRunning.containsKey(jobWrapper.jobId)) return;
    if (Time.now() < jobWrapper.retryAt) return;

    memJobRunning.add(jobWrapper.jobId, ());

    ignore ((async {
      try {
        switch (await executeJob(jobWrapper.job)) {
          case (#ok(())) {
            memJobs.remove(jobWrapper.jobId);
          };
          case (#err(e)) {
            Debug.print("Job execution failed: " # e);
            handleJobFailure(jobWrapper);
          };
        };
      } catch (e) {
        Debug.print("Job execution threw: " # Error.message(e));
        handleJobFailure(jobWrapper);
      };

      memJobRunning.remove(jobWrapper.jobId);
    }) : async ()); 
  };

  func createAndProcessJob(job: Job) : async JobWrapper {
    let jobWrapper = createJob(job);
    ignore processJob(jobWrapper);
    jobWrapper
  };

  func handleJobFailure(job: JobWrapper) : () {
    let updatedJob = { job with nbRetry = job.nbRetry + 1; retryAt = Time.now() + Configs.JOB_RETRY_DELAY };
    
    if (updatedJob.nbRetry >= Configs.JOB_MAX_RETRY) {
      memJobFailed.add(updatedJob.jobId, updatedJob);
      memJobs.remove(updatedJob.jobId);
    } else {
      memJobs.add(updatedJob.jobId, updatedJob);
    }
  };

  // ===== TIMERS =====

  ignore Timer.recurringTimer<system>(
    #seconds(recurringDelay), 
    func () : async () {
      
      for ((jobId, jobWrapper) in memJobs.entries()) {
        ignore processJob(jobWrapper);
      };
    }
  );

  // ===== FAILED JOB MANAGEMENT =====

  // Allows you (or an admin) to manually put a permanently failed job back into the queue
  public shared ({ caller }) func handlerRequeueFailedJobImmediatly(jobId: Nat) : async Result<(), HandlerErr> {
    if (not Principal.isController(caller)) return #err(#errMustBeController);

    let ?failedJob = memJobFailed.get(jobId) else return #err(#errNotFound);
    
    let updatedJob = { failedJob with nbRetry = 0; retryAt = Time.now() };

    memJobFailed.remove(jobId);
    memJobs.add(jobId, updatedJob);

    ignore processJob(updatedJob);

    return #ok(());
  };

  public shared ({ caller }) func handlerRequeueAllFailedJobs() : async Result<(), HandlerErr> {
    if (not Principal.isController(caller)) return #err(#errMustBeController);

    let failedEntries = memJobFailed.entries().toArray();

    for ((jobId, failedJob) in failedEntries.values()) {
      let updatedJob = { failedJob with nbRetry = 0; retryAt = Time.now() };

      memJobFailed.remove(jobId);
      memJobs.add(jobId, updatedJob);
    };
    
    return #ok(());
  };

  public query ({ caller }) func handlerGetFailedJobs() : async Result<[JobWrapper], HandlerErr> {
    if (not Principal.isController(caller)) return #err(#errMustBeController);

    #ok(memJobFailed.values().toArray())
  };
}