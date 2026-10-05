import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Timer "mo:core/Timer";
import { type Result } "mo:core/Result";
import Debug "mo:core/Debug";
import List "mo:core/List";
import Error "mo:core/Error";
import { Job = {type Job} } "../../models/Job";

mixin<system>(recurringDelay: Nat, executeJob: (Job) -> async Result<(), Text>) {
  // ===== MEMORY =====

  var nextJobId = 0;
  let memJobs = Map.empty<Nat, Job>();
  let memJobRunning = Map.empty<Nat, ()>();
  let batchSize = 400;

  // ===== WORKERS =====

  ignore Timer.recurringTimer<system>(
  #seconds(recurringDelay), func () : async () {
    var batch = List.empty<(Nat, async Result<(), Text>)>();
    var count = 0;

    for ((jobId, job) in memJobs.entries()) {
      if ( memJobRunning.containsKey(jobId) ) { continue };

      List.add(batch, (jobId, executeJob(job)));
      count += 1;

      if ( count >= batchSize ) {
        // await this batch before dispatching more
        for ((jobId, f) in List.values(batch)) {
          try {
            switch ( await f ) {
              case (#ok(())) memJobs.remove(jobId);
              case (#err(e)) Debug.print("Job execution failed: " # e);
            };
          } catch (e) {
            Debug.print("Job execution threw: " # Error.message(e));
          };
        };

        batch := List.empty<(Nat, async Result<(), Text>)>();
        count := 0;
      };
    };

    // handle any remaining jobs smaller than a full batch
    for ((jobId, f) in List.values(batch)) {
      try {
        switch ( await f ) {
          case (#ok(())) memJobs.remove(jobId);
          case (#err(e)) Debug.print("Job execution failed: " # e);
        };
      } catch (e) {
        Debug.print("Job execution threw: " # Error.message(e));
      };
    };
  }
);

  // ===== HELPERS =====

  func create_job(job: Job) : Nat {
    let jobId = nextJobId;
    memJobs.add(jobId, job);
    nextJobId += 1;
    jobId;
  };

  func createAndExecuteJob(job: Job) : async Nat {
    let jobId = create_job(job);
    
    let execution : async () = async {
      memJobRunning.add(jobId, ());
      
      let jobToExecute =switch ( memJobs.get(jobId) ) {
        case (?jobToExecute) jobToExecute;
        case (null) return ();
      };

      try {
        switch ( await executeJob(jobToExecute) ) {
          case (#ok(())) memJobs.remove(jobId);
          case (#err(e)) Debug.print("Job execution failed: " #e);
        };
      } catch (e) {
        Debug.print("Unexpected error during job execution: " # e.message());
      };

      memJobRunning.remove(jobId);
    };

    ignore execution;

    jobId
  };
}