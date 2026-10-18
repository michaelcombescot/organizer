import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Map "mo:core/Map";
import Time "mo:core/Time";
import List "mo:core/List";
import Iter "mo:core/Iter";
import Result "mo:core/Result";
import MixinKnownCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import { type HandlerErr } "../../shared/Errors";
import { Kind = { type CanisterKind } } "../../shared/Canisters";
import { ReqKind; ReqBy; ReqReservation } "../../models/Req";
import Errors "../../shared/Errors";
import { type Identifier } "../../shared/Identifiers";

shared ({ caller }) actor class SearchUsersByEmail(mapping: [(CanisterKind, [(Nat, Principal)])]) = this {
  let thisPrincipal = Principal.fromActor(this);
  let owner = caller;

  include MixinKnownCanistersMapping(thisPrincipal, owner, mapping);

  // ===== TYPE =====

  public type SearchEntryData = {
    owner: Identifier;
    reservedAt: Time.Time;
    confirmed: Bool;
  };

  // ===== MEMORY =====

  let memSearch = Map.empty<ReqKind.ReqKind, Map.Map<ReqBy.ReqBy, SearchEntryData>>();

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerSearchEntry : () -> (Text);
      #handlerReserveEntry : () -> (text: Text, principal: Principal);
      #handlerConfirmEntry : () -> (text: Text, principal: Principal);
      #handlerLiberateEntry : () -> (kind: ReqKind.ReqKind, by: ReqBy.ReqBy);
    };
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;
    if ( params.arg.size() > 5000 ) return false;

    isKnown(params.caller)
  };

  // ===== HANDLERS =====

  public query func handlerPublicSearch(request: [(ReqKind.ReqKind, ReqBy.ReqBy)], limit: Nat) : async Result.Result<[Identifier], Errors.HandlerErr> {
    if (request.size() > 10) { return #err(#errBadRequest("Request size exceeds limit")) };
    if ( limit > 20) { return #err(#errBadRequest("Limit exceeds maximum allowed value")) };

    let resp = List.empty<Identifier>();

    for ((kind, r) in request.values()) {
      let ?map = memSearch.get(kind) else { continue };

      map
        .entriesFrom(r)
        .filter(func ((by, d)) { d.confirmed })
        .map(func ((by, d)) { d.loc })
        .take(limit)
        .forEach(func (d) { resp.add(d) });
    };

    #ok(resp.toArray())
  };

  // RESERVATION

  public shared ({ caller }) func handlerReserveEntry(owner: Identifier, kind: ReqKind.ReqKind, by: ReqBy.ReqBy) : async Result<ReqReservation.ReserveEntryResult, Errors.HandlerErr> {
    if ( not isKnown(caller) ) return #err(#errForbidden);

    let map = switch (memSearch.get(kind) ) {
      case (?m) m;
      case null {
        let m = Map.singleton<ReqBy.ReqBy, SearchEntryData>(by, { owner = owner; reservedAt = Time.now(); confirmed = false });
        memSearch.add(kind, m);
        m
      };
    };

    let ?entry = map.get(by) else {
      map.add(by, { owner = owner; reservedAt = Time.now(); confirmed = false });
      return #ok(#reserved);
    };

    if (entry.confirmed) {
      if (entry.owner == owner) {
        return #ok(#alreadyBelongs);
      } else {
        return #ok(#alreadyTaken);
      }
    } else {
      if (entry.reservedAt + 60_000_000_000 < Time.now()) {
        map.add(by, { owner = owner; reservedAt = Time.now(); confirmed = false });
      } else {
        return #ok(#alreadyReserved);
      }
    };

    #ok(#reserved)
  };

  // CONFIRMATION

  public shared ({ caller }) func handlerConfirmEntry(text: Text, principal: Principal) : async Result<(), Errors.HandlerErr> {
    if ( not isKnown(caller) ) return #err(#errForbidden);

    let ?entry = memSearch.get(text.toLower()) else {
      return #err(#errNotFound);
    };

    if (entry.owner != principal) {
      return #err(#errForbidden);
    };

    if (not entry.confirmed and entry.reservedAt + 60_000_000_000 < Time.now()) {
      memSearch.remove(text.toLower());
      return #err(#errBadRequest(Errors.RESERVATION_EXPIRED));
    };

    switch (memSearchByOwner.get(principal)) {
      case (?previousEntry) {
        if (previousEntry != text.toLower()) {
          memSearch.remove(previousEntry);
        };
      };
      case null ();
    };

    memSearch.add(text.toLower(), { entry with confirmed = true });
    memSearchByOwner.add(principal, text.toLower());

    #ok
  };

  // DELETE
  public shared ({ caller }) func handlerLiberateEntry(owner: Identifier, kind: ReqKind.ReqKind, by: ReqBy.ReqBy) : async Result<(), Errors.HandlerErr> {
    if ( not isKnown(caller) ) return #err(#errForbidden);

    let ?map = memSearch.get(kind) else {
      return #ok(());
    };
    if (map.get(by)?.owner == owner) {
      memSearch.remove(kind);
      memSearchByOwner.remove(entry.owner);
    };

    #ok
  };
}