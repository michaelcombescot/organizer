import IC "mo:ic";
import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import Timer "mo:base/Timer";
import Canisters "../../shared/Canisters";

// used to handle authorization of canisters
mixin <system> ({ coordinatorPrincipal: Principal; canisterPrincipal: Principal; toppingThreshold: Nat; toppingIntervalNs: Nat; kind: Canisters.CanisterKind }) {
    transient let coordinatorActor = actor(Principal.toText(coordinatorPrincipal)) : Canisters.ICoordinator;

    func topCanisterRequest() : async () {
        let status = await IC.ic.canister_status({ canister_id = canisterPrincipal });
        if (status.cycles <= toppingThreshold) {

            switch (await coordinatorActor.handlerTopCanister(canisterPrincipal, kind)) {
                case (#ok) ();
                case (#err(err)) Debug.print("cannot top canister" # canisterPrincipal.toText() # ", error: " # err)
            }
        };
    };

    ignore Timer.recurringTimer<system>(#seconds(3600), topCanisterRequest);
};