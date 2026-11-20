import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Time "mo:core/Time";
import { type Result } "mo:core/Result";
import Error "mo:core/Error";
import Principal "mo:core/Principal";
import Iter "mo:core/Iter";
import { type Job } "../Job";
import { type HandlerErr } "../Errors";

mixin<system>({ executeJob: (Job) -> async Result<(), HandlerErr> }) {
  // ===== CONFIG =====

  let JOB_MAX_CONCURRENT = 250;
  let JOB_MAX_RETRY = 3;
  let JOB_RETRY_DELAY_NS = 60_000_000_000; // 1 minute in nanoseconds

  // ===== STRUCTURES =====

  type JobWrapper = {
    jobId: Nat;
    job: Job;
    nbRetry: Nat;
    retryAt: Time.Time;
    error: ?HandlerErr
  };

  // ===== MEMORY =====
  
  var memLastAllJobProcessedTime : Time.Time = 0;
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

  // Process Job

  func processJob(jobWrapper: JobWrapper) : async Result<(), HandlerErr> {
    if (memJobRunning.size() > JOB_MAX_CONCURRENT) return #err(#errTooManyConcurrentJobs);
    if (memJobRunning.containsKey(jobWrapper.jobId)) return #err(#errJobAlreadyRunning);
    if (Time.now() < jobWrapper.retryAt) return #err(#errJobNotReady);

    func handleFailure(jobWrapper: JobWrapper) : Result<(), HandlerErr> {
      let updatedJob = { jobWrapper with nbRetry = jobWrapper.nbRetry + 1; retryAt = Time.now() + JOB_RETRY_DELAY_NS };
      
      if (updatedJob.nbRetry >= JOB_MAX_RETRY) {
        memJobFailed.add(updatedJob.jobId, updatedJob);
        memJobs.remove(updatedJob.jobId);
      } else {
        memJobs.add(updatedJob.jobId, updatedJob);
      };

      let msg = "Job failed after " # updatedJob.nbRetry.toText() # " retries, error: " # debug_show(jobWrapper.error);
      #err(#errJobFailed(msg))
    };

    try {
      memJobRunning.add(jobWrapper.jobId, ());
      
      switch (await executeJob(jobWrapper.job)) {
        case (#ok(())) {
          memJobs.remove(jobWrapper.jobId);
          #ok;
        };
        case (#err(e)) handleFailure({jobWrapper with error = ?e });
      }
    } catch e {
      handleFailure({jobWrapper with error = ?#errInterCanisterCall(e.message())})
    } finally {
      memJobRunning.remove(jobWrapper.jobId);
    }
  };

  func createAndProcessJob(job: Job) : async Result<(), HandlerErr> {
    // this is a way to trigger a retry for all jobs without a timer, at minimal cost
    await processAllJobs();

    let jobWrapper = createJob(job);
    await processJob(jobWrapper)
  };

  // Process all jobs

  func processAllJobs() : async () {
    if (memAllJobsProcessing) return;
    if (memJobs.size() == 0) return;
    if (Time.now() - memLastAllJobProcessedTime < JOB_RETRY_DELAY_NS) return;

    memAllJobsProcessing := true;

    let snapshot = memJobs.values().toArray();

    ignore async {
      try {
        for (jobWrapper in snapshot.values()) {
          let ?jobInMemory = memJobs.get(jobWrapper.jobId) else continue;
          ignore await processJob(jobWrapper);
        };
      } finally {
        memAllJobsProcessing := false;
        memLastAllJobProcessedTime := Time.now();
      }
    };
  };

  // ===== HANDLERS =====

  // Create a new job

  public shared ({ caller }) func handlerCreateAndProcessJob(job: Job) : async Result<(), HandlerErr> {
    if (not caller.isController()) return #err(#errMustBeController);

    await createAndProcessJob(job)
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

    #ok
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