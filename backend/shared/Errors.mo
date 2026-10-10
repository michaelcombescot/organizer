module {
    public type HandlerErr = {
        #errInterCanisterCall: Text;
        #errMustNotBeAnonymous;
        #errMustBeController;
        #errForbidden;
        #errNotFound;
        #errBadRequest: Text;
        #errMissingCanister;
        #errValidation: [{
            field: Text;
            message: Text;
        }];
    };
}