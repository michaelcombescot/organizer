import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Timer "mo:core/Timer";
import Time "mo:core/Time";
import { type Result } "mo:core/Result";
import Error "mo:core/Error";
import Principal "mo:core/Principal";
import Iter "mo:core/Iter";
import { type Job } "../Job";
import { type HandlerErr } "../Errors";

mixin<system>({
  useTimer: Bool;
  timerRetryDelayNs: ?Nat;
  executeJob: (Job) -> async Result<(), HandlerErr>
}) {
  // ===== CONFIG =====

  let JOB_MAX_CONCURRENT = 250;
  let JOB_RETRY_DELAY_NS = switch (timerRetryDelayNs) { case (?d) d; case null 60_000_000_000 };
  let JOB_MAX_RETRY = 3;

  // ===== STRUCTURES =====

  type JobWrapper = {
    jobId: Nat;
    job: Job;
    nbRetry: Nat;
    retryAt: Time.Time;
    error: ?HandlerErr
  };

  type InspectParamsMsgJobs = {
    #handlerCreateAndProcessJob : (job: Job) -> ();
    #handlerRequeueFailedJob : () -> (jobId : Nat);
    #handlerRequeueAllFailedJobs : () -> ();
    #handlerGetFailedJobs : () -> ();
  };

  // ===== MEMORY =====
  
  var memLastProcessedTime : Time.Time = 0;
  var memAllJobsProcessing = false;

  var nextJobId = 0;
  let memJobs = Map.empty<Nat, JobWrapper>();
  let memJobRunning = Map.empty<Nat, ()>();
  let memJobFailed = Map.empty<Nat, JobWrapper>();

  // ===== HELPERS =====

  // Create a new job

  func createJob(job: Job) : JobWrapper {
    var jobWrapper : JobWrapper = {
      jobId = nextJobId;
      job = job;
      nbRetry = 0;
      retryAt = Time.now();
      error = null;
    };
    
    memJobs.add(jobWrapper.jobId, jobWrapper);
    nextJobId += 1;

    jobWrapper
  };

  func createAndExecuteJob({job: Job; allowRetry: Bool}) : async Result<(), HandlerErr> {
    let jobWrapper = createJob(job);
    let resp = switch (await executeJob(job)) {
      case (#ok(())) #ok;
      case (#err(e)) return #err(e);
    };

    memJobs.remove(jobWrapper.jobId);

    // If the timer job is not used, we still need a way to process jobs in the qeueue.
    // This is a solution to launch all jobs eventually, trigger each time a new jobs is executed.
    // launch asynchronously all remaining jobs in the queue.
    ignore async { ignore processAllJobs() };

    resp
  };

  // Process Job

  func processJob(jobWrapper: JobWrapper) : async () {
    if (memJobRunning.size() > JOB_MAX_CONCURRENT) return;
    if (memJobRunning.containsKey(jobWrapper.jobId)) return;
    if (Time.now() < jobWrapper.retryAt) return;

    memJobRunning.add(jobWrapper.jobId, ());

    ignore async {
      try {
        switch (await executeJob(jobWrapper.job)) {
          case (#ok(())) {
            memJobs.remove(jobWrapper.jobId);
          };
          case (#err(e)) {
            handleJobFailure({ jobWrapper with error = ?e });
          };
        };
      } catch (e) {
        handleJobFailure({ jobWrapper with error = ?(#errJobExec(e.message())) });
      };

      memJobRunning.remove(jobWrapper.jobId);
    };
  };

  func handleJobFailure(job: JobWrapper) : () {
    let updatedJob = { job with nbRetry = job.nbRetry + 1; retryAt = Time.now() + JOB_RETRY_DELAY_NS };
    
    if (updatedJob.nbRetry >= JOB_MAX_RETRY) {
      memJobFailed.add(updatedJob.jobId, updatedJob);
      memJobs.remove(updatedJob.jobId);
    } else {
      memJobs.add(updatedJob.jobId, updatedJob);
    }
  };

  func createAndProcessJob(job: Job) : async JobWrapper {
    let jobWrapper = createJob(job);
    ignore processJob(jobWrapper);
    jobWrapper
  };

  // Process all jobs

  func processAllJobs() : async () {
    if (memAllJobsProcessing) return;
    if (memJobs.size() == 0) return;
    if (Time.now() - memLastProcessedTime < JOB_RETRY_DELAY_NS) return;

    memAllJobsProcessing := true;

    for ((jobId, jobWrapper) in memJobs.entries()) {
      ignore processJob(jobWrapper);
    };
    
    memLastProcessedTime := Time.now();
    memAllJobsProcessing := false;
  };

  // ===== TIMERS =====

  if (useTimer) {
    ignore Timer.recurringTimer<system>(
      #seconds(JOB_RETRY_DELAY_NS / 1_000_000_000), 
      processAllJobs
    );
  };

  // ===== HANDLERS =====

  // Create a new job

  public shared ({ caller }) func handlerCreateAndProcessJob(job: Job) : async Result<(), HandlerErr> {
    if (not caller.isController()) return #err(#errMustBeController);

    ignore createAndProcessJob(job);

    #ok
  };

  // Failed Jobs management

  public query ({ caller }) func handlerGetFailedJobs() : async Result<[JobWrapper], HandlerErr> {
    if (not caller.isController()) return #err(#errMustBeController);

    #ok(memJobFailed.values().toArray())
  };

  public shared ({ caller }) func handlerRequeueFailedJob(jobId: Nat) : async Result<(), HandlerErr> {
    if (not caller.isController()) return #err(#errMustBeController);

    let ?failedJob = memJobFailed.get(jobId) else return #err(#errNotFound("Failed to find failed job with ID " # jobId.toText()));
    
    let updatedJob = { failedJob with nbRetry = 0; retryAt = Time.now() };

    memJobFailed.remove(jobId);
    memJobs.add(jobId, updatedJob);

    ignore processJob(updatedJob);

    return #ok(());
  };

  public shared ({ caller }) func handlerRequeueAllFailedJobs() : async Result<(), HandlerErr> {
    if (not caller.isController()) return #err(#errMustBeController);

    let failedEntries = memJobFailed.entries().toArray();

    for ((jobId, failedJob) in failedEntries.values()) {
      let updatedJob = { failedJob with nbRetry = 0; retryAt = Time.now() };

      memJobFailed.remove(jobId);
      memJobs.add(jobId, updatedJob);
    };
    
    return #ok(());
  };
}