import { type LocOwner } "Loc";
import { ReqUser = { type ReqUser } } "Req";
import { type Mapping } "Canisters";
import Principal "mo:core/Principal";

module {
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