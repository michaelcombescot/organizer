import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Timer "mo:core/Timer";
import Blob "mo:core/Blob";
import Debug "mo:core/Debug";
import IC "mo:ic";
import Error "mo:core/Error";
import MixinKnownCanisters "../../shared/mixins/MixinKnownCanisters";
import { Kind = {type CanisterKind} } "../../shared/Canisters";
import Configs "../../Configs";

shared ({ caller = owner }) persistent actor class WorkerTopUp(knownCanisters: [(Principal, CanisterKind)]) = this {
  // ===== MEMORY =====

  include MixinKnownCanisters(knownCanisters);

  // ===== SYSTEM =====

  type InspectParams = {
    arg: Blob;
    caller : Principal;
    msg : {
      #handlerSetKnownCanistersByPrincipal : () -> (canisters : [(Principal, CanisterKind)]);
    };
};

  system func inspect(params: InspectParams) : Bool {
    params.caller.isController()
  };

  // ===== TIMERS =====

  Timer.recurringTimer<system>(
    #seconds(Configs.toppingPeriod), func () : async () {

      for ( (principal, kind) in memKnownCanisters.entries() ) {
        let status = await IC.ic.canister_status({ canister_id = principal });
        
        if (status.cycles > getToppingThreshold(kind)) continue;
          Debug.print("Topping canister " # principal.toText() # ". Current cycles: " # debug_show(status.cycles));

          try {
              await (with cycles = getToppingAmount(kind)) IC.ic.deposit_cycles({ canister_id = principal });
          } catch (e) {
              Debug.print("exception occurred while topping canister" # principal.toText() # ", error: " # e.message());
          };
      }
  });
};

// ===== HELPERS =====

func getToppingThreshold(kind: CanisterKind) : Nat {
  switch (kind) {
    case(#index) Configs.toppingThresholdIndex;
    case(#registryIndexes) Configs.toppingThresholdRegistryIndexes;
    case(#bucket(bucketKind)) {
      switch (bucketKind) {
        case(#bucketUsers) Configs.toppingThresholdBuckets;
      };
    };
    case(#search(searchkind)) {
      switch (searchkind) {
        case(#searchUsers) Configs.toppingThresholdSearch;
      };
    };
    case(#worker(workerKind)) {
      switch (workerKind) {
        case(#workerTopUp) Configs.toppingThresholdWorkerTopUp;
        case(#workerApp) Configs.toppingThresholdWorkerApp;
      }
    };
  }
};

func getToppingAmount(kind: CanisterKind) : Nat {
  switch (kind) {
    case(#index) Configs.toppingAmountIndex;
    case(#registryIndexes) Configs.toppingAmountRegistryIndexes;
    case(#bucket(bucketKind)) {
      switch (bucketKind) {
        case(#bucketUsers) Configs.toppingAmountBuckets;
      };
    };
    case(#search(searchkind)) {
      switch (searchkind) {
        case(#searchUsers) Configs.toppingAmountSearch;
      };
    };
    case(#worker(workerKind)) {
      switch (workerKind) {
        case(#workerTopUp) Configs.toppingAmountWorkerTopUp;
        case(#workerApp) Configs.toppingAmountWorkerApp;
      }
    };
  }
};