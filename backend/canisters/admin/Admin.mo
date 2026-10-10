import Debug "mo:core/Debug";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import MixinCanistersByKind "../../shared/mixins/MixinCanistersByKind";
import MixinUsersMapping "../../shared/mixins/MixinUsersMapping";
import MixinTopUpCycles "MixinTopUpCycles";
import MixinJobs "../../shared/mixins/MixinJobs";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Blob "mo:core/Blob";
import List "mo:core/List";
import Runtime "mo:core/Runtime";
import { Kind = {type CanisterKind; compareCanisterKind; allSearchKinds; allBucketKinds} } "../../shared/Canisters";
import Array "mo:core/Array";
import Queue "mo:core/Queue";
import Timer "mo:core/Timer";
import Errors "../../shared/Errors";
import Configs "../../Configs";
import SearchUsers "../search/SearchUsers";
import Index "../index/Index";
import BucketUsers "../buckets/bucketUsers/BucketUsers";

shared ({ caller = owner }) persistent actor class Admin() = this {
  let thisPrincipal = Principal.fromActor(this);

  // ===== MEMORY =====

  include MixinCanistersByKind([]);
  include MixinUsersMapping([]);
  include MixinTopUpCycles<system>(memKnownCanistersByKind);
  include MixinJobs<system>(memKnownCanistersByKind);

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerCreateCanister : () -> (kind : CanisterKind);
      #handlerUpgradeCanisterKind : () -> (nature : CanisterKind, wasmModule : Blob.Blob)
    } or InspectParamsMsgKnownCanistersByKind or InspectParamsMsgUserMapping;
  };

  system func inspect(params: inspectParams) : Bool {
    params.caller.isController()
  };

  // ===== HANDLERS =====

  public shared ({ caller }) func handlerUpgradeCanisterKind(nature : CanisterKind, wasmModule: Blob.Blob) : async Result.Result<(), Errors.HandlerErr> {
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

  public shared ({ caller }) func handlerCreateCanister(kind: CanisterKind) : async Result.Result<Principal, Errors.HandlerErr> {
    if ( not (caller.isController() or isIndex(caller)) ) return #err(#errForbidden);

    await createCanister(kind)
  };

  // ===== HELPERS =====

  func createCanister(kind: CanisterKind) : async Result.Result<Principal, Errors.HandlerErr> {
    // 1. CREATE THE CANISTER

    let newPrincipal = try {
      switch (kind) {
        case (#registryIndexes) return #err(#errBadRequest("Cannot create canister of kind registryIndexes"));
        case (#index) Principal.fromActor(await (with cycles = Configs.NEW_INDEX_NB_CYCLES) Index.Index(knownCanistersTuples(), memUsersRing));
        case (#bucket(b)) {
          switch (b) {
            case (#bucketUsers) Principal.fromActor(await (with cycles = Configs.NEW_BUCKET_NB_CYCLES) BucketUsers.BucketUsers(knownIndexes()));
          };
        };
        case (#search(k)) {
          switch (k) {
            case (#searchUsers) Principal.fromActor(await (with cycles = Configs.NEW_SEARCH_NB_CYCLES) SearchUsers.SearchUsers(knownIndexes()));
          };
        };
      };
    } catch (e) {
      return #err(#errInterCanisterCall("Cannot create canister, error: " # Error.message(e)))
    };

    // 2. SAVE THE CANISTER INFORMATION

    saveCanisters([(kind, newPrincipal)]);

    // 3. SEND THE NEW CANISTER TO ALL RELEVANT CANISTERS

    switch (kind) {
      case (#registryIndexes) ();
      case (#index) {
        // send to buckets and search canisters
        let targets = List.empty<Principal>();

        allSearchKinds.forEach(func (searchKind) { 
          let ?map = memKnownCanistersByKind.get(compareCanisterKind, #search(searchKind)) else return;
          targets.addAll(Map.keys(map));
        });
        allBucketKinds.forEach(func (bucketKind) { 
          let ?map = memKnownCanistersByKind.get(compareCanisterKind, #bucket(bucketKind)) else return;
          targets.addAll(Map.keys(map));
        });
      };
      case (#bucket(_), #search(_)) {
        let targets = knownIndexes();
      };
      case (#search(k)) {
        let targets = knownIndexes();
      };
    };


    #ok(newPrincipal)
  };
};