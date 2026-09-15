// This module is used to share jobs between different canisters.
// The main points will be to:
// - provide a standardized structure for job data
// - ensure a smooth communication between the coordinator and indexes
// - facilitate retry mechanisms for failed jobs between indexes and buckets (in case of need of intercanister calls)
module {
    public type Job = {
        id: Nat;
        retryCount: Nat;
        data: JobData;
    };

    public type JobData = {
        #fromCoordinator: FromCoordinator;
        #fromBucketUsers: FromBucketUsers;
        #fromBucketGroups: FromBucketGroups;
    };

    public type FromCoordinator = {
        #updateRegistryList: { index: Principal };
    };

    public type FromBucketUsers = {
        #addUserNameToRegistry: { user: Principal; name: Text };
    };

    public type FromBucketGroups = {
        #updateRegistryGroups: { group: Principal };
    };
}