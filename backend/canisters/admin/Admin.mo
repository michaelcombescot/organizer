import Debug "mo:core/Debug";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Blob "mo:core/Blob";
import List "mo:core/List";
import Runtime "mo:core/Runtime";
import Canisters "../../shared/Canisters";
import Array "mo:core/Array";
import Queue "mo:core/Queue";
import Timer "mo:core/Timer";
import UserMapping "../../shared/UserMapping";
import Errors "../../shared/Errors";
import Configs "../../Configs";
import SearchUsers "../search/SearchUsers";
import Index "../index/Index";
import BucketUsers "../buckets/bucketUsers";

shared ({ caller = owner }) persistent actor class Admin() = this {
  let thisPrincipal = Principal.fromActor(this);

  include MixinKnownCanisters({ alreadyKnown = [] });

  // ===== MEMORY =====

  let memUsersMapping: UserMapping.UserRing = [];

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerAddCanister : () -> (kind : Canisters.CanisterKind, principal : Principal);
      #handlerAddKnownCanisters : () -> (principals : [Principal], kind : Canisters.CanisterKind);
      #handlerCreateBucket : () -> (kind : Canisters.DynamicKind);
      #handlerRemoveKnownCanisters : () -> (principals : [Principal], kind : Canisters.CanisterKind);
      #handlerTopCanister : () -> (canisterPrincipal : Principal, kind : Canisters.CanisterKind);
      #handlerUpgradeCanisterKind : () -> (nature : Canisters.CanisterKind, wasmModule : Blob.Blob)
    }
  };

  system func inspect(params: inspectParams) : Bool {
    params.caller.isController()
  };

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerUpgradeCanisterKind(nature : Canisters.CanisterKind, wasmModule: Blob.Blob) : async Result.Result<(), Errors.HandlerErr> {
    if ( not caller.isController() ) return #err(#errMustBeController);

    // let ?canistersMap = memCanisters.get(CanistersKinds.compareCanistersKinds, #static(nature)) else Runtime.trap("No canisters of type " # debug_show(nature) # " found");

    // for ( canisterPrincipal in Map.keys(canistersMap) ) {
    //     try {
    //         await IC.ic.install_code({
    //             mode = #upgrade(?{ 
    //                 wasm_memory_persistence = ?#keep; 
    //                 skip_pre_upgrade = null; 
    //             });
    //             canister_id = canisterPrincipal;
    //             wasm_module = wasmModule;
    //             arg = to_candid((thisPrincipal));
    //             sender_canister_version = null;
    //     });                 
    //         Debug.print("[coordinator] Upgraded canister " # Principal.toText(canisterPrincipal));
    //     } catch (e) {
    //         Debug.print("[coordinator] Cannot upgrade bucket, error: " # Error.message(e));
    //     };
    // };

    #ok
  };

  public shared ({ caller }) func handlerCreateBucket(kind: Canisters.DynamicKind) : async Result.Result<Principal, Errors.HandlerErr> {
    if ( isControllerOrKnownCanister(caller, #dynamic(#index)) ) return #err(#errForbidden);

    await createCanister(kind)
  };

  // ===== HELPERS =====

  func createCanister(kind: Canisters.DynamicKind) : async Result.Result<Principal, Errors.HandlerErr> {
    try {
      let newPrincipal =  switch (kind) {
        case (#index) Principal.fromActor(await (with cycles = Configs.newIndexNbCycles) Index.Index(knownCanistersToTuple()));
        case (#bucket(b)) {
          switch (b) {
            case (#bucketUsers) Principal.fromActor(await (with cycles = Configs.newBucketNbCycles) BucketUsers.BucketUsers(knownIndexesToTuple()));
            case (#bucketGroups) Principal.fromActor(await (with cycles = Configs.newBucketNbCycles) BucketGroups.BucketGroups(knownIndexesToTuple()));
          };
        };
        case (#search(k)) {
          switch (k) {
            case (#searchUsers) Principal.fromActor(await (with cycles = Configs.newSearchNbCycles) SearchUsers.SearchUsers(knownIndexesToTuple()));
            case (#searchGroups) Principal.fromActor(await (with cycles = Configs.newSearchNbCycles) SearchGroups.SearchGroups(knownIndexesToTuple()));
          };
        };
      };

      addKnownCanister(#dynamic(kind),newPrincipal);

      memjobsQueue.pushBack({ targetPrincipal = targetPrincipal; newCanisterPrincipal = newPrincipal; newCanisterKind = #dynamic(kind) });

      #ok(newPrincipal)
    } catch (e) {
        #err(#errInterCanisterCall("Cannot create canister, error: " # Error.message(e)))
    }
  };
};