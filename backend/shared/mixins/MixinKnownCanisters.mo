import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import { Kind = { type CanisterKind } } "../Canisters";
import { type HandlerErr } "../Errors";

// Mixin for managing known canisters by their principals.
// All canisters needs mainly to know if another canister is allowed to call them
mixin (canister: [(Principal, CanisterKind)]) {
  // ===== MEMORY =====

  var memKnownCanisters = Map.fromArray<Principal, CanisterKind>(canister);

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerSetKnownCanistersByPrincipal(canisters: [(principal: Principal, kind: CanisterKind)]) : async Result<(), HandlerErr> {
    if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

    memKnownCanisters := Map.fromArray<Principal, CanisterKind>(canisters);

    #ok
  };

  // ===== HELPERS =====

  func isControllerOrKnownCanister(principal: Principal) : Bool {
    if (principal.isController()) return true;

    memKnownCanisters.containsKey(principal)
  };
}