import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import MixinCommon "../../shared/mixins/MixinCommon";
import MixinTopUpCycles "MixinTopUpCycles";
import MixinNewCanisters "MixinNewCanisters";

shared ({ caller = owner }) actor class Factory() = this {
  let thisPrincipal = Principal.fromActor(this);

  include MixinCommon({
    thisPrincipal = thisPrincipal;
    thisKind = #static(#factory);
  });
  include MixinNewCanisters<system>({
    thisPrincipal = thisPrincipal;
    owner = owner;
    memVersion = memVersion;
    memMapping = memMapping;
    memKnownCanisters = memKnownCanisters;
    knownCanistersToMapping = knownCanistersToMapping;
    canAccess = canAccess;
  });
  include MixinTopUpCycles<system>(memMapping);   

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : InspectCommon or InspectCreateCanisters;
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous()) return false;

    return true
  };
};