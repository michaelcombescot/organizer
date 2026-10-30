import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Blob "mo:core/Blob";
import Canisters "../../shared/Canisters";
import Time "mo:core/Time";
import Errors "../../shared/Errors";
import SearchIndexes "../searches/SearchIndexes";
import IndexMain "../indexes/IndexMain";
import BucketUsers "../buckets/BucketUsers";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";

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

  // ===== MEMORY =====

  include MixinCanistersMapping({ self = thisPrincipal; selfKind = #static(#factory); mapping = { version = 0; canisters = [(#static(#factory), [(0, thisPrincipal)])] } });

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #systemAddStaticCanisters : () -> (canisters : [(Canisters.StaticKind, Principal)]);

      #handlerGetFullMapping : () -> ();
      #handlerCreateOrderedByTimeCanister : () -> (kind : Canisters.OrderedByTimeKind);
      #handlerCreateOrderedByHashCanister : () -> (kind : Canisters.OrderedByHashKind, index: Nat);
    } or InspectMapping;
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous()) return false;

    return true
  };

  public shared ({ caller }) func systemAddStaticCanisters(canisters: [(Canisters.StaticKind, Principal)]) : async Result.Result<(), Errors.HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errForbidden);

    addStaticCanisters(canisters);
    #ok
  };

  // ===== INIT =====

  if (memMapping.size() == 0) saveMapping({ version = 0; canisters = [(#static(#factory), [(0, thisPrincipal)])] });

  // ===== HELPERS =====

  func createCanister(kind: Canisters.DynamicKind) : async Result.Result<Principal, Errors.HandlerErr> {
    let nbCycles = confGetNewCanisterNbCycles(kind);

    let ?adminPrincipal = getAdmin() else return #err(#errSystem("Admin principal not found"));

    let settings = #new {
      settings = ?{
        controllers = ?[thisPrincipal, adminPrincipal];
        compute_allocation = null; // reserve a percentage of execution on the network
        memory_allocation = null; // preallocate memory for the canister
        freezing_threshold = null; // time vefore canister is deleted if no cycles, default = 2_592_000 (30 days in seconds)
      }
    };

    let principal = try {
      switch (kind) {
        case (#orderedByHash(h)) {
          switch (h) {
            case (#bucketUsers) Principal.fromActor(await (with cycles = nbCycles) (system BucketUsers.BucketUsers)(settings)(knownCanistersToMapping()));
            case (#searchIndexes) Principal.fromActor(await (with cycles = nbCycles) (system SearchIndexes.SearchIndexes)(settings)(knownCanistersToMapping()));
          }
        };
        case (#orderedByTime(i)) {
          switch (i) {
            case (#indexMain) Principal.fromActor(await (with cycles = nbCycles) (system IndexMain.IndexMain)(settings)(knownCanistersToMapping()));
          }
        };
      };
    } catch e {
      return #err(#errInterCanisterCall("Cannot create canister, error: " # e.message()));
    };

    #ok(principal)
  };

  func addOrderedByTimeCanister(kind: Canisters.OrderedByTimeKind, principal: Principal) : () {
    let map = switch ( memMapping.get(#dynamic(#orderedByTime(kind))) ) {
      case null {
        let map = Map.empty<Nat, Principal>();
        memMapping.add(#dynamic(#orderedByTime(kind)), map);
        map
      };
      case (?map) map;
    };

    let index = map.size();

    map.add(index, principal);
    memKnownCanisters.add(principal, ());
    currentVersion := currentVersion + 1;
    lastVersionMaj := Time.now();
  };

  func addOrderedByHashCanister(kind: Canisters.OrderedByHashKind, principal: Principal, index: Nat) : () {
    let map = switch ( memMapping.get(#dynamic(#orderedByHash(kind))) ) {
      case null {
        let newMap = Map.empty<Nat, Principal>();
        memMapping.add(#dynamic(#orderedByHash(kind)), newMap);
        newMap
      };
      case (?map) map;
    };

    map.add(index, principal);
    memKnownCanisters.add(principal, ());
    currentVersion := currentVersion + 1;
    lastVersionMaj := Time.now();
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetFullMapping() : async Result.Result<{ version: Nat; canisters: [(Canisters.CanisterKind, [(Nat, Principal)])] }, Errors.HandlerErr> {
    if ( not (isKnownBasic(caller)) ) return #err(#errForbidden);

    #ok({ version = currentVersion; canisters = knownCanistersToMapping().canisters })
  };

  public shared ({ caller }) func handlerCreateOrderedByTimeCanister(kind: Canisters.OrderedByTimeKind) : async Result.Result<Principal, Errors.HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errForbidden);

    // 1. CREATE THE CANISTER

    let newPrincipal = switch (await createCanister(#orderedByTime(kind))) {
      case (#ok(p)) p;
      case (#err(e)) return #err(e);
    };

    // 2. SAVE THE CANISTER INFORMATION

    addOrderedByTimeCanister(kind, newPrincipal);

    #ok(newPrincipal)
  };

  public shared ({ caller }) func handlerCreateOrderedByHashCanister(kind: Canisters.OrderedByHashKind, index: Nat) : async Result.Result<Principal, Errors.HandlerErr> {
    if ( not caller.isController() ) return #err(#errForbidden);

    // 1. CREATE THE CANISTER

    let newPrincipal = switch (await createCanister(#orderedByHash(kind))) {
      case (#ok(p)) p;
      case (#err(e)) return #err(e);
    };

    // 2. SAVE THE CANISTER INFORMATION

    addOrderedByHashCanister(kind, newPrincipal, index);

    #ok(newPrincipal)
  };
};