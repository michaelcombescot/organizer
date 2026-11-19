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

  let memGuards = Map.empty<Principal, ()>();
  let memUsers = Map.empty<Principal, User>();

  // ===== SYSTEM =====

  system func inspect({ arg : Blob; caller : Principal }) : Bool {
      inspectBasic({arg = arg; caller = caller; maxArgSize = 1000})
  };

  // ===== HANDLERS =====

  public query ({caller}) func handlerGetUsersPublicData(usersPrincipals: [Principal]) : async Result<[PublicUser], Errors.HandlerErr> {
    switch(callerIsIdentified(caller)) { case (#ok) (); case (#err(e)) return #err(e); };
    if ( Array.size(usersPrincipals) > 50 ) return #err(#errBadRequest("Too many principals requested"));

    let users = List.empty<PublicUser>();
    for (p in usersPrincipals.values()) {
      let ?user = memUsers.get(p) else return #err(#errNotFound("User not found"));
      users.add(user.toPublic(p));
    };

    #ok(users.toArray());
  };

  public query ({ caller }) func handlerGetCurrentUserData() : async Result<PrivateUser, Errors.HandlerErr> {
      switch(callerIsIdentified(caller)) { case (#ok) (); case (#err(e)) return #err(e); };

      let ?user = memUsers.get(caller) else return #err(#errNotFound("User not found"));

      #ok(user.toPrivate());
  };

  public shared ({ caller }) func handlerCreateUser() : async Result<(), Errors.HandlerErr> {
    switch(callerIsIdentified(caller)) { case (#ok) (); case (#err(e)) return #err(e); };
    if ( memGuards.size() >= MAX_NUMBER_USERS ) return #err(#errMemoryLimitReached);

    if ( memUsers.containsKey(caller) ) return #err(#errValidation([#alreadyExists { field = "caller" }]));

    switch (acquireGuard(caller)) {
      case (#ok(())) ();
      case (#err(e)) return #err(e);
    };

    try {
      let job = #jobBucketUsers(#updateUserIndex({ kind = #usersByPrincipal ; key = caller.toText(); owner = #principal(caller) })); 
      switch (await executeJob(job)) {
        case (#ok(())) ();
        case (#err(e)) {
          memGuards.remove(caller);
          return #err(e);
        };
      };

      let user: User = {
        name = "";
        email = "";
        groups = Map.empty<Loc.LocOwner, ()>();
        createdAt = Time.now();
        updatedAt = Time.now();
      };

      memUsers.add(caller, user);
    } finally {
      releaseGuard(caller);
    };

    #ok
  };

  public shared ({ caller }) func handlerUpdateUser({
    name: Text;
    email: Text
  }) : async Result<(), Errors.HandlerErr> {
    let ?user = memUsers.get(caller) else return #err(#errNotFound("User not found"));

    switch (acquireGuard(caller)) {
      case (#ok(())) ();
      case (#err(e)) return #err(e);
    };

    try {
      var updatedUser = { user with updatedAt = Time.now() };

      // Save indexes

      let jobIndexName = #jobBucketUsers(#updateUserIndex({ kind = #usersByName ; key = updatedUser.name; owner = #principal(caller) }));
      let futureName = executeJob(jobIndexName);

      let jobIndexEmail = #jobBucketUsers(#updateUserIndex({ kind = #usersByEmail ; key = updatedUser.email; owner = #principal(caller) }));
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

      if ( not errors.isEmpty() ) return #err(#errValidation(errors.toArray()));

      // save user
      memUsers.add(caller, updatedUser);  
    } catch e {
      return #err(#errInterCanisterCall(e.message()));
    } finally {
      releaseGuard(caller);
    };

    #ok
  };

  public shared ({ caller }) func handlerDeleteUser() : async Result<(), Errors.HandlerErr> {
    switch (acquireGuard(caller)) {
      case (#ok(())) ();
      case (#err(e)) return #err(e);
    };

    let ?user = memUsers.get(caller) else return #err(#errNotFound("User not found"));

    try {
      switch ( await createAndExecuteJob(#jobBucketUsers(#removeUserIndex({ kind = #usersByPrincipal; key = caller.toText() }))) ) {
        case (#ok(())) ();
        case (#err(e)) return #err(e);
      };

      switch ( await createAndExecuteJob(#jobBucketUsers(#removeUserIndex({ kind = #usersByName; key = user.name }))) ) {
        case (#ok(())) ();
        case (#err(e)) return #err(e);
      };

      switch ( await createAndExecuteJob(#jobBucketUsers(#removeUserIndex({ kind = #usersByEmail; key = user.email }))) ) {
        case (#ok(())) ();
        case (#err(e)) return #err(e);
      };
    } catch e {
      return #err(#errInterCanisterCall(e.message()));
    } finally {
      releaseGuard(caller);
    };

    #ok
  };


  // ===== HELPERS =====

  func acquireGuard(caller: Principal) : Result<(), Errors.HandlerErr> {
    switch (memGuards.get(caller)) {
      case (?_) {
        memGuards.add(caller, ());
        #ok;
      };
      case (null) #err(#errGuarded);
    }
  };

  func releaseGuard(caller: Principal) {
    memGuards.remove(caller);
  };
}