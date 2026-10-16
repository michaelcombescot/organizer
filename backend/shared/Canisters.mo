import Text "mo:core/Text";
import Order "mo:core/Order";
import Result "mo:core/Result";
import Errors "Errors";

module {
  public module Kind {
    // ===== Canisters Kinds =====

    public type CanisterKind = {
      #registryIndexes;
      #index;
      #search: SearchKind;
      #bucket: BucketKind;
    };

    public type SearchKind = {
      #searchUsersByName;
      #searchUsersByEmail;
    };

    // NEVER FORGET TO UPDATE THIS WHEN ADDING NEW SEARCH KINDS
    public let allSearchKinds : [SearchKind] = [#searchUsersByName, #searchUsersByEmail];

    public type BucketKind = {
      #bucketUsers;
    };

    // NEVER FORGET TO UPDATE THIS WHEN ADDING NEW BUCKET KINDS
    public let allBucketKinds : [BucketKind] = [#bucketUsers];

    public func compareCanisterKind(a: CanisterKind, b: CanisterKind) : Order.Order {
      Text.compare(debug_show(a), debug_show(b));
    };
  };

  public module Interfaces {
    public type AdminActor = actor {
      handlerGetFullMapping : shared query () -> async Result.Result<{version: Nat; mapping: [(Kind.CanisterKind, [Principal])]}, Errors.HandlerErr>;
    };
  };
}