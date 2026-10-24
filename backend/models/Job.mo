import { CanisterKind = {type CanisterKind} } "../shared/Canisters";

module {
  public type Job = {
    #jobAdmin: JobAdmin;
    #jobWorkerApp: JobWorkerAppJob;
    #jobBucketUsers: JobBucketUsersJob;
  };

  public type JobAdmin = {
    #broadcastIndex: { targets: [Principal]; indexes: [Principal] };
    #broadcastBucket: { targets: [Principal]; canisters: [(CanisterKind, Principal)] };
    #broadcastSearch: { targets: [Principal]; canisters: [(CanisterKind, Principal)] };
  };

  public type JobWorkerAppJob = {
  };

  public type JobBucketUsersJob = {
    #sendFieldsUpdate: { name: Text; email: Text}
  };
};