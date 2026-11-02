module {
  public type Job = {
    #jobBucketUsers: JobBucketUsers;
  };

  public type JobBucketUsers = {
    #removeOldName: { searchBucket: Principal; oldName: Text; };
    #removeOldEmail: { searchBucket: Principal; oldEmail: Text; };
  };
}