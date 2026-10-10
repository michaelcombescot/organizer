import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Timer "mo:core/Timer";
import Debug "mo:core/Debug";
import IC "mo:ic";
import Error "mo:core/Error";
import { Kind = {type CanisterKind} } "../../shared/Canisters";
import Configs "../../Configs";

mixin <system>(knownCanisters: Map.Map<CanisterKind, Map.Map<Principal, ()>>) {
  // ===== HELPERS =====

  func getToppingThreshold(kind: CanisterKind) : Nat {
    switch (kind) {
      case(#index) Configs.TOPPING_THRESHOLD_INDEX;
      case(#registryIndexes) Configs.TOPPING_THRESHOLD_REGISTRY_INDEXES;
      case(#bucket(bucketKind)) {
        switch (bucketKind) {
          case(#bucketUsers) Configs.TOPPING_THRESHOLD_BUCKETS;
        };
      };
      case(#search(searchkind)) {
        switch (searchkind) {
          case(#searchUsers) Configs.TOPPING_THRESHOLD_SEARCH;
        };
      };
    }
  };

  func getToppingAmount(kind: CanisterKind) : Nat {
    switch (kind) {
      case(#index) Configs.TOPPING_AMOUNT_INDEX;
      case(#registryIndexes) Configs.TOPPING_AMOUNT_REGISTRY_INDEXES;
      case(#bucket(bucketKind)) {
        switch (bucketKind) {
          case(#bucketUsers) Configs.TOPPING_AMOUNT_BUCKETS;
        };
      };
      case(#search(searchkind)) {
        switch (searchkind) {
          case(#searchUsers) Configs.TOPPING_AMOUNT_SEARCH;
        };
      };
    }
  };

  // ===== TIMERS =====

  Timer.recurringTimer<system>(
    #seconds(Configs.TOPPING_PERIOD), func () : async () {
      for ( (kind, map) in knownCanisters.entries() ) {
        for ((principal, _) in map.entries()) {
        let status = await IC.ic.canister_status({ canister_id = principal });
        
        if (status.cycles > getToppingThreshold(kind)) continue;
          Debug.print("Topping canister " # principal.toText() # ". Current cycles: " # debug_show(status.cycles));

          try {
              await (with cycles = getToppingAmount(kind)) IC.ic.deposit_cycles({ canister_id = principal });
          } catch (e) {
              Debug.print("exception occurred while topping canister" # principal.toText() # ", error: " # e.message());
          };
        }
      }
  });
};