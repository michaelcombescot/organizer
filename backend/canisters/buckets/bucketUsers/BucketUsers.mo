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
import MixinCanistersMapping "../../../shared/mixins/MixinCanistersMapping";
import { type Job } "../../../models/Job";

shared ({ caller }) actor class BucketUsers(mapping: [(CanisterKind, [(Nat, Principal)])]) = this {
  let thisPrincipal = Principal.fromActor(this);
  let owner = caller;

  include MixinCanistersMapping(thisPrincipal, owner, mapping);
  
  // ===== MEMORY =====

  let memUsers = Map.empty<Principal, User>();

  // // ===== SYSTEM =====

  // type InspectParams = {
  //     arg: Blob;
  //     caller : Principal;
  //     msg : {
  //     #handlerCreateUser : () -> ({userPrincipal: Principal; name: Text; email: Text});
  //     #handlerUpdateUser : () -> ({userPrincipal: Principal; name: Text; email: Text});
  //     #handlerGetUserData : () -> ();
  //     #handlerDeleteUser : () -> ({userPrincipal : Principal});
  //   } or InspectParamsMsgKnownCanistersByPrincipal
  // };

  // system func inspect(params: InspectParams) : Bool {
  //     if ( params.caller == Principal.anonymous() ) { return false; };

  //     if ( Blob.size(params.arg) > 300 ) { return false; };

  //     isControllerOrKnownCanister(params.caller)
  // };

  // // ===== HANDLERS =====

  // public query ({ caller }) func handlerGetUserData() : async Result<PublicUser, Errors.HandlerErr> {
  //     let ?user = memUsers.get(caller) else return #err(#errNotFound);

  //     #ok(user.toPublic());
  // };

  // public shared ({ caller }) func handlerCreateUser({ 
  //   userPrincipal: Principal;
  //   name: Text;
  //   email: Text 
  // }) : async Result<(), Errors.HandlerErr> {
  //   if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

  //   if ( memUsers.containsKey(userPrincipal) ) return #err(#errValidation([{ field = "userPrincipal"; message = "User already exists" }]));

  //   let user: User = {
  //     data = {
  //       name = name;
  //       email = email;
  //     };
  //     groups = Map.empty<Identifiers.Identifier, ()>();
  //     createdAt = Time.now();
  //     updatedAt = Time.now();
  //   };

  //   memUsers.add(userPrincipal, user);

  //   #ok();
  // };

  // public shared ({ caller }) func handlerUpdateUser({
  //   userPrincipal: Principal;
  //   name: Text;
  //   email: Text 
  // }) : async Result<(), Errors.HandlerErr> {
  //   if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

  //   let ?user = memUsers.get(userPrincipal) else return #err(#errNotFound);

  //   let updatedData = { user.data with name = name; email = email };
  //   let updatedUser = { user with data = updatedData; updatedAt = Time.now() };

  //   memUsers.add(userPrincipal, updatedUser);

  //   #ok();
  // };

  // public shared ({ caller }) func handlerDeleteUser({userPrincipal: Principal}) : async Result<(), Errors.HandlerErr> {
  //   if ( not isControllerOrKnownCanister(caller) ) return #err(#errForbidden);

  //   memUsers.remove(userPrincipal);

  //   #ok
  // };
};