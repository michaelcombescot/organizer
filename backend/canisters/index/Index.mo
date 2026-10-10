import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import MixinCanistersByKind "../../shared/mixins/MixinCanistersByKind";
import MixinUsersMapping "../../shared/mixins/MixinUsersMapping";
import MixinUsers "MixinUsers";
import { Kind = {type CanisterKind} } "../../shared/Canisters";

shared ({ caller = owner }) persistent actor class Index(canisters: [(CanisterKind, Principal)], userRing: [Principal]) = this {
  include MixinCanistersByKind(canisters);
  include MixinUsersMapping(userRing);
  include MixinUsers({ userRing = userRing; findUserBucket = helperFindUserBucket });

  // ===== SYSTEM =====

  type InspectParams = {
      arg: Blob;
      caller : Principal;
      msg : InspectParamsMsgUsers or InspectParamsMsgUserMapping or InspectParamsMsgKnownCanistersByKind;
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
};