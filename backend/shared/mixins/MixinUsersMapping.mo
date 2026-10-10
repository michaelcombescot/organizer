import Principal "mo:core/Principal";
import Nat32 "mo:core/Nat32";
import { type Result } "mo:core/Result";
import { type HandlerErr} "../Errors";

mixin (usersMapping: [Principal]) {
  // ===== TYPES =====

  type InspectParamsMsgUserMapping = {
    #handlerUpdateUserMapping : () -> (mapping : [Principal]);
  };

  // ===== MEMORY =====

  var memUsersRing = usersMapping;

  // ===== HELPERS =====

  func helperFindUserBucket(array: [Principal], userPrincipal: Principal) : Principal {
      let userPrincipalHash = Principal.hash(userPrincipal);
      array[ Nat32.toNat(userPrincipalHash) % array.size()]
  };

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerUpdateUserMapping(mapping: [Principal]) : async Result<(), HandlerErr> {
      memUsersRing := mapping;
      #ok
  };
}