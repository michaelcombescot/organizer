import Map "mo:core/Map";
import Nat "mo:core/Nat";
import { hashText } "../Hash";
import Principal "mo:core/Principal";
import { CanisterKind } "../Canisters";
import { type Result } "mo:core/Result";
import Iter "mo:core/Iter";
import List "mo:core/List";
import { type HandlerErr } "../Errors";
import { type IQueriesIndexTextActor } "../Interfaces";

mixin ({ self: Principal; selfKind: CanisterKind.CanisterKind; canisters: [(CanisterKind.CanisterKind, [(Nat, Principal)])]}) {
  // ===== INSPECT =====

  type InspectMappingMsg = {
    #handlerUpdateMapping : () -> ({ version: Nat; canisters: [(CanisterKind.CanisterKind, [(Nat, Principal)])] });
  };

  // ===== MEMORY =====

  var currentVersion = 0;
  let memKnownCanisters = Map.empty<Principal, ()>();
  let memMapping = Map.empty<CanisterKind.CanisterKind, Map.Map<Nat, Principal>>();

  // === Permissions ===

  func isKnown(caller: Principal) : Bool {
    memKnownCanisters.containsKey(caller)
  };

  func isInRange(key: Text) : Bool {
    let keyHash = hashText(key);

    let ?map = memMapping.get(selfKind) else return false;
    let ?entry = map.get(keyHash) else return false;
    
    entry == self
  };

  // === Save and format Canisters memory ===

  func saveCanisters(canisters: [(CanisterKind.CanisterKind, [(Nat, Principal)])]) : () {
    for ( (kind, principals) in canisters.values() ) {
      let map = switch ( memMapping.get(kind) ) {
        case null {
          let map = Map.empty<Nat, Principal>();
          memMapping.add(kind, map);
          map
        };
        case (?map) map;
      };

      for ( (index, principal) in principals.values() ) {
        map.add(index, principal);
        memKnownCanisters.add(principal, ());
      };
    };
  };

  func knownCanistersToTuples() : [(CanisterKind.CanisterKind, [(Nat, Principal)])] {
    let result = List.empty<(CanisterKind.CanisterKind, [(Nat, Principal)])>();

    for ( (kind, map) in memMapping.entries() ) {
      result.add((kind, (map.entries().toArray())));
    };

    result.toArray()
  };

  // === Find canister ===

  func findCanister(kind: CanisterKind.CanisterKind, text: Text) : ?Principal {
    let ?map = memMapping.get(kind) else return null;

    let index = hashText(text) % map.size();

    switch ( map.reverseEntriesFrom(index).next() ) {
      case (?entry) ?entry.1;
      case null null;
    }
  };

  // ===== INIT =====

  if (memKnownCanisters.size() == 0) saveCanisters(canisters);

  // ===== HANDLER =====

  public shared ({ caller }) func handlerUpdateMapping({
    version: Nat;
    canisters: [(CanisterKind.CanisterKind, [(Nat, Principal)])]
  }) : async Result<(), HandlerErr> {
    if ( not caller.isController() ) return #err(#errForbidden);

    if (version <= currentVersion) return #ok;

    memKnownCanisters.clear();
    memMapping.clear();

    currentVersion := version;
    saveCanisters(canisters);
    #ok
  };
}