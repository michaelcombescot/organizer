import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import MixinKnownCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import MixinIndexTextToPrincipal "../../shared/mixins/MixinIndexTextToPrincipal";
import { type HandlerErr } "../../shared/Errors";
import { Kind = { type CanisterKind } } "../../shared/Canisters";

shared ({ caller }) actor class SearchUsersByEmail(mapping: [(CanisterKind, [Principal])]) = this {
  let owner = caller;

  include MixinKnownCanistersMapping(owner, mapping);
  include MixinIndexTextToPrincipal({knownCanisters = memKnownCanisters; limit = 20});

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : InspectParamsMsgKnownCanistersMapping or InspectMsgIndex;
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;
    if ( params.arg.size() > 5000 ) return false;

    isKnown(params.caller)
  };
}