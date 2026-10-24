import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import User "../../../models/User";
import { type User; type PublicUser } "../../../models/User";
import Errors "../../../shared/Errors";
import Loc "../../../shared/Loc";
import { CanisterKind } "../../../shared/Canisters";
import MixinCanistersMapping "../../../shared/mixins/MixinCanistersMapping";
import { type Job } "../../../models/Job";

shared ({ caller }) actor class BucketUsers(mapping: [(CanisterKind.CanisterKind, [(Nat, Principal)])]) = this {
  include MixinCanistersMapping({ self = Principal.fromActor(this); selfKind = #buckets(#bucketUsers); canisters = mapping });
  
  // ===== CONFIGS =====

  let maxNumberOfusers = 10_000_000;

  // ===== MEMORY =====

  let memUsers = Map.empty<Principal, User>();

  // ===== SYSTEM =====

  type InspectParams = {
    arg: Blob;
    caller : Principal;
    msg : {
      #handlerCreateUser : () -> {email : Text; name : Text};
      #handlerDeleteUser : () -> ();
      #handlerGetUserData : () -> ();
      #handlerUpdateMapping : () -> (canisters : [(CanisterKind.CanisterKind, [(Nat, Principal)])]);
      #handlerUpdateUser : () -> {email : Text; name : Text; }
    } or InspectMappingMsg;
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller == Principal.anonymous() ) { return false; };

      if ( Blob.size(params.arg) > 1000 ) { return false; };

      isKnown(params.caller) or params.caller.isController()
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetUserData() : async Result<PublicUser, Errors.HandlerErr> {
      let ?user = memUsers.get(caller) else return #err(#errNotFound);

      #ok(user.toPublic());
  };

  public shared ({ caller }) func handlerCreateUser({ name: Text; email: Text }) : async Result<(), Errors.HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);
    if ( memUsers.size() >= maxNumberOfusers ) return #err(#errMemoryLimitReached);

    if ( memUsers.containsKey(caller) ) return #err(#errValidation([#alreadyExists { field = "caller" }]));

    let user: User = {
      data = {
        name = name;
        email = email;
      };
      groups = Map.empty<Loc.Loc, ()>();
      createdAt = Time.now();
      updatedAt = Time.now();
    };

    memUsers.add(caller, user);

    #ok();
  };

  public shared ({ caller }) func handlerUpdateUser({
    name: Text;
    email: Text
  }) : async Result<(), Errors.HandlerErr> {
    let ?user = memUsers.get(caller) else return #err(#errNotFound);

    let updatedData = { user.data with name = name; email = email };
    let updatedUser = { user with data = updatedData; updatedAt = Time.now() };

    memUsers.add(caller, updatedUser);

    #ok();
  };

  public shared ({ caller }) func handlerDeleteUser() : async Result<(), Errors.HandlerErr> {
    if ( not memUsers.containsKey(caller) ) return #err(#errNotFound);

    memUsers.remove(caller);

    #ok
  };
};