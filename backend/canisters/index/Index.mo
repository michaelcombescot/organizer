import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Runtime "mo:core/Runtime";
import Debug "mo:core/Debug";
import Timer "mo:core/Timer";
// import BucketGroups "bucketGroups";
// import BucketUsers "bucketUsers";
// import Identifiers "../shared/identifiers";
// import Group "../models/todosGroup";
// import UsersMapping "../shared/usersMapping";
import MixinTopUpCycles "../mixins/MixinTopUpCycles";
import Configs "../../Configs";

// Index is here to:
// - give informations about where to find items:
//   -> principal of the canister for the data of a specific user
//   -> spawning queries among canister (like all users with a name containing a substring, etc)
// - handle all opération necessiting an intercanister call:
//   -> coordination inter-buckets (creating a group + associating the group to a user)
//   -> communication with the coordinator canister factory
shared ({ caller = owner }) persistent actor class Index() = this {
    let thisPrincipal = Principal.fromActor(this);

    // ===== MEMORY =====

    var memoryUsersMapping: [Principal] = [];

    // var currentGroupBucket: ?BucketGroups.BucketGroups = null;

    // ===== JOBS =====

    

    // ===== SYSTEM =====

    include MixinTopUpCycles<system>({
        coordinatorPrincipal    = owner;
        canisterPrincipal       = Principal.fromActor(this);
        toppingThreshold        = Configs.toppingThresholdIndex;
        toppingIntervalNs       = Configs.toppingIntervalIndex;
        kind                    = #index;
    });

    // type InspectParams = {
    //     arg: Blob;
    //     caller : Principal;
    //     msg : {
    //         #systemSetUserMapping : () -> (mapping: [Principal]);

    //         #handlerFetchOrCreateUser : () -> ();

    //         #handlerCreateGroup : () -> (params: Group.CreateGroupParams);
    //     };
    // };

    // system func inspect(params: InspectParams) : Bool {
    //     if ( params.caller == Principal.anonymous() ) { return false; };

    //     switch ( params.msg ) {
    //         case (#systemSetUserMapping(_)) params.caller == owner;

    //         case (#handlerFetchOrCreateUser(_)) true;

    //         case (#handlerCreateGroup(_)) true;
    //     }
    // };

    // public shared func systemSetUserMapping(mapping: [Principal]) : async () {
    //     Debug.print("[mainIndex " # Principal.toText(thisPrincipal) # "] Set users mapping");
    //     memoryUsersMapping := mapping;
    // };

    // // ===== HANDLERS USERS =====

    // public shared ({ caller }) func handlerFetchOrCreateUser() : async Result.Result<Principal, Text> {
    //     Debug.print("array: " # debug_show(memoryUsersMapping));

    //     let bucketPrincipal = helperFindUserBucket(memoryUsersMapping, caller);

    //     switch ( await (actor(Principal.toText(bucketPrincipal)): BucketUsers.BucketUsers).handlerCreateUser({ userPrincipal = caller }) ) {
    //         case (#ok()) #ok(bucketPrincipal);
    //         case (#err(e)) #err(e);
    //     }
    // };

    // // ===== HANDLERS GROUPS =====

    // public shared ({ caller }) func handlerCreateGroup(params: Group.CreateGroupParams) : async Result.Result<Identifiers.Identifier, Text> {
    //     let ?bucket = await helperFetchCurrentGroupBucket() else return #err(ERR_CANNOT_FIND_CURRENT_BUCKET);
    
    //     switch ( await bucket.handlerCreateGroup(caller, params) ) {
    //         case (#ok(resp)) {
    //             if ( resp.isFull ) { currentGroupBucket := null; };
    //             #ok(resp.identifier);
    //         };
    //         case (#err(e)) return #err(e);
    //     }
    // };

    // // ===== HELPERS =====

    // func helperFetchCurrentGroupBucket() : async ?BucketGroups.BucketGroups {
    //     switch ( currentGroupBucket ) {
    //         case (?_) ();
    //         case (null) {
    //             switch ( await coordinatorActor.handlerCreateBucket(#bucketGroups) ) {
    //                 case (#ok(principal)) currentGroupBucket := ?(actor(Principal.toText(principal)) : BucketGroups.BucketGroups);
    //                 case (#err(err)) Runtime.trap("Error while fetching new bucket: " # err);
    //             };
    //         }
    //     };

    //     currentGroupBucket
    // };

    func helperFindUserBucket(array: [Principal], userPrincipal: Principal) : Principal {
        let userPrincipalHash = Principal.hash(userPrincipal);
        array[ Nat32.toNat(userPrincipalHash) % array.size()]
    };
};