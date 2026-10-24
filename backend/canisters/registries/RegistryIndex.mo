import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import { CanisterKind; IndexKind } "../../shared/Canisters";

shared ({ caller }) actor class RegistryIndex() = this {
  include MixinCanistersMapping({ self = Principal.fromActor(this); selfKind = #static(#registryIndexes); canisters = [] });

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerGetIndexes : () -> (kind: IndexKind.IndexKind);
    } or InspectMappingMsg
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;
    if ( params.arg.size() > 50 ) return false;

    true
  };

  // ===== HANDLERS =====

  public query ({ caller}) func handlerGetIndexes(kind: IndexKind.IndexKind) : async [Principal] {
    if ( caller.isAnonymous() ) return [];

    let ?map = memMapping.get(#indexes(kind)) else return [];

    map.values().toArray()
  };
};