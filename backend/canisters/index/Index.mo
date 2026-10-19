import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import MixinUsers "MixinUsers";
import { Kind = {type CanisterKind} } "../../shared/Canisters";

shared ({ caller }) persistent actor class Index(canisters: [(CanisterKind, Principal)], userRing: [Principal]) = this {
  let owner = caller;

  include MixinCanistersMapping(canisters);
  include MixinUsers({ userRing = userRing; findUserBucket = helperFindByPrincipal });

  // ===== SYSTEM =====

  type InspectParams = {
      arg: Blob;
      caller : Principal;
      msg : InspectParamsMsgUsers;
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller.isAnonymous() ) { return false; };

      if ( Blob.size(params.arg) > 5000 ) { return false; };

      switch ( params.msg ) {
          case (#handlerUpdateUserMapping(_)) params.caller.isController();
          case (#handlerAddKnownCanistersByKind(_)) params.caller.isController();
          case (#handlerRemoveKnownCanistersByKind(_)) params.caller.isController();
          case (#handlerGetCurrentUserBucket(_)) true;
      }
  };

  public shared ({ caller }) func updateMapping(kind: CanisterKind) : async [Principal] {
    switch ( memMapping.get(kind) ) {
      case (?map) Map.keys(map);
      case (null) [];
    }
  };
};