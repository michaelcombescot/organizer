import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Map "mo:core/Map";
import List "mo:core/List";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Result "mo:core/Result";
import MixinCommon "../../shared/mixins/MixinCommon";
import { type ErrHandler } "../../shared/Errors";
import { ReqKind } "../../shared/Req";
import Loc "../../shared/Loc";
import Errors "../../shared/Errors";

shared ({ caller }) actor class SearchIndexes() = this {
  let thisPrincipal = Principal.fromActor(this);

  include MixinCommon({ thisPrincipal = thisPrincipal; thisKind = #dynamic(#orderedByHash(#searchIndexes)) });

  // ===== MEMORY =====

  let memQuery = Map.empty<ReqKind.ReqKind, Map.Map<Text, Loc.Loc>>();

  // ===== SYSTEM =====

  system func inspect({ arg : Blob; caller : Principal }) : Bool {
    inspectBasic({ arg = arg; caller = caller; maxArgSize = 1000 })
  };

  // ===== HANDLERS =====

  public query ({caller}) func getAllKeys() : async Result<[(ReqKind.ReqKind, [Text])], ErrHandler> {
    switch ( canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    #ok(memQuery.entries().map(func ((kind, map)) = (kind, map.keys().toArray())).toArray())
  };

  public query func handlerPublicSearch({
    requests: {text: Text; kinds: [ReqKind.ReqKind]}; 
    limit: Nat
  }) : async Result.Result<[Loc.Loc], Errors.ErrHandler> {
    if (requests.kinds.size() > 10) { return #err(#errBadRequest("Request size exceeds limit")) };
    if ( limit > 20) { return #err(#errBadRequest("Limit exceeds maximum allowed value")) };

    let resp = List.empty<Loc.Loc>();

    for (kind in requests.kinds.values()) {
      let r = normalizeText(requests.text);
      let ?map = memQuery.get(kind) else { continue };

      map
        .entriesFrom(r)
        .filter(func ((key, _)) = key.startsWith(#text r))
        .map(func ((_, d)) = d )
        .take(limit)
        .forEach(func (loc) = resp.add(loc));
    };

    #ok(resp.toArray())
  };

  public shared ({ caller }) func handlerSaveEntry({ kind: ReqKind.ReqKind; owner: Loc.LocOwner; key: Text }) : async Result<(), Errors.ErrHandler> {
    if (key == "") return #err(#errBadRequest("Key cannot be empty"));
    
    switch ( canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    let map = switch ( memQuery.get(kind) ) {
      case (?m) m;
      case (null) {
        let newMap = Map.empty<Text, Loc.Loc>();
        memQuery.add(kind, newMap);
        newMap
      }
    };
      
    let normalizedKey = normalizeText(key);

    if ( map.containsKey(normalizedKey) ) return #err(#errIndexAlreadyExists);

    let ?callerIndex = memKnownCanisters.get(caller) else return #err(#errNotFound("Caller is not a known canister"));

    map.add(normalizedKey, { bucket = callerIndex; owner = owner });

    #ok(());
  };

  public shared ({ caller }) func handlerLiberateEntry({ kind: ReqKind.ReqKind; key: Text }) : async Result<(), Errors.ErrHandler> {
    switch ( canAccess(caller) ) { case(#ok) (); case(#err(e)) return #err(e); };

    let ?map = memQuery.get(kind) else { return #ok };
    map.remove(normalizeText(key));

    #ok
  };

  // ===== HELPERS =====

  func normalizeText(text: Text) : Text {
    text.toLower().trim(#char ' ')
  };
}