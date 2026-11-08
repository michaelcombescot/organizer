import { type LocPerId; type LocPerPrincipal } "Loc";

module {
  public type Job = {
    #jobBucketUsers: JobBucketUsers;
  };

  public type JobBucketUsers = {
    #addPrincipalSearch: { newPrincipal: Principal; loc: LocPerPrincipal };
    #addNameSearch: { newName: Text; loc: LocPerPrincipal};
    #addEmailSearch: { newEmail: Text; loc: LocPerPrincipal};
    #removePrincipalSearch: { oldPrincipal: Principal; };
    #removeOldNameSearch: { oldName: Text; };
    #removeOldEmailSearch: { oldEmail: Text; };
  };
}