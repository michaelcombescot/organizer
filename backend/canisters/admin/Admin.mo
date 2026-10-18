import Debug "mo:core/Debug";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
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
import SearchUsersByEmail "../search/SearchUsersByEmail";
import SearchUsersByName "../search/SearchUsersByName";
import Index "../index/Index";
import BucketUsers "../buckets/bucketUsers/BucketUsers";
import IC "mo:ic/Types";

shared ({ caller = owner }) persistent actor class Admin() = this {
  let thisPrincipal = Principal.fromActor(this);

  // ===== MEMORY =====

  include MixinCanistersByKind([]);
  include MixinCanistersSlots([]);
  include MixinTopUpCycles<system>(memKnownCanistersByKind);
  include MixinJobs<system>(memKnownCanistersByKind);

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerCreateCanister : () -> (kind : CanisterKind);
      #handlerUpgradeCanisterKind : () -> (nature : CanisterKind, wasmModule : Blob.Blob)
    } or InspectParamsMsgUserMapping;
  };

  system func inspect(params: inspectParams) : Bool {
    params.caller.isController()
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetFullMapping() : async [(CanisterKind, [Principal])] {
    if ( not isKnown(caller) ) return [];

    knownCanistersToTuples()
  };

  public shared ({ caller }) func handlerCreateCanister(kind: CanisterKind) : async Result.Result<Principal, Errors.HandlerErr> {
    if ( not isKnown(caller) ) return #err(#errForbidden);

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
            case (#searchUsersByEmail) Principal.fromActor(await (with cycles = Configs.NEW_SEARCH_NB_CYCLES) SearchUsersByEmail.SearchUsersByEmail(knownIndexes()));
            case (#searchUsersByName) Principal.fromActor(await (with cycles = Configs.NEW_SEARCH_NB_CYCLES) SearchUsersByName.SearchUsersByName(knownIndexes()));
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

  public shared ({ caller }) func handlerUpgradeCanisterKind(canisterId: Principal, wasmModule: Blob.Blob) : async Result.Result<(), Errors.HandlerErr> {
    if ( not isKnown(caller) ) return #err(#errMustBeController);

    let resp = await IC.install_code({
      mode = #upgrade;
      canister_id = canisterId;
      wasm_module = wasmModule;
      arg = to_candid ();
    });

    switch (resp) {
      case (#ok) ();
      case (#err(e)) return #err(#errInterCanisterCall("Cannot upgrade canister with canisterId " # Principal.toText(canisterId) # ", error: " # Error.message(e)));
    }
  };   
};