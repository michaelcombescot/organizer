import MixinCommon "../../shared/mixins/MixinCommon";
import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import Canisters "../../shared/Canisters";

shared ({ caller }) actor class RegistryIndexes() = this {
  include MixinCommon({ thisPrincipal = Principal.fromActor(this); thisKind = #static(#registryIndexes) });

  // ===== SYSTEM =====

  system func inspect({ arg : Blob; caller : Principal }) : Bool {
    inspectBasic({arg = arg; caller = caller; maxArgSize = 100})
  };

  // ===== HANDLERS =====

  public query ({ caller}) func handlerGetMainIndexes() : async [Principal] {
    if ( caller.isAnonymous() ) return [];

    let ?map = memMapping.get(#dynamic(#orderedByTime(#indexMain))) else return [];

    map.values().toArray()
  };
};