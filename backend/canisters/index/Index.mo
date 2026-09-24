import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Blob "mo:core/Blob";
import Error "mo:core/Error";
import MixinJobTopUpCycles "../mixins/MixinJobTopUpCycles";
import UserMapping "../../shared/UserMapping";
import Errors "../../shared/Errors";
import BucketUsers "../buckets/bucketUsers";

shared ({ caller = owner }) persistent actor class Index() = this {
    let thisPrincipal = Principal.fromActor(this);

    include MixinJobTopUpCycles<system>({
        adminPrincipal    = owner;
        canisterPrincipal = thisPrincipal;
        kind              = #index;
    });

    // ===== MEMORY =====

    var memoryUsersMapping: UserMapping.UserRing = [];

    // ===== JOBS =====

    

    // ===== SYSTEM =====

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemUpdateUserMapping : () -> (mapping : UserMapping.UserRing);
            #handlerFetchOrCreateUser : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 5000 ) { return false; };

        switch ( params.msg ) {
            case (#systemUpdateUserMapping(_)) params.caller.isController();
            case (#handlerFetchOrCreateUser(_)) true;
        }
    };

    public shared ({ caller }) func systemUpdateUserMapping(mapping: UserMapping.UserRing) : async Result.Result<(), Errors.HandlerErr> {
        if ( not Principal.isController(caller) ) { return #err(#errMustBeController); };
    
        memoryUsersMapping := mapping;
        #ok(());
    };

    // ===== HANDLERS USERS =====

    public shared ({ caller }) func handlerCreateUser(name: Text, email: Text) : async Result.Result<Principal, Errors.HandlerErr> {
        let bucketPrincipal = UserMapping.helperFindUserBucket(memoryUsersMapping, caller);

        try {
            switch ( await (actor(Principal.toText(bucketPrincipal)): BucketUsers.BucketUsers).handlerCreateUser(caller, name, email) ) {
                case (#ok(_)) #ok(bucketPrincipal);
                case (#err(e)) #err(e);
            }
        } catch (e) {
            #err(#errInterCanisterCall(e.message()))
        }
    };
};