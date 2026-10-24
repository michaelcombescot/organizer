import Debug "mo:core/Debug";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Blob "mo:core/Blob";
import List "mo:core/List";
import Runtime "mo:core/Runtime";
import { CanisterKind } "../../shared/Canisters";
import Array "mo:core/Array";
import Queue "mo:core/Queue";
import Timer "mo:core/Timer";
import Errors "../../shared/Errors";
import SearchIndexes "../searches/SearchIndexes";
import IndexMain "../indexes/IndexMain";
import BucketUsers "../buckets/bucketUsers/BucketUsers";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";

shared ({ caller = owner }) persistent actor class Factory() = this {
  let thisPrincipal = Principal.fromActor(this);

  // ===== MEMORY =====

  include MixinCanistersMapping([]);

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerCreateCanister : () -> (kind : CanisterKind.CanisterKind);
    } or InspectMappingMsg;
  };

  system func inspect(params: inspectParams) : Bool {
    params.caller.isController()
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetFullMapping() : async [(CanisterKind.CanisterKind, [(Nat, Principal)])] {
    if ( not (isKnown(caller) or caller.isController()) ) return [];

    knownCanistersToTuples()
  };

  public shared ({ caller }) func handlerAddIndex(indexPrincipal: Principal) : async Result.Result<(), Errors.HandlerErr> {
    if ( not isKnown(caller) ) return #err(#errForbidden);

    saveCanisters([(#index, [(0, indexPrincipal)])]);

    #ok(())
  };

  public shared ({ caller }) func handlerCreateCanister(kind: CanisterKind.CanisterKind) : async Result.Result<Principal, Errors.HandlerErr> {
    if ( not (isKnown(caller) or caller.isController()) ) return #err(#errForbidden);

     // 1. CREATE THE CANISTER

    let newPrincipal = try {
      switch (kind) {
        case (#registryIndexes) return #err(#errBadRequest("Cannot create canister of kind registryIndexes"));
        case (#index) return #err(#errBadRequest("Cannot create canister of kind index"));
        case (#bucket(b)) {
          switch (b) {
            case (#bucketUsers) Principal.fromActor(await (with cycles = Configs.NEW_BUCKET_NB_CYCLES) BucketUsers.BucketUsers(knownIndexes()));
          };
        };
        case (#search(k)) {
          switch (k) {
            case (#search) Principal.fromActor(await (with cycles = Configs.NEW_SEARCH_NB_CYCLES) Search.SearchUsersByEmail(knownIndexes()));
          };
        };
      };
    } catch (e) {
      return #err(#errInterCanisterCall("Cannot create canister, error: " # Error.message(e)))
    };

    // 2. SAVE THE CANISTER INFORMATION

    saveCanisters([(kind, newPrincipal)]);

    #ok(newPrincipal)
  };
};