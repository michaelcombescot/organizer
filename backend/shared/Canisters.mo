import Order "mo:core/Order";
import Text "mo:core/Text";

module Kind {
  // ===== Canisters Kinds =====

  public type CanisterKind = {
    #registryIndexes;
    #index;
    #worker: WorkerKind;
    #search: SearchKind;
    #bucket: BucketKind;
  };

  public type WorkerKind = {
    #workerApp;
    #workerTopUp;
  };

  public type SearchKind = {
    #searchUsers;
  };

  public type BucketKind = {
    #bucketUsers;
  };

  public func compareCanisterKind(a: CanisterKind, b: CanisterKind) : Order.Order {
    Text.compare(debug_show(a), debug_show(b));
  };
};

module Interfaces {

};

module Utils {
  
};