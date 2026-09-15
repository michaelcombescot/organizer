import Result "mo:core/Result";

module {
    // Canisters Kinds

    public type CanisterKind = {
        #coordinator;
        #index;
        #registry: RegistryKind;
        #bucket: BucketKind;
    };

    public type RegistryKind = {
        #registryGroups;
        #registryUsers;
    };

    public type BucketKind = {
        #usersBucket;
        #groupsBucket;
    };



    // Actor Interfaces

    public type ICoordinator = actor {
        handlerTopCanister: shared (canisterPrincipal: Principal, kind: CanisterKind) -> async Result.Result<(), Text>;
        handlerCreateBucket: shared (bucketKind: CanisterKind) -> async Result.Result<Principal, Text>;
        handlerGetRegistries: shared () -> async Result.Result<[Principal], Text>;
        handlerGetIndexes: shared () -> async Result.Result<[Principal], Text>;
    };
}