import IC "mo:ic";
import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import Timer "mo:base/Timer";
import Canisters "../../shared/Canisters";
import Configs "../../Configs";

// used to handle authorization of canisters
mixin <system> ({ adminPrincipal: Principal; canisterPrincipal: Principal; kind: Canisters.CanisterKind }) {
    transient let coordinatorActor = actor(Principal.toText(adminPrincipal)) : Canisters.ICoordinator;

    func topCanisterRequest() : async () {
        let status = await IC.ic.canister_status({ canister_id = canisterPrincipal });
        
        let toppingThreshold = switch (kind) {
            case (#index) Configs.toppingThresholdIndex;
            case (#registry(registriesKind)) {
                switch (registriesKind) {
                    case (#registryIndexes) Configs.toppingThresholdRegistry;
                };
            };
            case (#bucket(bucketsKind)) {
                switch (bucketsKind) {
                    case (#bucketUsers) Configs.toppingThresholdBuckets;
                };
            }
        };

        if (status.cycles <= toppingThreshold) {

            switch (await coordinatorActor.handlerTopCanister(canisterPrincipal, kind)) {
                case (#ok) ();
                case (#err(err)) Debug.print("cannot top canister" # canisterPrincipal.toText() # ", error: " # err)
            }
        };
    };

    ignore Timer.recurringTimer<system>(#seconds(86400), topCanisterRequest);
};