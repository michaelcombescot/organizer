import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import MixinTopUpCycles "MixinTopUpCycles";
import MixinNewCanisters "MixinNewCanisters";

shared ({ caller = owner }) actor class Factory() = this {
  let thisPrincipal = Principal.fromActor(this);

  include MixinCanistersMapping({ self = thisPrincipal; selfKind = #static(#factory); mapping = ?{ version = 0; canisters = [(#static(#factory), [(0, thisPrincipal)])] } });
  include MixinNewCanisters<system>({
    thisPrincipal = thisPrincipal;
    owner = owner;
    memVersion = memVersion;
    memMapping = memMapping;
    memKnownCanisters = memKnownCanisters;
    knownCanistersToMapping = knownCanistersToMapping;
    isKnownBasic = isKnownBasic;
  });
  include MixinTopUpCycles<system>(memMapping);   

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : InspectMapping or InspectCreateCanisters;
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous()) return false;

    return true
  };
};