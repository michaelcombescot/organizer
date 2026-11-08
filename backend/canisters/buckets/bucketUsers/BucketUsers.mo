import Map "mo:core/Map";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Error "mo:core/Error";
import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import List "mo:core/List";
import User "../../../models/User";
import { type User; type PublicUser; type PrivateUser } "../../../models/User";
import Errors "../../../shared/Errors";
import Loc "../../../shared/Loc";
import Canisters "../../../shared/Canisters";
import MixinCommon "../../../shared/mixins/MixinCommon";
import MixinBucketUsersJobs "MixinBucketUsersJobs";
import MixinJobs "../../../shared/mixins/MixinJobs";

shared ({ caller }) actor class BucketUsers() = this {
  let thisPrincipal = Principal.fromActor(this);

  include MixinCommon({
    thisPrincipal = thisPrincipal;
    thisKind = #dynamic(#orderedByHash(#bucketUsers));
  });
  include MixinBucketUsersJobs({
    thisPrincipal = thisPrincipal;
    memKnownCanisters = memKnownCanisters;
    createActorSearchIndexesFor = createActorSearchIndexesFor;
  });
  include MixinJobs<system>({
    useTimer = true;
    timerRetryDelaySeconds = null;
    executeJob = executeJob;
  });
  
  // ===== CONFIGS =====

  let MAX_NUMBER_USERS = 10_000_000;

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
    } or InspectCommon;
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
    if ( memUsers.size() >= MAX_NUMBER_USERS ) return #err(#errMemoryLimitReached);

    if ( memUsers.containsKey(caller) ) return #err(#errValidation([#alreadyExists { field = "caller" }]));

    let user: User = {
      data = { name = ""; email = "" };
      groups = Map.empty<Loc.LocPerId, ()>();
      createdAt = Time.now();
      updatedAt = Time.now();
    };

    let job = #jobBucketUsers(#addPrincipalSearch({ newPrincipal = caller; loc = { id = null; principal = ?caller; bucketHash = thisIndex}; })); 
    switch (executeJob(job)) {
      case (#ok) ();
      case (#err(e)) return #err(e);
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

    #ok
  };

  public shared ({ caller }) func handlerDeleteUser() : async Result<(), Errors.HandlerErr> {
    if ( not memUsers.containsKey(caller) ) return #err(#errNotFound("User not found"));

    memUsers.remove(caller);

    #ok
  };
};