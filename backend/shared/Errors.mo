module {
  public type HandlerErr = {
    #errSystem: Text;
    #errInterCanisterCall: Text;
    #errMustNotBeAnonymous;
    #errMustBeController;
    #errForbidden;
    #errCannotVerifyCaller;
    #errNotFound;
    #errMemoryLimitReached; // used when a canister memory limit is reached
    #errBadRequest: Text;
    #errWrongCanister; // used when a bucket/search is selected albeit it's the wrong range
    #errCanisterFull; // used when a canister memory is full
    #errIndexAlreadyExists; // used when an index entry already exists
    #errValidation: [ValidationErr];
    #errUpdateFailed: { field: Text };
  };

  public type ValidationErr = {
    #alreadyExists: { field: Text };
    #badLength: {field: Text; min: Nat; max: Nat};
  };
}