import { type LocOwner } "Loc";
import { ReqUser = { type ReqUser } } "Req";
import { type Mapping } "Canisters";
import Principal "mo:core/Principal";
import Time "mo:core/Time";
import { type ErrJob } "Errors";

module {
  public type JobWrapper = {
    jobId: Nat;
    job: Job;
    nbRetry: Nat;
    retryAt: Time.Time;
    error: ?ErrJob;
  };

  public type Job = {
    #jobFactory: JobFactory;
    #jobBucketUsers: JobBucketUsers;
  };

  public type JobFactory = {
    #sendMappingTo: Principal;
  };

  public type JobBucketUsers = {
    #updateUserIndex: {kind: ReqUser; key: Text; owner: LocOwner };
    #removeUserIndex: {kind: ReqUser; key: Text; };
  };
}