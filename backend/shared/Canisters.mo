import Result "mo:core/Result";
import Order "mo:core/Order";
import Text "mo:core/Text";

module {
    // Canisters Kinds

    public type CanisterKind = {
      #index;
      #registry: RegistryKind;
      #bucket: BucketKind;
    };

    public type RegistryKind = {
      #registryIndexes;
    };

    public type BucketKind = {
      #bucketUsers;
    };

    public func compareCanisterKind(a: CanisterKind, b: CanisterKind) : Order.Order {
      Text.compare(debug_show(a), debug_show(b));
    };

    // Actor Interfaces

    public type ICoordinator = actor {
      handlerTopCanister: shared (canisterPrincipal: Principal, kind: CanisterKind) -> async Result.Result<(), Text>;
      handlerCreateBucket: shared (bucketKind: CanisterKind) -> async Result.Result<Principal, Text>;
      handlerGetRegistries: shared () -> async Result.Result<[Principal], Text>;
      handlerGetIndexes: shared () -> async Result.Result<[Principal], Text>;
    };
}