import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import User "../../../models/User";
import { type User; type PublicUser } "../../../models/User";
import Errors "../../../shared/Errors";
import Identifiers "../../../shared/Identifiers";
import { Kind = { type CanisterKind} } "../../../shared/Canisters";
import MixinCanistersByPrincipal "../../../shared/mixins/MixinCanistersByPrincipal";
import { type Job } "../../../models/Job";

shared ({ caller = owner }) persistent actor class BucketUsers(canisters: [Principal]) = this {
  include MixinCanistersByPrincipal(canisters);
  
  // ===== MEMORY =====

  let memUsers = Map.empty<Principal, User>();

  // ===== SYSTEM =====

  type InspectParams = {
      arg: Blob;
      caller : Principal;
      msg : {
      #handlerCreateUser : () -> (params: CreateUserParams);
      #handlerUpdateUser : () -> (params: UpdateUserParams);
      #handlerGetUserData : () -> ();
      #handlerDeleteUser : () -> (userPrincipal : Principal);
    } or InspectParamsMsgKnownCanistersByPrincipal
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller == Principal.anonymous() ) { return false; };

      if ( Blob.size(params.arg) > 300 ) { return false; };

      isControllerOrKnownCanister(params.caller)
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetUserData() : async Result<PublicUser, Errors.HandlerErr> {
      let ?user = memUsers.get(caller) else return #err(#errNotFound);

      #ok(user.toPublic());
  };

  public type CreateUserParams = {
    userPrincipal: Principal;
    name: Text;
    email: Text;
  };

  public shared ({ caller }) func handlerCreateUser(params: CreateUserParams) : async Result<(), Errors.HandlerErr> {
    if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

    if ( memUsers.containsKey(params.userPrincipal) ) return #err(#errValidation([{ field = "userPrincipal"; message = "User already exists" }]));

    let user: User = {
      data = {
        name = params.name;
        email = params.email;
      };
      groups = Map.empty<Identifiers.Identifier, ()>();
      createdAt = Time.now();
      updatedAt = Time.now();
    };

    memUsers.add(params.userPrincipal, user);

    #ok();
  };

  public type UpdateUserParams = {
    userPrincipal: Principal;
    name: Text;
    email: Text;
  };

  public shared ({ caller }) func handlerUpdateUser(params: UpdateUserParams) : async Result<(), Errors.HandlerErr> {
    if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

    let ?user = memUsers.get(params.userPrincipal) else return #err(#errNotFound);

    let updatedData = { user.data with name = params.name; email = params.email };
    let updatedUser = { user with data = updatedData; updatedAt = Time.now() };

    memUsers.add(params.userPrincipal, updatedUser);

    #ok();
  };

  public shared ({ caller }) func handlerDeleteUser(userPrincipal: Principal) : async Result<(), Errors.HandlerErr> {
    if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

    if ( not memUsers.containsKey(userPrincipal) ) return #err(#errNotFound);

    memUsers.remove(userPrincipal);

    #ok();
  };
};