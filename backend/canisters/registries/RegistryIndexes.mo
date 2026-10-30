import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import Errors "../../shared/Errors";
import Result "mo:core/Result";
import Canisters "../../shared/Canisters";

shared ({ caller }) actor class RegistryIndexes() = this {
  include MixinCanistersMapping({ self = Principal.fromActor(this); selfKind = #static(#registryIndexes); mapping = { version = 0; canisters = [] } : Canisters.Mapping });

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #systemAddStaticCanisters : () -> (canisters: [(Canisters.StaticKind, Principal)]);
      #handlerGetMainIndexes : () -> ();
    } or InspectMapping;
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;
    if ( params.arg.size() > 50 ) return false;

    true
  };

  public shared ({ caller }) func systemAddStaticCanisters(canisters: [(Canisters.StaticKind, Principal)]) : async Result.Result<(), Errors.HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errForbidden);

    addStaticCanisters(canisters);
    #ok
  };

  // ===== HANDLERS =====

  public query ({ caller}) func handlerGetMainIndexes() : async [Principal] {
    if ( caller.isAnonymous() ) return [];

    let ?map = memMapping.get(#dynamic(#orderedByTime(#indexMain))) else return [];

    map.values().toArray()
  };
};