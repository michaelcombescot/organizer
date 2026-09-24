import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Errors "../../shared/Errors";
import Canisters "../../shared/Canisters";

mixin () {
    // ===== MEMORY =====

    let memKnownCanisters = Map.empty<Canisters.CanisterKind, Map.Map<Principal, ()>>();

    // ===== HANDLERS =====

    public shared ({ caller }) func addKnownCanisters(principals: [Principal], kind: Canisters.CanisterKind) : async Result.Result<(), Errors.HandlerErr> {
      if ( not caller.isController() ) { return #err(#errMustBeController); };

      let map = switch (memKnownCanisters.get(Canisters.compareCanisterKind, kind)) {
        case (?m) m;
        case null {
          let innerMap = Map.empty<Principal, ()>();
          memKnownCanisters.add(Canisters.compareCanisterKind, kind, innerMap);
          innerMap;
        };
      };

      principals.forEach(func(principal) = map.add(principal, ()));

      #ok(());
    };

    public shared ({ caller }) func removeKnownCanisters(principals: [Principal], kind: Canisters.CanisterKind) : async Result.Result<(), Errors.HandlerErr> {
      if ( not caller.isController() ) { return #err(#errMustBeController); };

      switch (memKnownCanisters.get(Canisters.compareCanisterKind, kind)) {
        case (?m) {
          principals.forEach(func(principal) = m.remove(principal));
        };
        case null {};
      };

      #ok(());
    };

    // ===== HELPERS =====

    func isKnownCanister(principal: Principal, kind: Canisters.CanisterKind) : async Bool {
        switch (memKnownCanisters.get(Canisters.compareCanisterKind, kind)) {
          case (?m) m.containsKey(principal);
          case null false;
        };
    };
}