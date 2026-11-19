import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Job "../../shared/Job";
import { type Result } "mo:core/Result";
import Canisters "../../shared/Canisters";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Time "mo:core/Time";
import Iter "mo:core/Iter";
import Errors "../../shared/Errors";
import { type HandlerErr } "../../shared/Errors";
import BucketUsers "../buckets/bucketUsers/BucketUsers";
import SearchIndexes "../searches/SearchIndexes";
import IndexMain "../indexes/IndexMain";

mixin<system>({
  owner: Principal;
  thisPrincipal: Principal;
  memMapping: Map.Map<Canisters.CanisterKind, Map.Map<Nat, Principal>>;
  memKnownCanisters: Map.Map<Principal, Nat>;
  memVersion: Canisters.Version;
  canAccess : (Principal) -> async Result<(), HandlerErr>;
  createAndExecuteJob : (job: Job.Job) -> async Result.Result<(), HandlerErr>;
}) {
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

  // ===== MEMORY =====

  let memJobsSendMapping = Map.empty<Principal, ()>();

  // ===== HELPERS =====

  func sendMappingToAll() : async () {
    for (target in memKnownCanisters.keys()) {
      ignore createAndExecuteJob(#jobFactory(#sendMappingTo(target)));
    };
  };

  func createCanister(kind: Canisters.DynamicKind) : async Result.Result<Principal, Errors.HandlerErr> {
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
    memVersion.currentVersion := memVersion.currentVersion + 1;
    memVersion.lastVersionMaj := Time.now();

    memJobsSendMapping.add(principal, ());
    ignore sendMappingToAll();
  };

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerCreateOrderedByTimeCanister(kind: Canisters.OrderedByTimeKind) : async Result.Result<Principal, Errors.HandlerErr> {
    let #ok = (await canAccess(caller)) else return #err(#errForbidden);

    // 1. CREATE THE CANISTER

    let newPrincipal = switch (await createCanister(#orderedByTime(kind))) {
      case (#ok(p)) p;
      case (#err(e)) return #err(e);
    };

    // 2. SAVE THE CANISTER INFORMATION

    await addOrderedByTimeCanister(kind, newPrincipal);

    #ok(newPrincipal)
  };

  public shared ({ caller }) func handlerCreateOrderedByHashCanister(kind: Canisters.OrderedByHashKind, index: Nat) : async Result.Result<Principal, Errors.HandlerErr> {
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

  public query ({ caller }) func handlerGetJobs() : async [Principal] {
    if ( caller.isController() ) return [];

    memJobsSendMapping.keys().toArray()
  };
}