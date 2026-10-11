import Map "mo:core/Map";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Principal "mo:core/Principal";
import { type Result } "mo:core/Result";
import Iter "mo:core/Iter";
import { type HandlerErr } "../Errors";

mixin({knownCanisters: Map.Map<Principal, ()>; limit: Nat}) {
  // ===== TYPES =====

  type InspectMsgIndex = {
    #handlerSearchEntry : () -> (Text);
    #handlerReserveEntry : () -> (text: Text, principal: Principal);
    #handlerConfirmEntry : () -> (text: Text, principal: Principal);
    #handlerDeleteOwner : () -> (principal: Principal);
  };

  // ===== MEMORY =====

  let memSearch = Map.empty<Text, {owner: Principal; reservedAt: Time.Time; confirmed: Bool}>();
  let memSearchByOwner = Map.empty<Principal, Text>();

  // ===== HANDLERS =====

  public query func handlerSearchEntry(text: Text) : async [Principal] {
    memSearch
      .entriesFrom(text)
      .filter(func ((k, v)) { k.startsWith(#text(text)) and v.confirmed })
      .take(limit)
      .map(func ((k, v)) { v.owner })
      .toArray()
  };

  // RESERVATION
  public type ReserveEntryResult = {
    #allowed;
    #alreadyTaken;
    #alreadyBelongs;
    #alreadyReserved;
  };

  public shared ({ caller }) func handlerReserveEntry(text: Text, principal: Principal) : async Result<ReserveEntryResult, HandlerErr> {
    let ?_ = knownCanisters.get(caller) else return #err(#errForbidden);

    let ?entry = memSearch.get(text.toLower()) else {
      memSearch.add(text.toLower(), { owner = principal; reservedAt = Time.now(); confirmed = false });
      return #ok(#allowed);
    };

    if (entry.confirmed) {
      if (entry.owner != principal) {
        return #ok(#alreadyTaken);
      } else {
        return #ok(#alreadyBelongs);
      }
    } else {
      if (entry.reservedAt + 60_000_000_000 < Time.now()) {
        memSearch.add(text.toLower(), { owner = principal; reservedAt = Time.now(); confirmed = false });
      } else {
        return #ok(#alreadyReserved);
      }
    };

    #ok(#allowed)
  };

  // CONFIRMATION

  public shared ({ caller }) func handlerConfirmEntry(text: Text, principal: Principal) : async Result<(), HandlerErr> {
    let ?_ = knownCanisters.get(caller) else return #err(#errForbidden);

    let ?entry = memSearch.get(text.toLower()) else {
      return #err(#errNotFound);
    };

    if (entry.owner != principal) {
      return #err(#errForbidden);
    };

    if (not entry.confirmed and entry.reservedAt + 60_000_000_000 < Time.now()) {
      memSearch.remove(text.toLower());
      return #err(#errBadRequest("Reservation expired"));
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
  public shared ({ caller }) func handlerDeleteOwner(principal: Principal) : async Result<(), HandlerErr> {
    let ?_ = knownCanisters.get(caller) else return #err(#errForbidden);

    let ?name = memSearchByOwner.get(principal) else {
      return #ok(());
    };
    memSearch.remove(name);
    memSearchByOwner.remove(principal);

    #ok
  };
}