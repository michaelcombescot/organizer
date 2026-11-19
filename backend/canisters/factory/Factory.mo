import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Map "mo:core/Map";
import Canisters "../../shared/Canisters";
import MixinCommon "../../shared/mixins/MixinCommon";
import MixinJobs "../../shared/mixins/MixinJobs";
import MixinFactoryJobs "MixinFactoryJobs";
import MixinTopUpCycles "MixinTopUpCycles";
import MixinNewCanisters "MixinNewCanisters";

shared ({ caller = owner }) actor class Factory() = this {
  let thisPrincipal = Principal.fromActor(this);

  include MixinCommon({
    thisPrincipal = thisPrincipal;
    thisKind = #static(#factory);
  });
  
  switch ( memMapping.get(#static(#factory)) ) { // init the mapping with itself as the first known canister
    case null {
      let map = Map.singleton<Nat, Principal>(0, thisPrincipal);
      memMapping.add(#static(#factory), map);

      memKnownCanisters.add(thisPrincipal, 0);
    };
    case (?_) ();
  };

  include MixinFactoryJobs({ mappingToPublic = mappingToPublic });

  include MixinJobs<system>({
    useTimer = true;
    timerRetryDelayNs = null;
    executeJob = executeJob;
  });

  include MixinTopUpCycles<system>({
    memMapping = memMapping;
  });

  include MixinNewCanisters<system>({
    thisPrincipal = thisPrincipal;
    owner = owner;
    memVersion = memVersion;
    memMapping = memMapping;
    memKnownCanisters = memKnownCanisters;
    canAccess = canAccess;
    createAndExecuteJob = createAndExecuteJob;
  });

  // ===== SYSTEM =====

  system func inspect({ arg : Blob; caller : Principal }) : Bool {
    inspectBasic({arg = arg; caller = caller; maxArgSize = 1000})
  };
};