import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Map "mo:core/Map";
import Canisters "../../shared/Canisters";
import Errors "../../shared/Errors";
import { ic } "mo:ic";

module {
    // ===== CONFIGS =====

  let TOPPING_LIMIT_REGISTRY_INDEXES = 1_000_000_000_000;
  let TOPPING_AMOUNT_REGISTRY_INDEXES = 1_000_000_000_000;

  let TOPPING_LIMIT_FACTORY = 1_000_000_000_000;
  let TOPPING_AMOUNT_FACTORY = 1_000_000_000_000;

  let TOPPING_LIMIT_INDEX_MAIN = 1_000_000_000_000;
  let TOPPING_AMOUNT_INDEX_MAIN = 1_000_000_000_000;

  let TOPPING_LIMIT_SEARCH_INDEX = 1_000_000_000_000;
  let TOPPING_AMOUNT_SEARCH_INDEX = 1_000_000_000_000;

  let TOPPING_LIMIT_BUCKETS = 1_000_000_000_000;
  let TOPPING_AMOUNT_BUCKETS = 1_000_000_000_000;

  // ===== HELPERS =====

  public func topUpCanister(kind: Canisters.CanisterKind, canisterId: Principal) : async Result.Result<(), Errors.HandlerErr> {
    let status =try {
      await ic.canister_status({ canister_id = canisterId; })
    } catch (e) {
      return #err(#errInterCanisterCall("Cannot get status of canisterId " # canisterId.toText() # ", error: " # e.message() ))
    };

    let (toppingAmount, toppingLimit) = switch (kind) {
      case (#static(s)) {
        switch (s) {
          case (#admin) (0, 0);
          case (#registryIndexes) (TOPPING_AMOUNT_REGISTRY_INDEXES, TOPPING_LIMIT_REGISTRY_INDEXES);
          case (#factory) (TOPPING_AMOUNT_FACTORY, TOPPING_LIMIT_FACTORY);
        };
      };
      case (#dynamic(d)) {
        switch (d) {
          case (#orderedByHash(h)) {
            switch (h) {
              case (#bucketUsers) (TOPPING_AMOUNT_BUCKETS, TOPPING_LIMIT_BUCKETS);
              case (#searchIndexes) (TOPPING_AMOUNT_SEARCH_INDEX, TOPPING_LIMIT_SEARCH_INDEX);
            };
          };
          case (#orderedByTime(s)) {
            switch (s) {
              case (#indexMain) (TOPPING_AMOUNT_INDEX_MAIN, TOPPING_LIMIT_INDEX_MAIN);
            };
          }
        };
      }
    };

    if (status.cycles < toppingLimit) {
      try {
        await (with cycles = toppingAmount) ic.deposit_cycles({ canister_id = canisterId });
      } catch (e) {
        return #err(#errInterCanisterCall("Cannot top up canister with canisterId " # canisterId.toText() # ", error: " # e.message() ));
      };
    };

    #ok(());
  };

  public func topUpCanisters(mapping: Map.Map<Canisters.CanisterKind, Map.Map<Nat, Principal>>) : async () {
    for ( (kind, map) in mapping.entries() ) {
      for ( (index, principal) in map.entries() ) {
        ignore await topUpCanister(kind, principal);
      };
    };
  };
}