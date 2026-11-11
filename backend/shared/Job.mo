import { type LocOwner } "Loc";
import { ReqUser = { type ReqUser } } "Req";

module {
  public type Job = {
    #jobBucketUsers: JobBucketUsers;
  };

  public type JobBucketUsers = {
    #updateUserIndex: {kind: ReqUser; key: Text; owner: LocOwner };
    #removeUserIndex: {kind: ReqUser; key: Text; };
  };
}