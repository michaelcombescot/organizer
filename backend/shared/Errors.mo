module {
    public type HandlerErr = {
        #errInterCanisterCall: Text;
        #errMustNotBeAnonymous;
        #errMustBeController;
        #errForbidden;
        #errNotFound;
        #errValidation: [{
            field: Text;
            message: Text;
        }];
    };
}