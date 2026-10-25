import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import Result "mo:core/Result";
import Error "mo:core/Error";
import Errors "../../shared/Errors";
import IC "mo:ic/Types";
import { StaticKind } "../../shared/Canisters";

shared ({ caller }) actor class Admin() = this {
  include MixinCanistersMapping({ self = Principal.fromActor(this); selfKind = #static(#admin); mapping = { version = 0; canisters = [] } });

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

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerUpgradeCanisterKind(canisterId: Principal, wasmModule: Blob.Blob) : async Result.Result<(), Errors.HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errMustBeController);

    let resp =try {
      let resp = await IC.install_code({
        mode = #upgrade;
        canister_id = canisterId;
        wasm_module = wasmModule;
        arg = to_candid ();
      });
    } catch (e) {
      return #err(#errInterCanisterCall("Cannot upgrade canister with canisterId " # Principal.toText(canisterId) # ", error: " # Error.message(e)));
    };

    switch (resp) {
      case (#ok) ();
      case (#err(e)) return #err(#errInterCanisterCall("Cannot upgrade canister with canisterId " # canisterId.toText() # ", error: " # Error.message(e)));
    }
  };   
};