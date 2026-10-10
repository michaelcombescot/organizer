import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { Kind = {type CanisterKind; compareCanisterKind} } "../Canisters";
import { type Result } "mo:core/Result";
import List "mo:core/List";
import Iter "mo:core/Iter";
import { type HandlerErr } "../Errors";

// Mixin for managing known canisters by their kinds and principals.
// All canisters needs mainly to know if another canister is allowed to call them
mixin (canisters: [(CanisterKind, Principal)]) {
  // ===== STRUCTURES =====

  type InspectParamsMsgKnownCanistersByKind = {
    #handlerAddKnownCanistersByKind : () -> (canisters : [(CanisterKind, Principal)]);
    #handlerRemoveKnownCanistersByKind : () -> (canisters : [(CanisterKind, Principal)]);
  };

  // ===== MEMORY =====

  let memKnownCanistersByKind = Map.empty<CanisterKind, Map.Map<Principal, ()>>();

  // ===== PERMISSIONS =====

  func isIndex(caller: Principal) : Bool {
    let ?indexes = memKnownCanistersByKind.get(compareCanisterKind, #index) else return false;
    caller.isController() or indexes.containsKey(caller)
  };
  
  // ===== HELPERS =====

  func saveCanisters(canisters: [(CanisterKind, Principal)]) : () {
    for ( (kind, principal) in canisters.values() ) {
      switch ( memKnownCanistersByKind.get(compareCanisterKind, kind) ) {
        case null memKnownCanistersByKind.add(compareCanisterKind, kind, Map.singleton<Principal, ()>(principal, ()));
        case (?map) map.add(principal, ());
      };
    };
  };

  func knownCanistersTuples() : [(CanisterKind, Principal)] {
    var result = List.empty<(CanisterKind, Principal)>();

    for ( (kind, map) in memKnownCanistersByKind.entries() ) {
      map.keys().forEach(func (principal) { result.add((kind, principal)) });
    };

    result.toArray()
  };

  func knownIndexes() : [Principal] {
    let ?map = memKnownCanistersByKind.get(compareCanisterKind, #index) else return [];
    map.keys().toArray()
  };

  // ===== INIT =====

  saveCanisters(canisters);

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerAddKnownCanistersByKind(canisters: [(CanisterKind, Principal)]) : async Result<(), HandlerErr> {
    if ( not caller.isController() ) return #err(#errForbidden);

    saveCanisters(canisters);

    #ok
  };

  public shared ({ caller }) func handlerRemoveKnownCanistersByKind(canisters: [(CanisterKind, Principal)]) : async Result<(), HandlerErr> {
    if ( not caller.isController() ) return #err(#errForbidden);

    for ( (kind, principal) in canisters.values() ) {
      switch ( memKnownCanistersByKind.get(compareCanisterKind, kind) ) {
        case null {};
        case (?map) map.remove(principal);
      };
    };

    #ok
  };
}