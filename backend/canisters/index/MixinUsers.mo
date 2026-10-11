import { type Result } "mo:core/Result";
import Principal "mo:core/Principal";
import Error "mo:core/Error";
import BucketUsers "../buckets/bucketUsers/BucketUsers";
import { type HandlerErr } "../../shared/Errors";
import SearchUsersByName "../search/SearchUsersByName";
import SearchUsersByEmail "../search/SearchUsersByEmail";

mixin({userRing: [Principal]; findUserBucket: ( [Principal], Principal) -> Principal}) {
  // ===== TYPES =====

  type ActorSearchUsersByName = SearchUsersByName.SearchUsersByName;
  type ActorSearchUsersByEmail = SearchUsersByEmail.SearchUsersByEmail;

  type InspectParamsMsgUsers = {
    #handlerGetCurrentUserBucket : () -> ();
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetCurrentUserBucket() : async Result<Principal, HandlerErr> {
    #ok(findUserBucket(userRing, caller))
  };

  public composite query ({ caller }) func handlerSearchUsersByName(name: Text) : async Result<[Principal], HandlerErr> {
    let userBucket = findUserBucket(userRing, caller);

    try {
      let principals = await (actor(userBucket.toText()) : ActorSearchUsersByName).handlerSearchEntry(name);
      #ok(principals);
    } catch e {
      return #err(#errInterCanisterCall(e.message()));
    };
  };

  public composite query ({ caller }) func handlerSearchUsersByEmail(email: Text) : async Result<[Principal], HandlerErr> {
    let userBucket = findUserBucket(userRing, caller);

    try {
      let principals = await (actor(userBucket.toText()) : ActorSearchUsersByEmail).handlerSearchEntry(email);
      #ok(principals);
    } catch e {
      return #err(#errInterCanisterCall(e.message()));
    };
  };

  public shared ({ caller }) func handlerCreateUser() : async Result<Principal, HandlerErr> {
    let userBucket = findUserBucket(userRing, caller);

    try {
      switch (await (actor(userBucket.toText()) : BucketUsers.BucketUsers).handlerCreateUser({ userPrincipal = caller; name = ""; email = "" })) {
        case (#ok(_)) ();
        case (#err(e)) { return #err(e); };
      };
    } catch e {
      return #err(#errInterCanisterCall(e.message()));
    };

    #ok(userBucket)
  };
}