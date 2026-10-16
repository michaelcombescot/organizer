import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { Interfaces = { type AdminActor }; Kind = {type CanisterKind; compareCanisterKind} } "../Canisters";
import { type Result } "mo:core/Result";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Debug "mo:core/Debug";
import Nat "mo:core/Nat";
import Time "mo:core/Time";
import Error "mo:core/Error";
import { type HandlerErr } "../Errors";

// Mixin for managing known canisters by their kinds and principals.
// All canisters needs mainly to know if another canister is allowed to call them
mixin (owner: Principal, canisters: [(CanisterKind, [Principal])]) {
  // ===== STRUCTURES =====

  type InspectParamsMsgKnownCanistersMapping = {
    #handlerUpdateMapping : () -> ({version: Nat; canisters : [(CanisterKind, Principal)]});
    #handlerRemoveKnownCanisters : () -> (canisters : [(CanisterKind, Principal)]);
  };

  // ===== MEMORY =====

  var memMappingVersion = {var version = 0; var lastUpdate = Time.now(); var ongoing = false};
  let memKnownCanisters = Map.empty<Principal, ()>();
  let memMapping = Map.empty<CanisterKind, Map.Map<Principal, ()>>();

  // ===== PERMISSIONS =====

  func isKnown(caller: Principal) : Bool {
    caller.isController() or memKnownCanisters.containsKey(caller)
  };
  
  // ===== HELPERS =====

  func checkMappingVersion(version: Nat) : async () {
    if ( version <= memMappingVersion.version ) return;

    // Little security in case of a failed call to prevent indefinite blocking
    if ( memMappingVersion.ongoing and memMappingVersion.lastUpdate + 30_000_000_000 <= Time.now() ) return;

    Debug.print("Mapping version mismatch, expected " # memMappingVersion.version.toText() # ", got " # version.toText());
    memMappingVersion.ongoing := true;

    ignore async {
      try {
        let actorAdmin : AdminActor = actor (owner.toText());
        switch ( await actorAdmin.handlerGetFullMapping() ) {
          case #ok(mapping) memMappingVersion.lastUpdate := Time.now();
          case #err(e) Debug.print("Mapping version update failed: " # debug_show(e));
        };
      } catch (e) {
        Debug.print("Mapping version update encountered an exception: " # e.message());
        memMappingVersion.lastUpdate := Time.now();
      };

      memMappingVersion.ongoing := false;
    };
  };

  func saveCanisters(canisters: [(CanisterKind, [Principal])]) : () {
    for ( (kind, principals) in canisters.values() ) {
      switch ( memMapping.get(compareCanisterKind, kind) ) {
        case null memMapping.add(compareCanisterKind, kind, Map.empty<Principal, ()>());
        case (?map) {};
      };

      let ?map = memMapping.get(compareCanisterKind, kind) else continue;
      for (principal in principals.values()) {
        map.add(principal, ());
        memKnownCanisters.add(principal, ());
      };
    };
  };

  func knownCanistersTuples() : [(CanisterKind, [Principal])] {
    let result = List.empty<(CanisterKind, [Principal])>();
    for ( (kind, map) in memMapping.entries() ) {
      result.add((kind, map.keys().toArray()));
    };
    result.toArray()
  };

  // ===== INIT =====

  saveCanisters(canisters);

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerUpdateMapping(({version: Nat; canisters : [(CanisterKind, [Principal])]})) : async Result<(), HandlerErr> {
    if ( not caller.isController() ) return #err(#errForbidden);

    saveCanisters(canisters);
    memMappingVersion.version := version;

    #ok
  };

  public shared ({ caller }) func handlerRemoveKnownCanisters(canisters: [(CanisterKind, Principal)]) : async Result<(), HandlerErr> {
    if ( not caller.isController() ) return #err(#errForbidden);

    for ( (kind, principal) in canisters.values() ) {
      switch ( memMapping.get(compareCanisterKind, kind) ) {
        case null {};
        case (?map) map.remove(principal);
      };

      memKnownCanisters.remove(principal);
    };

    #ok
  };
}