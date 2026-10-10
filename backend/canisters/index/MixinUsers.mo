import { type Result } "mo:core/Result";
import Principal "mo:core/Principal";
import Errors "../../shared/Errors";

mixin(params: {userRing: [Principal]; findUserBucket: ( [Principal], Principal) -> Principal}) {
  // ===== TYPES =====

  type InspectParamsMsgUsers = {
    #handlerGetCurrentUserBucket : () -> ();
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetCurrentUserBucket() : async Result<Principal, Errors.HandlerErr> {
    #ok(params.findUserBucket(params.userRing, caller))
  };
}