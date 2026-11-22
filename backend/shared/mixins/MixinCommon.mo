import Map "mo:core/Map";
import Nat "mo:core/Nat";
import { hashText } "../Hash";
import Principal "mo:core/Principal";
import Canisters "../Canisters";
import { type Result } "mo:core/Result";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Time "mo:core/Time";
import Result "mo:core/Result";
import Blob "mo:core/Blob";
import { type ErrHandler } "../Errors";
import { type ActorSearchIndexes; type ActorFactory; } "../Interfaces";

mixin ({ thisPrincipal: Principal; thisKind: Canisters.CanisterKind; }) {
  //////
  // ===== CONFIGS =====
  //////

  let STALE_MAPPING_THRESHOLD : Time.Time = 60_000_000_000; // 60 seconds
  let MAX_MAPPING_INDEXES : Nat = 1_000_000_000_000; // Maximum number of indexes per canister kind

  //////
  // ===== MEMORY =====
  //////

  // Update and lock
  var updateOngoing = false;

  // Mapping
  var updateMappingOngoing = false;
  var memCurrentVersion = 0;

  let memKnownCanisters = Map.empty<Principal, Nat>();
  let memMapping = Map.empty<Canisters.CanisterKind, Map.Map<Nat, Principal>>();

  //////
  // ===== Mapping helpers (save, get, update) =====
  //////

  func mappingToPublic() : Canisters.Mapping {
    let result = List.empty<(Canisters.CanisterKind, [(Nat, Principal)])>();

    for ( (kind, map) in memMapping.entries() ) {
      result.add((kind, (map.entries().toArray())));
    };

    { version = memCurrentVersion; canisters = result.toArray() }
  };

  /////
  // ===== INSPECT VERIFICATIONS  =====
  /////

  func inspectBasic({caller: Principal; arg: Blob.Blob; maxArgSize: Nat}) : Bool {
    if ( caller.isAnonymous() ) return false;
    if (arg.size() > maxArgSize) return false;
    true
  };

  //////
  // ===== Permissions =====
  //////

  func isOpenToRequests() : Result<(), ErrHandler> {
    if ( updateOngoing or updateMappingOngoing ) return #err(#errUpdateOngoing);
    #ok
  };

  func isKnown(caller: Principal) : Result<(), ErrHandler> {
    if ( not(memKnownCanisters.containsKey(caller) or caller.isController() ) ) return #err(#errForbidden);
    #ok
  };

  func callerIsIdentified(caller: Principal) : Result<(), ErrHandler> {
    switch (isOpenToRequests()) { case(#ok) (); case(#err(e)) return #err(e); };
    if ( caller.isAnonymous() ) return #err(#errMustNotBeAnonymous);
    #ok
  };

  func canAccess(caller: Principal) : Result<(), ErrHandler> {
    if ( caller.isAnonymous() ) return #err(#errMustNotBeAnonymous);

    switch ( isOpenToRequests() ) {
      case (#ok) ();
      case (#err(e)) return #err(e);
    };

    if ( updateOngoing or updateMappingOngoing ) return #err(#errUpdateOngoing);

    switch ( isKnown(caller) ) {
      case (#ok) #ok;
      case (#err(e)) return #err(e);
    };
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

  // ACTORS CREATION

  func createActorFactory() : Result<ActorFactory, ErrHandler> {
    let principal = switch ( memMapping.get(#static(#factory)) ) {
      case (?factories) {
        switch (factories.get(0)) { case (?p) p; case null return #err(#errNotFound("No factories found in mapping")); };
      };
      case null return #err(#errNotFound("No factories found in mapping"));
    };

    #ok(actor(principal.toText()) : ActorFactory)
  };

  func createActorSearchIndexesFor(text: Text) : Result<ActorSearchIndexes, ErrHandler> {
    let ?principal = findCanisterFromText(#dynamic(#orderedByHash(#searchIndexes)), text) else return #err(#errNotFound("No search index found for the given text"));
    #ok(actor(principal.toText()) : ActorSearchIndexes)
  };

  // HELPERS TO FIND A CANISTER IN THE MAPPING

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

  ////// 
  // ===== API =====
  //////

  // Handler to fetch the full mapping of canisters, restricted to known basic callers.
  // Mainly used for controllers to know if the mapping is up to date
  public query ({ caller }) func handlerGetFullMapping() : async Result.Result<Canisters.Mapping, ErrHandler> {
    switch ( canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    #ok(mappingToPublic())
  };

  // Handler called by the factory when a new dynamic canister is created.
  // It updates the internal mapping with the latest information provided by the factory.
  public shared ({ caller }) func handlerUpdateMapping(mapping: Canisters.Mapping) : async Result.Result<(), ErrHandler> {
    switch ( canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    if (mapping.canisters.size() == 0) return #err(#errNotFound("No canisters found in mapping"));
    if (mapping.version < memCurrentVersion) return #ok;

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

    memCurrentVersion := mapping.version;

    #ok
  };
}