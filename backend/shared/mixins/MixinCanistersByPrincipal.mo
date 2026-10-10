import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import { type HandlerErr } "../Errors";

// Mixin for managing known canisters by their principals.
// All canisters needs mainly to know if another canister is allowed to call them
mixin (canisters: [Principal]) {
  // ===== STRUCTURES =====

  type InspectParamsMsgKnownCanistersByPrincipal = {
    #handlerAddKnownCanistersByPrincipal : () -> (canisters : [Principal]);
    #handlerRemoveKnownCanistersByPrincipal : () -> (canisters : [Principal]);
  };

  // ===== MEMORY =====

  let memKnownCanistersByPrincipal = Map.empty<Principal, ()>();

  // ===== HELPERS =====

  func isControllerOrKnownCanister(principal: Principal) : Bool {
    if ( memKnownCanistersByPrincipal.containsKey(principal) ) return true;
    if (principal.isController()) return true;
    false
  };

  func saveCanisters(canisters: [Principal]) : () {
    for ( principal in canisters.values() ) {
      memKnownCanistersByPrincipal.add(principal, ());
    };
  };

  // ===== INIT =====

  saveCanisters(canisters);

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerAddKnownCanistersByPrincipal(canisters: [Principal]) : async Result<(), HandlerErr> {
    if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

    saveCanisters(canisters);

    #ok
  };

  public shared ({ caller }) func handlerRemoveKnownCanistersByPrincipal(canisters: [Principal]) : async Result<(), HandlerErr> {
    if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

    for ( principal in canisters.values() ) {
      memKnownCanistersByPrincipal.remove(principal);
    };

    #ok
  };
}