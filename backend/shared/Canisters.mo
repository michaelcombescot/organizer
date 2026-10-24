import Text "mo:core/Text";
import Order "mo:core/Order";

module {
  public module CanisterKind {
    // ===== Canisters Kinds =====

    public type CanisterKind = {
      // declared directly in the icp.yaml, known from the frontend, wll be called exclusively for discovery
      // or very specific tasks, no data associated
      #static: StaticKind.StaticKind;
      // canisters responsible of redirecting the frontend to the right canister
      #indexes: IndexKind.IndexKind;
      // all canisters for storing data
      #buckets: BucketKind.BucketKind;
      // all canisters for system wide search queries
      #queries: QueryKind.QueryKind; // canister responsible for handling global search operations
    };

    public func compare(a: CanisterKind, b: CanisterKind) : Order.Order {
      Text.compare(debug_show(a), debug_show(b));
    };
  };

  public module StaticKind {
    public type StaticKind = {
      #admin; // canister responsible for administrative tasks (topping up cycles, checking status etc)
      #factory; // canister responsible for creating other canisters, is the absolute reference for the canisters mapping
      #registryIndexes; // canister responsible for index canisters discovery
    };

    public func compare(a: StaticKind, b: StaticKind) : Order.Order {
      Text.compare(debug_show(a), debug_show(b));
    };
  };

  public module IndexKind {
    public type IndexKind = {
      #indexMain; // canister responsible for frontend buckets discovery
    };

    public func compare(a: IndexKind, b: IndexKind) : Order.Order {
      Text.compare(debug_show(a), debug_show(b));
    };
  };

  public module BucketKind {
    public type BucketKind = {
      #bucketUsers; // canister storing user-related data in a bucket
    };

    public func compare(a: BucketKind, b: BucketKind) : Order.Order {
      Text.compare(debug_show(a), debug_show(b));
    };
  };
  
  public module QueryKind {
    public type QueryKind = {
      #queriesIndex; // canister responsible for global search operations on text values
    };

    public func compare(a: QueryKind, b: QueryKind) : Order.Order {
      Text.compare(debug_show(a), debug_show(b));
    };
  };
}