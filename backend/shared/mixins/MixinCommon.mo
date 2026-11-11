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

mixin ({ thisPrincipal: Principal; thisKind: Canisters.CanisterKind; }) {
  //////
  // ===== CONFIGS =====
  //////

  let STALE_MAPPING_THRESHOLD : Time.Time = 60_000_000_000; // 60 seconds
  let MAX_MAPPING_INDEXES : Nat = 1_000_000_000_000; // Maximum number of indexes per canister kind

  //////
  // ===== TYPES =====
  //////

  type InspectCommon = {
    #handlerGetFullMapping : () -> ();
    #handlerUpdateMapping : () -> (mapping: Canisters.Mapping);
    #handlerAddStaticCanisters : () -> (canisters: [(Canisters.StaticKind, Principal)]);
  };

  //////
  // ===== MEMORY =====
  //////

  // Update and lock
  var updateOngoing = false;

  // Mapping
  var updateMappingOngoing = true;
  var memVersion: Canisters.Version = {
    var currentVersion = 0;
    var lastVersionMaj = Time.now();
  };
  let memKnownCanisters = Map.empty<Principal, Nat>();
  let memMapping = Map.empty<Canisters.CanisterKind, Map.Map<Nat, Principal>>();

  //////
  // ===== Mapping helpers (save, get, update) =====
  //////

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
        memKnownCanisters.add(principal, index);
      };
    };

    memVersion.lastVersionMaj := Time.now();
    memVersion.currentVersion := mapping.version;
  };

  func getAndSaveMapping() : async Result<(), HandlerErr> {
    // prevent the fetch to be called several times concurrently
    if ( updateMappingOngoing ) return #ok;
    // prevent a malicious canister to spam the network with repeated fetch requests when the mapping is stale
    if ( memVersion.lastVersionMaj < Time.now() - STALE_MAPPING_THRESHOLD ) return #ok;

    updateMappingOngoing := true;

    let ?factory = findFactory() else {
      updateMappingOngoing := false;
      return #err(#errNotFound("Factory not found in mapping"));
    };

    let actorFactory = actor(factory.toText()) : ActorFactory;

    try {
      switch ( await actorFactory.handlerGetFullMapping() ) {
        case (#ok(newMapping)) {
          if (newMapping.version > memVersion.currentVersion) {
            saveMapping(newMapping);
          };
        };
        case (#err(_)) ();
      };
    } catch e {
      Debug.print("Error fetching full mapping: " # e.message());
    };
    
    updateMappingOngoing := false;
    #ok;
  };

  func knownCanistersToMapping() : Canisters.Mapping {
    let result = List.empty<(Canisters.CanisterKind, [(Nat, Principal)])>();

    for ( (kind, map) in memMapping.entries() ) {
      result.add((kind, (map.entries().toArray())));
    };

    { version = memVersion.currentVersion; canisters = result.toArray() }
  };

  //////
  // ===== Permissions =====
  //////

  func isOpenToRequests() : Result<(), HandlerErr> {
    if ( updateOngoing or updateMappingOngoing ) return #err(#errUpdateOngoing);
    #ok
  };

  func isKnownBasic(caller: Principal) : Result<(), HandlerErr> {
    if ( not(memKnownCanisters.containsKey(caller) or caller.isController() ) ) return #err(#errForbidden);
    #ok
  };

  func canAccessBasic(caller: Principal) : Result<(), HandlerErr> {
    switch ( isOpenToRequests() ) {
      case (#ok) ();
      case (#err(e)) return #err(e);
    };

    if ( updateOngoing or updateMappingOngoing ) return #err(#errUpdateOngoing);
    switch ( isKnownBasic(caller) ) {
      case (#ok) #ok;
      case (#err(e)) return #err(e);
    };
  };

  func canAccess(caller: Principal) : async Result<(), HandlerErr> {
    switch ( canAccessBasic(caller) ) {
      case (#ok) return #ok;
      case (#err(_)) ();
    };

    await getAndSaveMapping()
  };

  func isInRange(key: Text) : Bool {
    let keyHash = hashText(key);

    let ?map = memMapping.get(thisKind) else return false;
    let ?entry = map.get(keyHash) else return false;
    
    entry == thisPrincipal
  };

  //////
  // ===== Find canister helpers =====
  //////

  func findFactory() : ?Principal {
    let ?factories = memMapping.get(#static(#factory)) else return null;
    factories.get(0)
  };

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

  ////// 
  // ===== API =====
  //////

  // Handler to fetch the full mapping of canisters, restricted to known basic callers.
  // Mainly used for controllers to know if the mapping is up to date
  public query ({ caller }) func handlerGetFullMapping() : async Result.Result<Canisters.Mapping, HandlerErr> {
    switch ( canAccessBasic(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    #ok(knownCanistersToMapping())
  };

  // Handler called by the factory when a new dynamic canister is created.
  // It updates the internal mapping with the latest information provided by the factory.
  public shared ({ caller }) func handlerUpdateMapping(mapping: Canisters.Mapping) : async Result.Result<(), HandlerErr> {
    switch ( canAccessBasic(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    updateMappingOngoing := true;

    saveMapping(mapping);

    updateMappingOngoing := false;

    #ok
  };

  // Handler called by a controller to make static canisters know to the factory,
  // and the factory known to the statics canisters.
  public shared ({ caller }) func handlerAddStaticCanisters(canisters: [(Canisters.StaticKind, Principal)]) : async Result.Result<(), HandlerErr> {
    switch ( canAccessBasic(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

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
      memKnownCanisters.add(principal, 0);
    };

    #ok
  };
}