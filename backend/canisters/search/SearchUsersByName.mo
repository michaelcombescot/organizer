import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import MixinKnownCanistersByPrincipal "../../shared/mixins/MixinCanistersByPrincipal";
import MixinIndexTextToPrincipal "../../shared/mixins/MixinIndexTextToPrincipal";
import { type HandlerErr } "../../shared/Errors";

shared ({ caller = owner }) actor class SearchUsersByName(canisters: [Principal]) = this {
  include MixinKnownCanistersByPrincipal(canisters);
  include MixinIndexTextToPrincipal({knownCanisters = memKnownCanistersByPrincipal; limit = 20});    

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : InspectParamsMsgKnownCanistersByPrincipal or InspectMsgIndex;
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;
    if ( params.arg.size() > 5000 ) return false;

    isControllerOrKnownCanister(params.caller)
  };
}