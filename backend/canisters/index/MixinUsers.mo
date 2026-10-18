import { type Result } "mo:core/Result";
import Principal "mo:core/Principal";
import Error "mo:core/Error";
import BucketUsers "../buckets/bucketUsers/BucketUsers";
import Errors "../../shared/Errors";

mixin({userRing: [Principal]; findUserBucket: ( [Principal], Principal) -> Principal}) {
  // // ===== TYPES =====

  // type ActorSearchUsersByName = SearchUsersByName.SearchUsersByName;
  // type ActorSearchUsersByEmail = SearchUsersByEmail.SearchUsersByEmail;
  // type ActorBucketUsers = BucketUsers.BucketUsers;

  // type JobsUsers = {
  //   #confirmIndex: {}
  // };

  // type InspectParamsMsgUsers = {
  //   #handlerGetCurrentUserBucket : () -> ();
  // };

  // // ===== HANDLERS =====

  // public query ({ caller }) func handlerGetCurrentUserBucket() : async Result<Principal, Errors.HandlerErr> {
  //   #ok(findUserBucket(userRing, caller))
  // };

  // public composite query ({ caller }) func handlerSearchUsersByName(name: Text) : async Result<[Principal], Errors.HandlerErr> {
  //   if (name.size() < 3) return #err(#errBadRequest("Name must be at least 3 characters long"));

  //   let userBucket = findUserBucket(userRing, caller);

  //   try {
  //     let principals = await (actor(userBucket.toText()) : ActorSearchUsersByName).handlerSearchEntry(name);
  //     #ok(principals);
  //   } catch e {
  //     return #err(#errInterCanisterCall(e.message()));
  //   };
  // };

  // public composite query ({ caller }) func handlerSearchUsersByEmail(email: Text) : async Result<[Principal], Errors.HandlerErr> {
  //   if (email.size() < 3) return #err(#errBadRequest("Email must be at least 3 characters long"));

  //   let userBucket = findUserBucket(userRing, caller);

  //   try {
  //     let principals = await (actor(userBucket.toText()) : ActorSearchUsersByEmail).handlerSearchEntry(email);
  //     #ok(principals);
  //   } catch e {
  //     return #err(#errInterCanisterCall(e.message()));
  //   };
  // };

  // public shared ({ caller }) func handlerCreateUser() : async Result<Principal, Errors.HandlerErr> {
  //   if (caller.isAnonymous()) return #err(#errMustNotBeAnonymous);

  //   let userBucket = findUserBucket(userRing, caller);

  //   try {
  //     switch (await (actor(userBucket.toText()) : ActorBucketUsers).handlerCreateUser({ userPrincipal = caller; name = ""; email = "" })) {
  //       case (#ok(_)) ();
  //       case (#err(e)) { return #err(e); };
  //     };
  //   } catch e {
  //     return #err(#errInterCanisterCall(e.message()));
  //   };

  //   #ok(userBucket)
  // };

  // public shared ({ caller }) func handlerUpdateUser(name: Text, email: Text) : async Result<(), Errors.HandlerErr> {
  //   if (caller.isAnonymous()) return #err(#errMustNotBeAnonymous);

  //   let userBucket = findUserBucket(userRing, caller);

  //   // Check if name and email are available, reserve them
  //   let emailAvailability = (actor(userBucket.toText()) : ActorSearchUsersByEmail).handlerReserveEntry(email, caller);
  //   let nameAvailability = (actor(userBucket.toText()) : ActorSearchUsersByName).handlerReserveEntry(name, caller);

  //   let emailResult = try { await emailAvailability } catch (e) {return #err(#errInterCanisterCall(e.message())); };
  //   let nameResult = try { await nameAvailability } catch (e) { return #err(#errInterCanisterCall(e.message())); };

  //   switch (emailResult) {
  //     case (#ok(r)) {
  //       switch (r) {
  //         case (#allowed) ();
  //         case (_) { return #err(#errValidation([{ field = "email"; message = Errors.ALREADY_TAKEN }])); };
  //       };
  //     };
  //     case (#err(e)) { return #err(e); };
  //   };

  //   switch (nameResult) {
  //     case (#ok(r)) {
  //       switch (r) {
  //         case (#allowed) ();
  //         case (_) { return #err(#errValidation([{ field = "name"; message = Errors.ALREADY_TAKEN }])); };
  //       };
  //     };
  //     case (#err(e)) { return #err(e); };
  //   };

  //   // Update the user
  //   let userRes = try { 
  //       await (actor(userBucket.toText()) : ActorBucketUsers).handlerUpdateUser({ userPrincipal = caller; name = name; email = email }) 
  //     } catch (e) { return #err(#errInterCanisterCall(e.message())); };

  //   switch (userRes) {
  //     case (#ok(_)) ();
  //     case (#err(e)) return #err(e);
  //   };

  //   // confirm indexes
  //   let confirmEmail = (actor(userBucket.toText()) : ActorSearchUsersByEmail).handlerConfirmEntry(email, caller);
  //   let confirmName = (actor(userBucket.toText()) : ActorSearchUsersByName).handlerConfirmEntry(name, caller);

  //   let confirmEmailResult = try { await confirmEmail } catch (e) {return #err(#errInterCanisterCall(e.message())); };
  //   let confirmNameResult = try { await confirmName } catch (e) { return #err(#errInterCanisterCall(e.message())); };

  //   switch (confirmEmailResult) {
  //     case (#ok(_)) ();
  //     case (#err(e)) {
        
  //       return #err(e);
  //     };
  //   };

  //   switch (confirmNameResult) {
  //     case (#ok(_)) ();
  //     case (#err(e)) {
  //       return #err(e);
  //     };
  //   };

  //   #ok
  // };

  // public shared ({ caller }) func handlerDeleteUser() : async Result<Principal, Errors.HandlerErr> {
  //   if (caller.isAnonymous()) return #err(#errMustNotBeAnonymous);

  //   let userBucket = findUserBucket(userRing, caller);

  //   try {
  //     switch (await (actor(userBucket.toText()) : BucketUsers.BucketUsers).handlerDeleteUser({ userPrincipal = caller })) {
  //       case (#ok(_)) ();
  //       case (#err(e)) { return #err(e); };
  //     };
  //   } catch e {
  //     return #err(#errInterCanisterCall(e.message()));
  //   };

  //   #ok(userBucket)
  // };

  // ===== JOBS =====


}