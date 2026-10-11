import Principal "mo:core/Principal";
import Nat32 "mo:core/Nat32";
import { type Result } "mo:core/Result";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import { type HandlerErr} "../Errors";
import { Kind = { type CanisterKind; compareCanisterKind } } "../Canisters";

mixin (mappings: [(CanisterKind, [Principal])]) {
  // ===== TYPES =====

  type InspectParamsMsgUserMapping = {
    #handlerUpdateMappings : () -> (mapping : [Principal]);
  };

  // ===== MEMORY =====

  var memMappings = Map.fromArray(mappings, compareCanisterKind);

  // ===== HELPERS =====

  func helperFindByPrincipal(kind: CanisterKind, principal: Principal) : Principal {
      let ?arr = memMappings.get(compareCanisterKind, kind) else return Principal.anonymous(); 
      arr[ principal.hash().toNat() % arr.size()]
  };

  func helperFindById(kind: CanisterKind, id: Nat) : Principal {
      let ?arr = memMappings.get(compareCanisterKind, kind) else return Principal.anonymous(); 
      arr[ id % arr.size()]
  };

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerUpdateMappings(mapping: [(CanisterKind, [Principal])]) : async Result<(), HandlerErr> {
      memMappings := Map.fromArray(mapping, compareCanisterKind);
      #ok
  };
}