import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import { Kind = { type CanisterKind } } "../Canisters";
import { type HandlerErr } "../Errors";

// Mixin for managing known canisters by their principals.
// All canisters needs mainly to know if another canister is allowed to call them
mixin (canisters: [(CanisterKind, Principal)]) {
  // ===== STRUCTURES =====

  type InspectParamsMsg = {
    #handlerSetKnownCanistersByPrincipal : () -> (canisters : [(kind: CanisterKind, principal: Principal)]);
  };

  // ===== MEMORY =====

  var memWorkers = Map.empty<Principal, ()>();
  var memIndexes = Map.empty<Principal, ()>();

  // ===== HELPERS =====

  func isControllerOrKnownCanister(principal: Principal) : Bool {
    if (principal.isController()) return true;

    if (memWorkers.containsKey(principal)) return true;
    if (memIndexes.containsKey(principal)) return true;

    return false;
  };

  func saveCanisters(canisters: [(kind: CanisterKind, principal: Principal)]) : () {
    for ( (kind, principal) in canisters.values() ) {
      switch (kind) {
        case (#worker(#workerApp)) memWorkers.add(principal, ());
        case (#index) memIndexes.add(principal, ());
        case (_) ();
      };
    };
  };

  // ===== INIT =====

  saveCanisters(canisters);

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerSetKnownCanistersByPrincipal(canisters: [(kind: CanisterKind, principal: Principal)]) : async Result<(), HandlerErr> {
    if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

    saveCanisters(canisters);

    #ok
  };  
}