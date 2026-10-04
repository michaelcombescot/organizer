import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Blob "mo:core/Blob";
import MixinHandlersKnownCanisters "../../shared/mixins/MixinKnownCanisters";
import UserMapping "../../shared/UserMapping";
import Errors "../../shared/Errors";
import Canisters "../../shared/Canisters";

shared ({ caller = owner }) persistent actor class Index(knownCanisters: [(Principal, Canisters.CanisterKind)]) = this {
    include MixinHandlersKnownCanisters({
      alreadyKnown = knownCanisters
    });

    // ===== MEMORY =====

    var memoryUsersMapping: UserMapping.UserRing = [];

    // ===== SYSTEM =====

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
          #systemUpdateUserMapping : () -> (mapping : UserMapping.UserRing);
          #handlerAddKnownCanisters : () -> (canisters : [(Principal, Canisters.CanisterKind)]);
          #handlerRemoveKnownCanisters : () -> (canisters : [(Principal, Canisters.CanisterKind)]);
          #handlerGetCurrentUserBucket : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 5000 ) { return false; };

        switch ( params.msg ) {
            case (#systemUpdateUserMapping(_)) params.caller.isController();
            case (#handlerAddKnownCanisters(_)) params.caller.isController();
            case (#handlerRemoveKnownCanisters(_)) params.caller.isController();
            case (#handlerGetCurrentUserBucket(_)) true;
        }
    };

    public shared ({ caller }) func systemUpdateUserMapping(mapping: UserMapping.UserRing) : async Result.Result<(), Errors.HandlerErr> {
      if ( not Principal.isController(caller) ) { return #err(#errMustBeController); };
  
      memoryUsersMapping := mapping;
      #ok(());
    };

    // ===== HANDLERS USERS =====

    public query ({ caller }) func handlerGetCurrentUserBucket() : async Result.Result<Principal, Errors.HandlerErr> {
      #ok(UserMapping.helperFindUserBucket(memoryUsersMapping, caller))
    };
};