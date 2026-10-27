import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Timer "mo:core/Timer";
import Errors "../../shared/Errors";
import { ic } "mo:ic";
import { StaticKind } "../../shared/Canisters";
import ModTopUpCycles "ModTopUpCycles";

shared ({ caller }) actor class Admin() = this {
  include MixinCanistersMapping({ self = Principal.fromActor(this); selfKind = #static(#admin); mapping = { version = 0; canisters = [] } });

  // ===== CONFIGS =====

  let MAINTENANCE_TIMER = #hours(12);

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #systemAddStaticCanisters : () -> (canisters: [(StaticKind.StaticKind, Principal)]);

      #handlerUpgradeCanisterKind : () -> (canisterId: Principal, wasmModule: Blob.Blob);
    };
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;

    true
  };

  public shared ({ caller }) func systemAddStaticCanisters(canisters: [(StaticKind.StaticKind, Principal)]) : async Result.Result<(), Errors.HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errForbidden);

    addStaticCanisters(canisters);
    #ok
  };

  // ===== JOBS =====

  ignore Timer.recurringTimer<system>(MAINTENANCE_TIMER, func () : async () {
    await getAndSaveMapping();
    await ModTopUpCycles.topUpCanisters(memMapping);
  });

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerUpgradeCanisterKind(canisterId: Principal, wasmModule: Blob.Blob) : async Result.Result<(), Errors.HandlerErr> {
    if (not isKnownBasic(caller)) return #err(#errMustBeController);

    try {
      await ic.install_code({
        sender_canister_version = null;
        mode = #upgrade(?{ wasm_memory_persistence = ?#keep; skip_pre_upgrade = null; });
        canister_id = canisterId;
        wasm_module = wasmModule;
        arg = to_candid();
      });
      #ok(())
    } catch (e) {
      #err(#errInterCanisterCall("Cannot upgrade canister with canisterId " # canisterId.toText() # ", error: " # e.message() ))
    }
  };
}