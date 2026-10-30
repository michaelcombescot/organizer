import Text "mo:core/Text";
import Order "mo:core/Order";

module {
  public type CanisterKind = {
    // declared directly in the icp.yaml, known from the frontend, wll be called exclusively for discovery
    // or very specific tasks, no data associated
    #static: StaticKind;
    #dynamic: DynamicKind;
  };

  public func compare(a: CanisterKind, b: CanisterKind) : Order.Order {
    Text.compare(debug_show(a), debug_show(b));
  };

  public type StaticKind = {
    #admin; // canister responsible for administrative tasks (topping up cycles, checking status etc)
    #factory; // canister responsible for creating other canisters, is the absolute reference for the canisters mapping
    #registryIndexes; // canister responsible for index canisters discovery
  };

  public type DynamicKind = {
    #orderedByHash: OrderedByHashKind; // canister with data ordered by hash
    #orderedByTime: OrderedByTimeKind; // canister with data ordered in the order they are created
  };

  public type OrderedByHashKind = {
    #bucketUsers;
    #searchIndexes;
  };

  public type OrderedByTimeKind = {
    #indexMain; // main index canister, responsible for sequentially ordered data
  };

  public type Mapping = {
    version: Nat;
    canisters: [(CanisterKind, [(Nat, Principal)])];
  };
}