import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import Result "mo:core/Result";
import { type HandlerErr } "../../shared/Errors";
import { Kind = {type CanisterKind} } "../../shared/Canisters";
import MixinCanistersByPrincipal "../../shared/mixins/MixinCanistersByPrincipal";

shared ({ caller = owner }) persistent actor class RegistryIndexes(canisters: [Principal]) = this {
    include MixinCanistersByPrincipal(canisters);

    // ===== MEMORY =====

    let memIndexes = Map.empty<Principal, ()>();

    // ===== ADMIN =====

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
          #handlerGetIndexes : () -> ();
        } or InspectParamsMsgKnownCanistersByPrincipal
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller.isAnonymous() ) return false;

        if ( Blob.size(params.arg) > 5000 ) return false;

        switch (params.msg) {
            case (#handlerGetIndexes(_)) true;
            case (#handlerAddKnownCanistersByPrincipal(_)) params.caller.isController();
            case (#handlerRemoveKnownCanistersByPrincipal(_)) params.caller.isController();
        }
    };

    // ===== HANDLERS =====

    public query ({ caller }) func handlerGetIndexes() : async Result.Result<[Principal], HandlerErr> {
        if ( caller.isAnonymous() ) return #err(#errForbidden);

        #ok(memIndexes.keys().toArray())
    };
}