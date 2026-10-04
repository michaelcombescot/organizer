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
  let jobRunning = Map.empty<Nat, ()>();

  // ===== WORKERS =====

  ignore Timer.recurringTimer<system>(
    #seconds(recurringDelay), func () : async () {
      var futures = List.empty<(Nat, async Result<(), Text>)>();

      for ((jobId, job) in memJobs.entries()) {
        if ( jobRunning.containsKey(jobId) ) { continue };

        jobRunning.add(jobId, ());

        List.add(futures, (jobId, executeJob(job)));
      };

      for ((jobId, f) in List.values(futures)) {
        try {
          switch ( await f ) {
            case (#ok(())) memJobs.remove(jobId);
            case (#err(e)) Debug.print("Job execution failed: " # e);
          };
        } catch (e) {
          Debug.print("Unexpected error during job execution: " # e.message());
        };

        jobRunning.remove(jobId);
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
      jobRunning.add(jobId, ());
      
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

      jobRunning.remove(jobId);
    };

    ignore execution;

    jobId
  };
}