import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Time "mo:core/Time";
import Timer "mo:core/Timer";
import UserData "../models/todosUserData";
import Identifiers "../shared/identifiers";
import MixinAllowedCanisters "mixins/mixinAllowedCanisters";
import MixinOpsOperations "mixins/mixinOpsOperations";

shared ({ caller = owner }) persistent actor class BucketUsers() = this {
    include MixinOpsOperations({
        coordinatorPrincipal    = owner;
        canisterPrincipal       = Principal.fromActor(this);
        toppingThreshold        = 2_000_000_000_000;
        toppingAmount           = 2_000_000_000_000;
        toppingIntervalNs       = 20_000_000_000;
    });
    include MixinAllowedCanisters(coordinatorActor);

    // ===== ERRORS =====

    let ERR_USER_NOT_FOUND = "ERR_USER_NOT_FOUND";
    let ERR_USER_ALREADY_EXISTS = "ERR_USER_ALREADY_EXISTS";

    // ===== MEMORY =====

    let memoryUsers = Map.empty<Principal, UserData.UserData>();

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
            #handlerGetUserData : () -> (userPrincipal: Principal);
            #handlerCreateUser : () -> { userPrincipal: Principal; };
        }
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#handlerGetUserData(_))       true;
            case (#handlerCreateUser(_))        true;
        }
    };

    // ===== HANDLERS =====

    public shared func handlerGetUserData( userPrincipal: Principal ) : async Result.Result<UserData.SharableUserData, Text> {
        let ?userData = memoryUsers.get(userPrincipal) else return #err(ERR_USER_NOT_FOUND);

        #ok({
            name = userData.name;
            email = userData.email;
            groups = Array.fromIter( Map.keys(userData.groups) );
            createdAt = userData.createdAt;
        })
    };

    public shared func handlerCreateUser({ userPrincipal: Principal; }) : async Result.Result<(), Text> {
        switch ( memoryUsers.get(userPrincipal) ) {
            case (?_) return #err(ERR_USER_ALREADY_EXISTS);
            case null ();
        };

        // create user data
        let userData: UserData.UserData = {
            name = "";
            email = "";
            groups = Map.empty<Identifiers.Identifier, ()>();
            createdAt = Time.now();
        };

        memoryUsers.add(userPrincipal, userData);

        #ok();
    };
};