import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import User "../../models/User";
import MixinJobTopUpCycles "../mixins/MixinJobTopUpCycles";
import Errors "../../shared/Errors";
import Identifiers "../../shared/identifiers";

shared ({ caller = owner }) persistent actor class BucketUsers() = this {
    let thisPrincipal = Principal.fromActor(this);

    include MixinJobTopUpCycles<system>({
        adminPrincipal    = owner;
        canisterPrincipal = thisPrincipal;
        kind              = #bucket(#bucketUsers);
    });

    // ===== MEMORY =====

    let memUsers = Map.empty<Principal, User.User>();

    // ===== SYSTEM =====

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
        #systemAddIndex : () -> (userPrincipal : [Principal]);
        #handlerCreateUser : () -> (userPrincipal : Principal, name : Text, email : Text);
        #handlerGetUserData : () -> (userPrincipal : Principal)
      }
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 5000 ) { return false; };

        switch ( params.msg ) {
            case (#systemAddIndex(_)) params.caller.isController();
            case (#handlerGetUserData(_)) true;
            case (#handlerCreateUser(_)) true;
        }
    };

    // ===== HANDLERS =====

    public query func handlerGetUserData( userPrincipal: Principal ) : async Result.Result<User.PublicUser, Errors.HandlerErr> {
        let ?user = memUsers.get(userPrincipal) else return #err(#errNotFound);

        #ok(user.toPublic());
    };

    public shared func handlerCreateUser(userPrincipal: Principal, name: Text, email: Text) : async Result.Result<(), Errors.HandlerErr> {
        if ( memUsers.containsKey(userPrincipal) ) return #err(#errValidation([{ field = "userPrincipal"; message = "User already exists" }]));

        let user: User.User = {
            data = {
                name = name;
                email = email;
            };
            groups = Map.empty<Identifiers.Identifier, ()>();
            createdAt = Time.now();
            updatedAt = Time.now();
        };

        memUsers.add(userPrincipal, user);

        #ok();
    };
};