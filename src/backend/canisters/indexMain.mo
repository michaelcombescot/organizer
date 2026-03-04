import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Runtime "mo:core/Runtime";
import Debug "mo:core/Debug";
import Timer "mo:core/Timer";
import BucketGroups "bucketGroups";
import BucketUsers "bucketUsers";
import Identifiers "../shared/identifiers";
import Group "../models/todosGroup";
import UsersMapping "../shared/usersMapping";
import MixinAllowedCanisters "mixins/mixinAllowedCanisters";
import MixinOpsOperations "mixins/mixinOpsOperations";

// only goal of this canister is too keep track of the relationship between users principals and canisters.
// this is the main piece of code which should need to change in case of scaling needs (by adding new users buckets )
shared ({ caller = owner }) persistent actor class IndexMain() = this {
    let thisPrincipal = Principal.fromActor(this);

    include MixinOpsOperations({
        coordinatorPrincipal    = owner;
        canisterPrincipal       = Principal.fromActor(this);
        toppingThreshold        = 2_000_000_000_000;
        toppingAmount           = 2_000_000_000_000;
        toppingIntervalNs       = 20_000_000_000;
    });
    include MixinAllowedCanisters(coordinatorActor);

    // ===== ERRORS =====

    let ERR_CANNOT_FIND_CURRENT_BUCKET = "ERR_CANNOT_FIND_CURRENT_BUCKET";

    // ===== MEMORY =====

    var memoryUsersMapping: [Principal] = [];

    var currentGroupBucket: ?BucketGroups.BucketGroups = null;

    // ===== JOBS =====

    ignore Timer.setTimer<system>(
        #seconds(0),
        func () : async () {
            ignore Timer.recurringTimer<system>(#hours(24), topCanisterRequest);
            await topCanisterRequest();
        }
    );

    // ===== SYSTEM =====

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemSetUserMapping : () -> (mapping: [Principal]);

            #handlerFetchOrCreateUser : () -> ();

            #handlerCreateGroup : () -> (params: Group.CreateGroupParams);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemSetUserMapping(_)) params.caller == owner;

            case (#handlerFetchOrCreateUser(_)) true;

            case (#handlerCreateGroup(_)) true;
        }
    };

    public shared func systemSetUserMapping(mapping: [Principal]) : async () {
        Debug.print("[mainIndex " # Principal.toText(thisPrincipal) # "] Set users mapping");
        memoryUsersMapping := mapping;
    };

    // ===== HANDLERS USERS =====

    public shared ({ caller }) func handlerFetchOrCreateUser() : async Result.Result<Principal, Text> {
        Debug.print("array: " # debug_show(memoryUsersMapping));

        let bucketPrincipal = UsersMapping.helperFetchUserBucket(memoryUsersMapping, caller);

        switch ( await (actor(Principal.toText(bucketPrincipal)): BucketUsers.BucketUsers).handlerCreateUser({ userPrincipal = caller }) ) {
            case (#ok()) #ok(bucketPrincipal);
            case (#err(e)) #err(e);
        }
    };

    // ===== HANDLERS GROUPS =====

    public shared ({ caller }) func handlerCreateGroup(params: Group.CreateGroupParams) : async Result.Result<Identifiers.Identifier, Text> {
        let ?bucket = await helperFetchCurrentGroupBucket() else return #err(ERR_CANNOT_FIND_CURRENT_BUCKET);
    
        switch ( await bucket.handlerCreateGroup(caller, params) ) {
            case (#ok(resp)) {
                if ( resp.isFull ) { currentGroupBucket := null; };
                #ok(resp.identifier);
            };
            case (#err(e)) return #err(e);
        }
    };

    // ===== HELPERS =====

    func helperFetchCurrentGroupBucket() : async ?BucketGroups.BucketGroups {
        switch ( currentGroupBucket ) {
            case (?_) ();
            case (null) {
                switch ( await coordinatorActor.handlerCreateBucket(#bucketGroups) ) {
                    case (#ok(principal)) currentGroupBucket := ?(actor(Principal.toText(principal)) : BucketGroups.BucketGroups);
                    case (#err(err)) Runtime.trap("Error while fetching new bucket: " # err);
                };
            }
        };

        currentGroupBucket
    };
};