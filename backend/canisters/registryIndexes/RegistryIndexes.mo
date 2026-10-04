import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import Result "mo:core/Result";
import Canisters "../../shared/Canisters";

import Errors "../../shared/Errors";
import MixinHandlersKnownCanisters "../../shared/mixins/MixinKnownCanisters";

shared ({ caller = owner }) persistent actor class RegistryIndexes(adminPrincipal: Principal) = this {
    include MixinHandlersKnownCanisters({
      alreadyKnown = [(adminPrincipal, #admin)]
    });

    // ===== MEMORY =====

    let memIndexes = Map.empty<Principal, ()>();

    // ===== ADMIN =====

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
          #getIndexes : () -> ();
          #handlerAddKnownCanisters : () -> (canisters : [(Principal, Canisters.CanisterKind)]);
          #handlerRemoveKnownCanisters : () -> (canisters : [(Principal, Canisters.CanisterKind)])
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( Principal.isAnonymous(params.caller) ) return false;

        if ( Blob.size(params.arg) > 5000 ) return false;

        switch (params.msg) {
            case (#getIndexes(_)) true;
            case (#handlerAddKnownCanisters(_)) params.caller.isController();
            case (#handlerRemoveKnownCanisters(_)) params.caller.isController();
        }
    };

    // ===== HANDLERS =====

    public query ({ caller }) func getIndexes() : async Result.Result<[Principal], Errors.HandlerErr> {
        if ( Principal.isAnonymous(caller) ) return #err(#errMustNotBeAnonymous);

        #ok(memIndexes.keys().toArray())
    };
}