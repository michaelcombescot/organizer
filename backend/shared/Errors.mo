module {
  public type ErrHandler = {
    // System
    #errSystem: Text;
    #errInterCanisterCall: Text;
    #errUpdateOngoing;

    // Permissions
    #errMustNotBeAnonymous;
    #errMustBeController;
    #errForbidden;
    #errCannotVerifyCaller;

    // Request
    #errGuarded;
    #errNotFound: Text;
    #errMemoryLimitReached; // used when a canister memory limit is reached
    #errBadRequest: Text;
    #errWrongCanister; // used when a bucket/search is selected albeit it's the wrong range

    // memory
    #errCanisterFull; // used when a canister memory is full

    // Index
    #errIndexAlreadyExists; // used when an index entry already exists
    #errIndexNotFound;

    // Validations
    #errValidation: [ErrValidation];
    
    // Jobs
    #errJob: ErrJob;
  };

  public type ErrValidation = {
    #alreadyExists: { field: Text };
    #badLength: {field: Text; min: Nat; max: Nat};
  };

  public type ErrJob = {
    #errHandler: ErrHandler;
    #errJobFailed: Text;
    #errTooManyConcurrentJobs;
    #errJobAlreadyRunning;
    #errJobNotReady;
  };
}