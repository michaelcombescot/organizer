import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Map "mo:core/Map";
import List "mo:core/List";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Result "mo:core/Result";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import { type HandlerErr } "../../shared/Errors";
import { CanisterKind = { type CanisterKind } } "../../shared/Canisters";
import { ReqKind } "../../models/Req";
import Loc "../../shared/Loc";
import Errors "../../shared/Errors";

shared ({ caller }) actor class QueriesIndex(mapping: [(CanisterKind, [(Nat, Principal)])]) = this {
  let thisPrincipal = Principal.fromActor(this);

  include MixinCanistersMapping({ self = thisPrincipal; selfKind = #queries(#queriesIndex); canisters = mapping });

  // ===== MEMORY =====

  let memQuery = Map.empty<ReqKind.ReqKind, Map.Map<Text, Loc.Loc>>();

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerPublicSearch : () -> { requests: [(ReqKind.ReqKind, Text)]; limit: Nat };
      #handlerSaveEntry : () -> {kind: ReqKind.ReqKind; loc: Loc.Loc; key: Text};
      #handlerLiberateEntry : () -> { kind: ReqKind.ReqKind; key: Text };
    } or InspectMappingMsg
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;
    if ( params.arg.size() > 5000 ) return false;

    isKnown(params.caller)
  };

  // ===== HANDLERS =====

  public query func handlerPublicSearch({
    requests: [(ReqKind.ReqKind, Text)]; 
    limit: Nat
  }) : async Result.Result<[Loc.Loc], Errors.HandlerErr> {
    if (requests.size() > 10) { return #err(#errBadRequest("Request size exceeds limit")) };
    if ( limit > 20) { return #err(#errBadRequest("Limit exceeds maximum allowed value")) };

    let resp = List.empty<Loc.Loc>();

    for ((kind, r) in requests.values()) {
      let ?map = memQuery.get(kind) else { continue };

      map
        .entriesFrom(r)
        .map(func ((by, d)) { d })
        .take(limit)
        .forEach(func (d) { resp.add(d) });
    };

    #ok(resp.toArray() : [Loc.Loc])
  };

  public shared ({ caller }) func handlerSaveEntry({ kind: ReqKind.ReqKind; loc: Loc.Loc; key: Text }) : async Result<(), Errors.HandlerErr> {
    if ( not isKnown(caller) ) return #err(#errForbidden);

    let ?map = memQuery.get(kind) else { return #err(#errNotFound) };
    
    if ( map.containsKey(key) ) return #err(#errIndexAlreadyExists);

    map.add(key, loc);
    
    #ok
  };

  public shared ({ caller }) func handlerLiberateEntry({ kind: ReqKind.ReqKind; key: Text }) : async Result<(), Errors.HandlerErr> {
    if ( not isKnown(caller) ) return #err(#errForbidden);

    let ?map = memQuery.get(kind) else return #ok;    
    map.remove(key);

    #ok
  };
}