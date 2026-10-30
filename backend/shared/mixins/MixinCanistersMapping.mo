import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import { hashText } "../Hash";
import Principal "mo:core/Principal";
import Canisters "../Canisters";
import { type Result } "mo:core/Result";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Time "mo:core/Time";
import Debug "mo:core/Debug";
import Result "mo:core/Result";
import { type HandlerErr } "../Errors";
import { type ActorSearchIndexes; type ActorFactory; } "../Interfaces";

mixin ({ self: Principal; selfKind: Canisters.CanisterKind; mapping: ?Canisters.Mapping }) {
  // ===== CONFIGS =====

  let STALE_MAPPING_THRESHOLD : Time.Time = 60_000_000_000; // 60 seconds
  let MAX_MAPPING_INDEXES : Nat = 1_000_000_000; // Maximum number of indexes per canister kind

  // ===== TYPES =====

  type InspectMapping = {
    #handlerGetFullMapping : () -> ();
    #handlerUpdateMapping : () -> ();
    #handlerAddStaticCanisters : () -> (canisters: [(Canisters.StaticKind, Principal)]);
  };

  // ===== MEMORY =====

  var lastVersionMaj : Time.Time = Time.now();
  var currentVersion = 0;
  let memKnownCanisters = Map.empty<Principal, ()>();
  let memMapping = Map.empty<Canisters.CanisterKind, Map.Map<Nat, Principal>>();

  // === Save and format Canisters memory ===

  func addStaticCanisters(canisters: [(Canisters.StaticKind, Principal)]) : () {
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

  func saveMapping(mapping: Canisters.Mapping) : () {
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
        case (#ok(null)) return ();
        case (#ok(?newMapping)) {
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

  func knownCanistersToMapping() : ?Canisters.Mapping {
    let result = List.empty<(Canisters.CanisterKind, [(Nat, Principal)])>();

    for ( (kind, map) in memMapping.entries() ) {
      result.add((kind, (map.entries().toArray())));
    };

    if (result.size() == 0) return null;
    ?{ version = currentVersion; canisters = result.toArray() }
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

  func findCanisterFromText(kind: Canisters.CanisterKind, text: Text) : ?Principal {
    let ?map = memMapping.get(kind) else return null;

    let index = hashText(text) % MAX_MAPPING_INDEXES;

    switch ( map.reverseEntriesFrom(index).next() ) {
      case (?entry) ?entry.1;
      case null null;
    }
  };

  func findCanisterFromIndex(kind: Canisters.CanisterKind, index: Nat) : ?Principal {
    let ?map = memMapping.get(kind) else return null;

    let idx = index % MAX_MAPPING_INDEXES;

    switch ( map.reverseEntriesFrom(idx).next() ) {
      case (?entry) ?entry.1;
      case null null;
    }
  };

  func createActorSearchIndexesFor(text: Text) : ?ActorSearchIndexes {
    let ?principal = findCanisterFromText(#dynamic(#orderedByHash(#searchIndexes)), text) else return null;
    ?(actor(principal.toText()) : ActorSearchIndexes)
  };

  func getAdmin() : ?Principal {
    let ?admin = memMapping.get(#static(#admin)) else return null;
    let ?adminPrincipal = admin.get(0) else return null;

    ?adminPrincipal
  };

  // ===== INIT =====

  switch (mapping) {
    case (?m) saveMapping(m);
    case null ();
  };

  // ===== API =====

  public query ({ caller }) func handlerGetFullMapping() : async Result.Result<?Canisters.Mapping, HandlerErr> {
    if ( not (isKnownBasic(caller)) ) return #err(#errForbidden);

    #ok(knownCanistersToMapping())
  };

  public shared ({caller}) func handlerUpdateMapping() : async Result.Result<(), HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errForbidden);

    Debug.print("Handler update mapping called by: " # caller.toText());

    await getAndSaveMapping();

    #ok
  };

  public shared ({ caller }) func handlerAddStaticCanisters(canisters: [(Canisters.StaticKind, Principal)]) : async Result.Result<(), HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errForbidden);

    addStaticCanisters(canisters);
    #ok
  };
}