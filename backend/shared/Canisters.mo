import Text "mo:core/Text";
import Order "mo:core/Order";

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
      #searchUsers;
    };

    // NEVER FORGET TO UPDATE THIS WHEN ADDING NEW SEARCH KINDS
    public let allSearchKinds : [SearchKind] = [#searchUsers];

    public type BucketKind = {
      #bucketUsers;
    };

    // NEVER FORGET TO UPDATE THIS WHEN ADDING NEW BUCKET KINDS
    public let allBucketKinds : [BucketKind] = [#bucketUsers];

    public func compareCanisterKind(a: CanisterKind, b: CanisterKind) : Order.Order {
      Text.compare(debug_show(a), debug_show(b));
    };
  };

  public module Utils {
    
  };
}