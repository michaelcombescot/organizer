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
    timerRetryDelayNs = null;
    executeJob = executeJob;
  });
  
  // ===== CONFIGS =====

  let MAX_NUMBER_USERS = 10_000_000;

  // ===== MEMORY =====

  let memGuards = Map.empty<Principal, User>();
  let memOngoingUpdate = Map.empty<Principal, ()>();

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
    } or InspectCommon or InspectJobs;
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
      let ?user = memGuards.get(p) else return #err(#errNotFound("User not found"));
      users.add(user.toPublic(p));
    };

    #ok(users.toArray());
  };

  public query ({ caller }) func handlerGetCurrentUserData() : async Result<PrivateUser, Errors.HandlerErr> {
      if ( caller.isAnonymous() ) return #err(#errForbidden);

      let ?user = memGuards.get(caller) else return #err(#errNotFound("User not found"));

      #ok(user.toPrivate());
  };

  public shared ({ caller }) func handlerCreateUser() : async Result<(), Errors.HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);
    if ( memGuards.size() >= MAX_NUMBER_USERS ) return #err(#errMemoryLimitReached);

    if ( memGuards.containsKey(caller) ) return #err(#errValidation([#alreadyExists { field = "caller" }]));

    switch (aquireGuard(caller)) {
      case (#ok(())) ();
      case (#err(e)) return #err(e);
    };

    try {
      let job = #jobBucketUsers(#addPrincipalSearch({ newPrincipal = caller; owner = #principal(caller) })); 
      switch (await executeJob(job)) {
        case (#ok(())) ();
        case (#err(e)) {
          memGuards.remove(caller);
          return #err(e);
        };
      };

      let user: User = {
        data = { name = ""; email = "" };
        groups = Map.empty<Loc.LocOwner, ()>();
        createdAt = Time.now();
        updatedAt = Time.now();
      };

      memGuards.add(caller, user);
    } finally {
      memOngoingUpdate.remove(caller);
    };

    #ok
  };

  public shared ({ caller }) func handlerUpdateUser({
    name: Text;
    email: Text
  }) : async Result<(), Errors.HandlerErr> {
    let ?user = memGuards.get(caller) else return #err(#errNotFound("User not found"));

    switch (acquireGuard(caller)) {
      case (#ok(())) ();
      case (#err(e)) return #err(e);
    };

    try {
      let updatedUser = { user with updatedAt = Time.now() };

      // Save indexes

      let jobIndexName = #jobBucketUsers(#addNameSearch({ newName = updatedUser.name; owner = #principal(caller) }));
      let futureName = executeJob(jobIndexName);

      let jobIndexEmail = #jobBucketUsers(#addEmailSearch({ newEmail = updatedUser.email; owner = #principal(caller) }));
      let futureEmail = executeJob(jobIndexEmail);
      
      let errors = List.empty<Errors.ValidationErr>();

      if ( user.name != name ) {
        switch ( await futureName ) {
          case (#ok(())) { updatedUser := { updatedUser with name } };
          case (#err(e)) {
            if ( e != #errIndexAlreadyExists ) return #err(e);
            errors.add(#alreadyExists { field = "name" });
          };
        };
      };

      if ( user.email != email ) {
        switch ( await futureEmail ) {
          case (#ok(())) { updatedUser := { updatedUser with email } };
          case (#err(e)) {
            if ( e != #errIndexAlreadyExists ) return #err(e);
            errors.add(#alreadyExists { field = "email" });
          };
        };
      };

      if ( not errors.isEmpty() ) return #err(#errValidation(errors));

      // save user
      memGuards.add(caller, updatedUser);  
    } finally {
      memOngoingUpdate.remove(caller);
    };

    #ok
  };

  public shared ({ caller }) func handlerDeleteUser() : async Result<(), Errors.HandlerErr> {
    let ?user = memGuards.get(caller) else return #err(#errNotFound("User not found"));

    try {
      switch ( await createAndExecuteJob(#jobBucketUsers(#removePrincipalSearch({ principal = caller;}))) ) {
        case (#ok(())) ();
        case (#err(e)) return #err(e);
      };

      switch ( await createAndExecuteJob(#jobBucketUsers(#removeNameSearch({ name = user.data.name }))) ) {
        case (#ok(())) ();
        case (#err(e)) return #err(e);
      };

      switch ( await createAndExecuteJob(#jobBucketUsers(#removeEmailSearch({ email = user.data.email }))) ) {
        case (#ok(())) ();
        case (#err(e)) return #err(e);
      };

      memGuards.remove(caller);
    } finally {
      releaseGuard(caller);
    };

    #ok
  };


  // ===== HELPERS =====

  func aquireGuard(caller: Principal) : Result<(), Errors.HandlerErr> {
    switch (memGuards.get(caller)) {
      case (?()) #ok;
      case (#none) memGuards.add(caller, ());
    }
  };

  func releaseGuard(caller: Principal) {
    memGuards.remove(caller);
  };
}