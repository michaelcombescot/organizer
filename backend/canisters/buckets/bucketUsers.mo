import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import Array "mo:core/Array";
import User "../../models/User";
import Errors "../../shared/Errors";
import Identifiers "../../shared/Identifiers";
import Canisters "../../shared/Canisters";

shared ({ caller = owner }) persistent actor class BucketUsers(workers: [Principal]) = this {
    // ===== MEMORY =====

    let memWorkers = workers.map(func p : (Principal, ()) = (p, ())).values().toMap<Principal, ()>(Principal.compare);

    let memUsers = Map.empty<Principal, User.User>();

    // ===== SYSTEM =====

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
        #handlerAddKnownCanisters : () -> ([(Principal, Canisters.CanisterKind)]);
        #handlerRemoveKnownCanisters : () -> ([(Principal, Canisters.CanisterKind)]);
        #handlerCreateUser : () -> (userPrincipal : Principal, name : Text, email : Text);
        #handlerGetUserData : () -> (userPrincipal : Principal);
        #handlerDeleteUser : () -> (userPrincipal : Principal);
      }
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 5000 ) { return false; };

        switch ( params.msg ) {
            case (#handlerAddKnownCanisters(_)) params.caller.isController();
            case (#handlerRemoveKnownCanisters(_)) params.caller.isController();
            case (#handlerGetUserData(_)) true;
            case (#handlerCreateUser(_)) isKnownCanister(params.caller, #dynamic(#index));
            case (#handlerDeleteUser(_)) true;
        }
    };

    // ===== HANDLERS =====

    public query func handlerGetUserData( userPrincipal: Principal ) : async Result.Result<User.PublicUser, Errors.HandlerErr> {
        let ?user = memUsers.get(userPrincipal) else return #err(#errNotFound);

        #ok(user.toPublic());
    };

    public shared ({ caller }) func handlerCreateUser(userPrincipal: Principal, name: Text, email: Text) : async Result.Result<(), Errors.HandlerErr> {
      if ( isKnownCanister(caller, #dynamic(#index)) ) return #err(#errForbidden);

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

    public shared ({ caller }) func handlerDeleteUser(userPrincipal: Principal) : async Result.Result<(), Errors.HandlerErr> {
      if ( isKnownCanister(caller, #dynamic(#index)) ) return #err(#errForbidden);

      if ( not memUsers.containsKey(userPrincipal) ) return #err(#errNotFound);

      memUsers.remove(userPrincipal);

      #ok();
    };
};