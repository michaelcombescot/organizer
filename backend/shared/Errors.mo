module {
    public type HandlerErr = {
        #errInterCanisterCall: Text;
        #errMustNotBeAnonymous;
        #errMustBeController;
        #errForbidden;
        #errNotFound;
        #errMissingCanister;
        #errValidation: [{
            field: Text;
            message: Text;
        }];
    };
}