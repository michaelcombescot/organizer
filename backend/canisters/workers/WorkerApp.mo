import { Kind = {type CanisterKind} } "../../shared/Canisters";
import Queue "mo:core/Queue";
import Timer "mo:core/Timer";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Errors "../../shared/Errors";
import MixinKnownCanisters "../../shared/MixinKnownCanisters";

shared ({ caller = owner }) persistent actor class WorkerApp(knownCanisters: [(Principal, CanisterKind)]) = this {
  // ===== MEMORY =====
  
  include MixinKnownCanisters(knownCanisters);

  // ===== TIMERS =====

  Timer.recurringTimer<system>(#seconds(86400), func () : async () {
    // Timer logic here
  });

  // ===== SYSTEM =====

  type InspectParams = {
    arg: Blob;
    caller : Principal;
    msg : {
      #addKnownCanisters : () -> (canisters : [(Principal, Canisters.CanisterKind)]);
      #removeKnownCanisters : () -> (canisters : [Principal]);
    };
};

  system func inspect(params: InspectParams) : Bool {
    params.caller.isController() or memKnownCanisters.containsKey(params.caller)
  };

  public shared ({ caller }) func addKnownCanisters(canisters: [(Principal, Canisters.CanisterKind)]) : async Result.Result<(), Errors.HandlerErr> {
    if ( not caller.isController() ) return #err(#errMustBeController);

    for ((principal, kind) in canisters.values()) {
      memKnownCanisters.add(principal, kind);
    };
    
    #ok
  };

  public shared ({ caller }) func removeKnownCanisters(canisters: [Principal]) : async Result.Result<(), Errors.HandlerErr> {
    if ( not caller.isController() ) return #err(#errMustBeController);

    for (principal in canisters.values()) {
      memKnownCanisters.remove(principal);
    };

    #ok
  };

  // ===== HANDLERS =====
}