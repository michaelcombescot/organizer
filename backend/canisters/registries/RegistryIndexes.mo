import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import Result "mo:core/Result";
import Array "mo:core/Array";

import Errors "../../shared/Errors";
import MixinJobTopUpCycles "../mixins/MixinJobTopUpCycles";

shared ({ caller = owner }) persistent actor class RegistryIndexes() = this {
    let thisPrincipal = Principal.fromActor(this);

    include MixinJobTopUpCycles<system>({
        adminPrincipal = owner;
        canisterPrincipal = thisPrincipal;
        kind = #registry(#registryIndexes);
    });

    // ===== MEMORY =====

    var adminPrincipal = owner;
    let memIndexes = Map.empty<Principal, ()>();

    // ===== ADMIN =====

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #getIndexes : () -> ();
            #addIndex : () -> (indexes : [Principal]);
            #setAdmin : () -> (principal : Principal);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( Principal.isAnonymous(params.caller) ) return false;

        if ( Blob.size(params.arg) > 5000 ) return false;

        switch (params.msg) {
            case (#getIndexes(_)) true;
            case (#addIndex(_)) adminPrincipal == params.caller;
            case (#setAdmin(_)) params.caller.isController();
        }
    };

    public shared ({ caller }) func setAdmin(principal: Principal) : async Result.Result<(), Errors.HandlerErr> {
        if ( not caller.isController() ) return #err(#errMustBeController);

        adminPrincipal := principal;

        #ok
    };

    public shared ({ caller }) func addIndex(indexes: [Principal]) : async Result.Result<Bool, Errors.HandlerErr> {
        if ( not caller.isController() ) return #err(#errMustBeController);

        indexes.forEach(func(principal) = memIndexes.add(principal, ()) );

        #ok(true)
    };

    // ===== HANDLERS =====

    public query ({ caller }) func getIndexes() : async Result.Result<[Principal], Errors.HandlerErr> {
        if ( Principal.isAnonymous(caller) ) return #err(#errMustNotBeAnonymous);

        #ok(memIndexes.keys().toArray())
    };
}