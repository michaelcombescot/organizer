import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Error "mo:core/Error";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Result "mo:core/Result";
import Iter "mo:core/Iter";
import Canisters "../../shared/Canisters";
import MixinCommon "../../shared/mixins/MixinCommon";
import MixinJobs "../../shared/mixins/MixinJobs";
import MixinFactoryJobs "MixinFactoryJobs";
import MixinTopUpCycles "MixinTopUpCycles";
import Errors "../../shared/Errors";
import BucketUsers "../buckets/bucketUsers/BucketUsers";
import SearchIndexes "../searches/SearchIndexes";
import IndexMain "../indexes/IndexMain";

// This actor has 3 purpose:
// - Keep track of known canisters and their mappings.
// - Manage the creation and registration of new canisters.
// - Topping up the cycles of existing canisters when needed
shared ({ caller = owner }) actor class Factory() = this {
  let thisPrincipal = Principal.fromActor(this);

  // ===== CONFIGS =====

  func confGetNewCanisterNbCycles (kind: Canisters.DynamicKind) : Nat {
    switch (kind) {
      case (#orderedByHash(h)) {
        switch (h) {
          case (#bucketUsers) return 1_000_000_000_000;
          case (#searchIndexes) return 1_000_000_000_000;
        }
      };
      case (#orderedByTime(i)) {
        switch (i) {
          case (#indexMain) return 1_000_000_000_000;
        }
      };
    };
  };

  // ===== MIXINS =====

  include MixinCommon({
    thisPrincipal = thisPrincipal;
    thisKind = #static(#factory);
  });
  
  switch ( memMapping.get(#static(#factory)) ) { // init the mapping with itself as the first known canister
    case null {
      let map = Map.singleton<Nat, Principal>(0, thisPrincipal);
      memMapping.add(#static(#factory), map);

      memKnownCanisters.add(thisPrincipal, 0);
    };
    case (?_) ();
  };

  include MixinFactoryJobs({ mappingToPublic = mappingToPublic });

  include MixinJobs<system>({ executeJob = executeJob });

  include MixinTopUpCycles<system>({
    memMapping = memMapping;
  });

  // ===== SYSTEM =====

  system func inspect({ arg : Blob; caller : Principal }) : Bool {
    inspectBasic({arg = arg; caller = caller; maxArgSize = 1000})
  };

  // ===== HELPERS =====

  func sendMappingToAll() : async () {
    for (target in memKnownCanisters.keys()) {
      ignore createAndProcessJob(#jobFactory(#sendMappingTo(target)));
    };
  };

  func createCanister(kind: Canisters.DynamicKind) : async Result.Result<Principal, Errors.ErrHandler> {
    let nbCycles = confGetNewCanisterNbCycles(kind);

    let settings = #new {
      settings = ?{
        controllers = ?[owner, thisPrincipal];
        compute_allocation = null; // reserve a percentage of execution on the network
        memory_allocation = null; // preallocate memory for the canister
        freezing_threshold = null; // time vefore canister is deleted if no cycles, default = 2_592_000 (30 days in seconds)
      }
    };

    let principal = try {
      switch (kind) {
        case (#orderedByHash(h)) {
          switch (h) {
            case (#bucketUsers) Principal.fromActor(await (with cycles = nbCycles) (system BucketUsers.BucketUsers)(settings)());
            case (#searchIndexes) Principal.fromActor(await (with cycles = nbCycles) (system SearchIndexes.SearchIndexes)(settings)());
          }
        };
        case (#orderedByTime(i)) {
          switch (i) {
            case (#indexMain) Principal.fromActor(await (with cycles = nbCycles) (system IndexMain.IndexMain)(settings)());
          }
        };
      };
    } catch e {
      return #err(#errInterCanisterCall("Cannot create canister, error: " # e.message()));
    };

    #ok(principal)
  };

  func addOrderedByTimeCanister(kind: Canisters.OrderedByTimeKind, principal: Principal) : async () {
    let index = switch ( memMapping.get(#dynamic(#orderedByTime(kind))) ) {
      case null 0;
      case (?map) map.size();
    };

    await saveNewMapping(#dynamic(#orderedByTime(kind)), index, principal);
  };

  func addOrderedByHashCanister(kind: Canisters.OrderedByHashKind, principal: Principal, index: Nat) : async () {
    await saveNewMapping(#dynamic(#orderedByHash(kind)), index, principal);
  };

  func saveNewMapping(kind: Canisters.CanisterKind, index: Nat, principal: Principal) : async () {
    let map = switch ( memMapping.get(kind)) {
      case null {
        let newMap = Map.empty<Nat, Principal>();
        memMapping.add(kind, newMap);
        newMap
      };
      case (?map) map;
    };

    map.add(index, principal);
    memKnownCanisters.add(principal, index);
    memCurrentVersion += 1;

    ignore sendMappingToAll();
  };

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerAddStaticCanisters(entries: [(Canisters.StaticKind, Principal)]) : async Result.Result<(), Errors.ErrHandler> {
    switch ( canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    for (entry in entries.values()) {
      let (kind, principal) = entry;

      let map = switch ( memMapping.get(#static(kind)) ) {
        case null {
          let newMap = Map.empty<Nat, Principal>();
          memMapping.add(#static(kind), newMap);
          newMap
        };
        case (?map) map;
      };

      let index = map.size();

      map.add(index, principal);
      memKnownCanisters.add(principal, index);
    };

    #ok
  };

  public query ({ caller }) func handlerGetCanistersOfKind(kind: Canisters.CanisterKind) : async Result.Result<[Principal], Errors.ErrHandler> {
    switch ( canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    let ?map = memMapping.get(kind) else return #err(#errNotFound("No canisters found for kind "));
    #ok(map.values().toArray())
  };

  public shared ({ caller }) func handlerCreateOrderedByTimeCanister(kind: Canisters.OrderedByTimeKind) : async Result.Result<Principal, Errors.ErrHandler> {
    switch ( canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    // 1. CREATE THE CANISTER

    let newPrincipal = switch (await createCanister(#orderedByTime(kind))) {
      case (#ok(p)) p;
      case (#err(e)) return #err(e);
    };

    // 2. SAVE THE CANISTER INFORMATION

    await addOrderedByTimeCanister(kind, newPrincipal);

    #ok(newPrincipal)
  };

  public shared ({ caller }) func handlerCreateOrderedByHashCanister(kind: Canisters.OrderedByHashKind, index: Nat) : async Result.Result<Principal, Errors.ErrHandler> {
    if ( not caller.isController() ) return #err(#errForbidden);

    // 1. VALIDATE INPUT
    if (index < 0) return #err(#errBadRequest("Index must be non-negative"));

    switch ( memMapping.get(#dynamic(#orderedByHash(kind))) ) {
      case null ();
      case (?map) {
        if (map.containsKey(index)) return #err(#errBadRequest("Index already exists"));
      };
    };

    // 2. CREATE THE CANISTER

    let newPrincipal = switch (await createCanister(#orderedByHash(kind))) {
      case (#ok(p)) p;
      case (#err(e)) return #err(e);
    };

    // 3. SAVE THE CANISTER INFORMATION

    await addOrderedByHashCanister(kind, newPrincipal, index);

    #ok(newPrincipal)
  };
};