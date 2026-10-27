import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import { hashText } "../Hash";
import Principal "mo:core/Principal";
import { CanisterKind; Mapping; StaticKind } "../Canisters";
import { type Result } "mo:core/Result";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Time "mo:core/Time";
import Debug "mo:core/Debug";
import { type HandlerErr } "../Errors";
import { type ActorSearchIndex; type ActorFactory; } "../Interfaces";

mixin ({ self: Principal; selfKind: CanisterKind.CanisterKind; mapping: Mapping.Mapping }) {
  // ===== CONFIGS =====

  let STALE_MAPPING_THRESHOLD : Time.Time = 60_000_000_000; // 60 seconds

  // ===== MEMORY =====

  var lastVersionMaj : Time.Time = Time.now();
  var currentVersion = 0;
  let memKnownCanisters = Map.empty<Principal, ()>();
  let memMapping = Map.empty<CanisterKind.CanisterKind, Map.Map<Nat, Principal>>();

  // === Save and format Canisters memory ===

  func addStaticCanisters(canisters: [(StaticKind.StaticKind, Principal)]) : () {
    for ((kind, principal) in canisters.values()) {
      let map = switch ( memMapping.get(#static(kind)) ) {
        case null {
          let map = Map.empty<Nat, Principal>();
          memMapping.add(#static(kind), map);
          map
        };
        case (?map) map;
      };

      map.add(0, principal);
      memKnownCanisters.add(principal, ());
    };
  };

  func saveMapping(mapping: Mapping.Mapping) : () {
    for ( (kind, principals) in mapping.canisters.values() ) {
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

    lastVersionMaj := Time.now();
    currentVersion := mapping.version;
  };

  func getAndSaveMapping() : async () {
    let ?factories = memMapping.get(#static(#factory)) else return ();
    let ?factory = factories.get(0) else return ();

    let actorFactory = actor(factory.toText()) : ActorFactory;

    try {
      switch ( await actorFactory.handlerGetFullMapping() ) {
        case (#ok(newMapping)) {
          if (newMapping.version <= currentVersion) return ();

          saveMapping(newMapping);
          return ();
        };
        case (#err(_)) return ();
      };
    } catch e {
      Debug.print("Error fetching full mapping: " # e.message());
      return ();
    };
  };

  func knownCanistersToMapping() : Mapping.Mapping {
    let result = List.empty<(CanisterKind.CanisterKind, [(Nat, Principal)])>();

    for ( (kind, map) in memMapping.entries() ) {
      result.add((kind, (map.entries().toArray())));
    };

    { version = currentVersion; canisters = result.toArray() }
  };

    // === Permissions ===

  func isKnownBasic(caller: Principal) : Bool {
    memKnownCanisters.containsKey(caller) or caller.isController();
  };

  func isKnown(caller: Principal) : async Bool {
    if ( isKnownBasic(caller) ) return true;
    
    if ( lastVersionMaj < Time.now() - STALE_MAPPING_THRESHOLD ) return false;

    await getAndSaveMapping();

    true;
  };

  func isInRange(key: Text) : Bool {
    let keyHash = hashText(key);

    let ?map = memMapping.get(selfKind) else return false;
    let ?entry = map.get(keyHash) else return false;
    
    entry == self
  };

  // === Find canister ===

  func findCanisterFromText(kind: CanisterKind.CanisterKind, text: Text) : ?Principal {
    let ?map = memMapping.get(kind) else return null;

    let index = hashText(text) % map.size();

    switch ( map.reverseEntriesFrom(index).next() ) {
      case (?entry) ?entry.1;
      case null null;
    }
  };

  func findCanisterFromIndex(kind: CanisterKind.CanisterKind, index: Nat) : ?Principal {
    let ?map = memMapping.get(kind) else return null;

    let idx = index % map.size();

    switch ( map.reverseEntriesFrom(idx).next() ) {
      case (?entry) ?entry.1;
      case null null;
    }
  };

  func createActorSearchIndexFor(text: Text) : ?ActorSearchIndex {
    let ?principal = findCanisterFromText(#dynamic(#search(#searchIndex)), text) else return null;
    ?(actor(principal.toText()) : ActorSearchIndex)
  };

  func getAdmin() : ?Principal {
    let ?admin = memMapping.get(#static(#admin)) else return null;
    let ?adminPrincipal = admin.get(0) else return null;

    ?adminPrincipal
  };

  // ===== INIT =====

  if (memKnownCanisters.size() == 0) saveMapping(mapping);
}