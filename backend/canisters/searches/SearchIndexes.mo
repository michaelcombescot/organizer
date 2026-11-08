import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Map "mo:core/Map";
import List "mo:core/List";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Result "mo:core/Result";
import MixinCommon "../../shared/mixins/MixinCommon";
import { type HandlerErr } "../../shared/Errors";
import { ReqKind } "../../shared/Req";
import Loc "../../shared/Loc";
import Errors "../../shared/Errors";

shared ({ caller }) actor class SearchIndexes() = this {
  let thisPrincipal = Principal.fromActor(this);

  include MixinCommon({ thisPrincipal = thisPrincipal; thisKind = #dynamic(#orderedByHash(#searchIndexes)) });

  // ===== MEMORY =====

  let memQuery = Map.empty<ReqKind.ReqKind, Map.Map<Text, Loc.Loc>>();

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerPublicSearch : () -> { requests: {text: Text; kinds: [ReqKind.ReqKind]}; limit: Nat };
      #handlerSaveEntry : () -> {kind: ReqKind.ReqKind; loc: Loc.Loc; key: Text};
      #handlerLiberateEntry : () -> { kind: ReqKind.ReqKind; key: Text };
    } or InspectCommon;
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;
    if ( params.arg.size() > 5000 ) return false;

    true
  };

  // ===== HANDLERS =====

  public query func handlerPublicSearch({
    requests: {text: Text; kinds: [ReqKind.ReqKind]}; 
    limit: Nat
  }) : async Result.Result<[Loc.Loc], Errors.HandlerErr> {
    if (requests.kinds.size() > 10) { return #err(#errBadRequest("Request size exceeds limit")) };
    if ( limit > 20) { return #err(#errBadRequest("Limit exceeds maximum allowed value")) };

    let resp = List.empty<Loc.Loc>();

    for (kind in requests.kinds.values()) {
      let r = requests.text;
      let ?map = memQuery.get(kind) else { continue };

      map
        .entriesFrom(r)
        .map(func ((_, d)) = d )
        .take(limit)
        .forEach(func (loc) = resp.add(loc));
    };

    #ok(resp.toArray())
  };

  public shared ({ caller }) func handlerSaveEntry({ kind: ReqKind.ReqKind; loc: Loc.Loc; key: Text; }) : async Result<(), Errors.HandlerErr> {
    switch ( await canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    let map = switch ( memQuery.get(kind) ) {
      case (?m) m;
      case (null) {
        let newMap = Map.empty<Text, Loc.Loc>();
        memQuery.add(kind, newMap);
        newMap
      }
    };
    
    if ( map.containsKey(key) ) return #err(#errIndexAlreadyExists);

    map.add(key, loc);
    
    #ok
  };

  public shared ({ caller }) func handlerLiberateEntry({ kind: ReqKind.ReqKind; key: Text }) : async Result<(), Errors.HandlerErr> {
    switch ( await canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    let ?map = memQuery.get(kind) else return #ok;    
    map.remove(key);

    #ok
  };
}