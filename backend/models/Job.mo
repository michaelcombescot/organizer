import { Kind = {type CanisterKind} } "../shared/Canisters";

module Job {
  public type Job = {
    #jobAdmin: JobAdmin.JobAdmin;
    #jobWorkerApp: JobWorkerApp.JobWorkerAppJob;
  };  
};

module JobAdmin {
  public type JobAdmin = {
    #broadcastCanisters: BroadcastCanisters;
  };

  type BroadcastCanisters = {
    targets: [Principal];
    canisters: [(Principal, CanisterKind)];
  };
};

module JobWorkerApp {
  public type JobWorkerAppJob = {
  };
};