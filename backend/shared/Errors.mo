module {
    public type HandlerErr = {
        #errInterCanisterCall: Text;
        #errMustNotBeAnonymous;
        #errMustBeController;
        #errForbidden;
        #errNotFound;
        #errBadRequest: Text;
        #errMissingCanister;
        #errBadCanister;
        #errValidation: [ValidationErr];
    };

    public type ValidationErr = {
        field: Text;
        message: Text;
    };

    public let ALREADY_TAKEN = "ALREADY_TAKEN";
    public let RESERVATION_EXPIRED = "RESERVATION_EXPIRED";
}