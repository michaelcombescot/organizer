import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Error "mo:core/Error";
import Nat32 "mo:core/Nat32";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import User "../../models/User";
import { type User; type PublicUser } "../../models/User";
import Errors "../../shared/Errors";
import Loc "../../shared/Loc";
import Canisters "../../shared/Canisters";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import { type Job } "../../models/Job";

shared ({ caller }) actor class BucketUsers(mapping: ?Canisters.Mapping) = this {
  let thisPrincipal = Principal.fromActor(this);
  let thisHash = thisPrincipal.hash().toNat();

  include MixinCanistersMapping({ self = thisPrincipal; selfKind = #dynamic(#orderedByHash(#bucketUsers)); mapping = mapping });
  
  // ===== CONFIGS =====

  let maxNumberOfusers = 10_000_000;

  // ===== MEMORY =====

  let memUsers = Map.empty<Principal, User>();

  // ===== SYSTEM =====

  type InspectParams = {
    arg: Blob;
    caller : Principal;
    msg : {
      #handlerCreateUser : () -> ();
      #handlerDeleteUser : () -> ();
      #handlerGetUserData : () -> ();
      #handlerUpdateUser : () -> {email : Text; name : Text; }
    } or InspectMapping;
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller == Principal.anonymous() ) { return false };
      if ( Blob.size(params.arg) > 1000 ) { return false };

      true;
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetUserData() : async Result<PublicUser, Errors.HandlerErr> {
      let ?user = memUsers.get(caller) else return #err(#errNotFound);

      #ok(user.toPublic());
  };

  public shared ({ caller }) func handlerCreateUser() : async Result<(), Errors.HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);
    if ( memUsers.size() >= maxNumberOfusers ) return #err(#errMemoryLimitReached);

    if ( memUsers.containsKey(caller) ) return #err(#errValidation([#alreadyExists { field = "caller" }]));

    let ?indexPrincipal = createActorSearchIndexesFor(caller.toText()) else return #err(#errNotFound);

    let user: User = {
      data = { name = ""; email = "" };
      groups = Map.empty<Loc.Loc, ()>();
      createdAt = Time.now();
      updatedAt = Time.now();
    };

    try {
      ignore switch ( await indexPrincipal.handlerSaveEntry({
        kind = #usersByPrincipal;
        loc = { id = null; bucketHash = thisHash};
        key = caller.toText()
      }) ) {
        case (#ok) ();
        case (#err(e)) return #err(e);
      };
    } catch e {
      return #err(#errInterCanisterCall("Failed to save entry in actor search index: " # e.message()));
    };

    memUsers.add(caller, user);

    #ok
  };

  public shared ({ caller }) func handlerUpdateUser({
    name: Text;
    email: Text
  }) : async Result<(), Errors.HandlerErr> {
    let ?user = memUsers.get(caller) else return #err(#errNotFound);

    let updatedData = { user.data with name = name; email = email };
    let updatedUser = { user with data = updatedData; updatedAt = Time.now() };

    memUsers.add(caller, updatedUser);

    #ok
  };

  public shared ({ caller }) func handlerDeleteUser() : async Result<(), Errors.HandlerErr> {
    if ( not memUsers.containsKey(caller) ) return #err(#errNotFound);

    memUsers.remove(caller);

    #ok
  };
};