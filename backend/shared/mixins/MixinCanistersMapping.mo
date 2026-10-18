import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import { Interfaces = { type AdminActor }; Kind = {type CanisterKind; compareCanisterKind} } "../Canisters";
import { type Result } "mo:core/Result";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Debug "mo:core/Debug";
import Error "mo:core/Error";
import { type HandlerErr } "../Errors";

mixin (self: Principal, owner: Principal, canisters: [(CanisterKind, [(Nat, Principal)])]) {
  // ===== MEMORY =====

  var minScope = 0;
  var maxScope = 1_000_000_000;
  let memKnownCanisters = Map.empty<Principal, ()>();
  let memMapping = Map.empty<CanisterKind, Map.Map<Nat, Principal>>();

  // ===== PERMISSIONS =====

  func isKnown(caller: Principal) : Bool {
    caller.isController() or memKnownCanisters.containsKey(caller)
  };
  
  // ===== HELPERS =====

  func saveCanisters(canisters: [(CanisterKind, [(Nat, Principal)])]) : () {
    for ( (kind, principals) in canisters.values() ) {
      switch ( memMapping.get(compareCanisterKind, kind) ) {
        case null memMapping.add(compareCanisterKind, kind, Map.empty<Nat, Principal>());
        case (?map) {};
      };

      let ?map = memMapping.get(compareCanisterKind, kind) else continue;
      var nextIndex = 0;
      for (i in principals.keys()) {
        let (index, principal) = principals[i];
        if (principal == self) {
          minScope := index;
          if (i + 1 < principals.size()) {
            maxScope := principals[i + 1].0 - 1;
          }
        };

        map.add(index, principal);
        memKnownCanisters.add(principal, ());
      };
    };
  };

  func knownCanistersToTuples() : [(CanisterKind, [(Nat, Principal)])] {
    let result = List.empty<(CanisterKind, [(Nat, Principal)])>();
    for ( (kind, map) in memMapping.entries() ) {
      result.add((kind, (map.entries().toArray())));
    };
    result.toArray()
  };

  func getNewMapping() : async () {
    let actorAdmin : AdminActor = actor (owner.toText());

    try {
      saveCanisters(await actorAdmin.handlerGetFullMapping());
    } catch (e) {
      Debug.print("Mapping update encountered an exception: " # e.message());
    };
  };

  // ===== INIT =====

  saveCanisters(canisters);
}