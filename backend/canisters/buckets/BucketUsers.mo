import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Error "mo:core/Error";
import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import List "mo:core/List";
import User "../../models/User";
import { type User; type PublicUser; type PrivateUser } "../../models/User";
import Errors "../../shared/Errors";
import Loc "../../shared/Loc";
import Canisters "../../shared/Canisters";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";

shared ({ caller }) actor class BucketUsers(mapping: ?Canisters.Mapping) = this {
  let thisPrincipal = Principal.fromActor(this);

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
      #handlerGetUsersPublicData : () -> (usersPrincipals: [Principal]);
      #handlerGetCurrentUserData : () -> ();
      #handlerCreateUser : () -> ();
      #handlerDeleteUser : () -> ();
      #handlerUpdateUser : () -> {email : Text; name : Text; }
    } or InspectMapping;
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller == Principal.anonymous() ) { return false };
      if ( Blob.size(params.arg) > 1000 ) { return false };

      true;
  };

  // ===== HANDLERS =====

  public query ({caller}) func handlerGetUsersPublicData(usersPrincipals: [Principal]) : async Result<[PublicUser], Errors.HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);
    if ( Array.size(usersPrincipals) > 50 ) return #err(#errBadRequest("Too many principals requested"));

    let users = List.empty<PublicUser>();
    for (p in usersPrincipals.values()) {
      let ?user = memUsers.get(p) else return #err(#errNotFound("User not found"));
      users.add(user.toPublic(p));
    };

    #ok(users.toArray());
  };

  public query ({ caller }) func handlerGetCurrentUserData() : async Result<PrivateUser, Errors.HandlerErr> {
      if ( caller.isAnonymous() ) return #err(#errForbidden);

      let ?user = memUsers.get(caller) else return #err(#errNotFound("User not found"));

      #ok(user.toPrivate());
  };

  public shared ({ caller }) func handlerCreateUser() : async Result<(), Errors.HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);
    if ( memUsers.size() >= maxNumberOfusers ) return #err(#errMemoryLimitReached);

    if ( memUsers.containsKey(caller) ) return #err(#errValidation([#alreadyExists { field = "caller" }]));

    let ?indexPrincipal = createActorSearchIndexesFor(caller.toText()) else return #err(#errNotFound("Failed to create actor search index for caller"));
    let ?thisIndex = memKnownCanisters.get(thisPrincipal) else return #err(#errNotFound("Failed to retrieve index for this canister"));

    let user: User = {
      data = { name = ""; email = "" };
      groups = Map.empty<Loc.Loc, ()>();
      createdAt = Time.now();
      updatedAt = Time.now();
    };

    try {
      ignore switch ( await indexPrincipal.handlerSaveEntry({
        kind = #usersByPrincipal;
        loc = { id = null; principal = ?caller; bucketHash = thisIndex};
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
    let ?user = memUsers.get(caller) else return #err(#errNotFound("User not found"));

    // Update data and create a checkpoint
    let updatedData = { user.data with name = name; email = email };
    let updatedUser = { user with data = updatedData; updatedAt = Time.now() };

    memUsers.add(caller, updatedUser);

    // save in search canisters
    if (name != user.data.name) {
      let ?searchForNewName = createActorSearchIndexesFor(updatedData.name) else return #err(#errNotFound("Failed to create actor search index for caller"));
      let ?searchForOldName = createActorSearchIndexesFor(user.data.name) else return #err(#errNotFound("Failed to create actor search index for old name"));
    };

    if (email != user.data.email) {
      let ?searchForEmail = createActorSearchIndexesFor(caller.toText()) else return #err(#errNotFound("Failed to create actor search index for caller"));
    };

    try {
      ignore switch ( await indexPrincipal.handlerSaveEntry({
        kind = #usersByPrincipal;
        loc = { id = null; principal = ?caller; bucketHash = thisIndex};
        key = caller.toText()
      }) ) {
        case (#ok) ();
        case (#err(e)) return #err(e);
      };
    } catch e {
      return #err(#errInterCanisterCall("Failed to save entry in actor search index: " # e.message()));
    };

    #ok
  };

  public shared ({ caller }) func handlerDeleteUser() : async Result<(), Errors.HandlerErr> {
    if ( not memUsers.containsKey(caller) ) return #err(#errNotFound("User not found"));

    memUsers.remove(caller);

    #ok
  };
};