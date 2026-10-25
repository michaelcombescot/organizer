import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Blob "mo:core/Blob";
import Runtime "mo:core/Runtime";
import { CanisterKind; DynamicKind; StaticKind } "../../shared/Canisters";
import Time "mo:core/Time";
import Errors "../../shared/Errors";
import SearchIndexes "../searches/SearchIndexes";
import IndexMain "../indexes/IndexMain";
import BucketUsers "../buckets/BucketUsers";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";

shared ({ caller = owner }) actor class Factory() = this {
  let thisPrincipal = Principal.fromActor(this);

  // ===== CONFIGS =====

  func confGetNewCanisterNbCycles (kind: DynamicKind.DynamicKind) : Nat {
    switch (kind) {
      case (#index(i)) {
        switch (i) {
          case (#indexMain) return 1_000_000_000_000;
        }
      };
      case (#search(s)) {
        switch (s) {
          case (#searchIndex) return 1_000_000_000_000;
        }
      };
      case (#bucket(b)) {
        switch (b) {
          case (#bucketUsers) return 1_000_000_000_000;
        }
      };
    };
  };

  // ===== MEMORY =====

  include MixinCanistersMapping({ self = thisPrincipal; selfKind = #static(#factory); mapping = { version = 0; canisters = [(#static(#factory), [(0, thisPrincipal)])] } });

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #systemAddStaticCanisters : () -> (canisters : [(StaticKind.StaticKind, Principal)]);

      #handlerGetFullMapping : () -> ();
      #handlerCreateCanister : () -> (kind : DynamicKind.DynamicKind);
    };
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous()) return false;

    return true
  };

  public shared ({ caller }) func systemAddStaticCanisters(canisters: [(StaticKind.StaticKind, Principal)]) : async Result.Result<(), Errors.HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errForbidden);

    addStaticCanisters(canisters);
    #ok
  };

  // ===== INIT =====

  if (memMapping.size() == 0) saveMapping({ version = 0; canisters = [(#static(#factory), [(0, thisPrincipal)])] });

  // ===== HELPERS =====

  func addCanister(kind: CanisterKind.CanisterKind, principal: Principal) : () {
    let map = switch ( memMapping.get(kind) ) {
      case null {
        let map = Map.empty<Nat, Principal>();
        memMapping.add(kind, map);
        map
      };
      case (?map) map;
    };

    let index = switch ( kind ) {
      case (#static(_)) 0;
      case (#dynamic(k)) {
        switch (k) {
          case (#index(_)) map.size();
          case (#search(_)) Runtime.trap("Cannot determine index for search canisters");
          case (#bucket(b)) {
            switch (b) {
              case (#bucketUsers) Runtime.trap("Cannot determine index for bucketUsers");
            };
          }
        }
      };
    };

    map.add(index, principal);
    memKnownCanisters.add(principal, ());
    currentVersion := currentVersion + 1;
    lastVersionMaj := Time.now();
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetFullMapping() : async Result.Result<{ version: Nat; canisters: [(CanisterKind.CanisterKind, [(Nat, Principal)])] }, Errors.HandlerErr> {
    if ( not (isKnownBasic(caller)) ) return #err(#errForbidden);

    #ok({ version = currentVersion; canisters = knownCanistersToMapping().canisters })
  };

  public shared ({ caller }) func handlerCreateCanister(kind: DynamicKind.DynamicKind) : async Result.Result<Principal, Errors.HandlerErr> {
    if ( not isKnownBasic(caller) ) return #err(#errForbidden);

    // 1. CREATE THE CANISTER
    let nbCycles = confGetNewCanisterNbCycles(kind);

    let newPrincipal = try {
      switch (kind) {
        case (#index(i)) {
          switch (i) {
            case (#indexMain) Principal.fromActor(await (with cycles = nbCycles) IndexMain.IndexMain(knownCanistersToMapping()));
          };
        } 
        case (#search(s)) {
          switch (s) {
            case (#searchIndex) Principal.fromActor(await (with cycles = nbCycles) SearchIndexes.SearchIndexes(knownCanistersToMapping()));
          };
        };
        case (#bucket(b)) {
          switch (b) {
            case (#bucketUsers) Principal.fromActor(await (with cycles = nbCycles) BucketUsers.BucketUsers(knownCanistersToMapping()));
          };
        };
      };
    } catch (e) {
      return #err(#errInterCanisterCall("Cannot create canister, error: " # e.message()))
    };

    // 2. SAVE THE CANISTER INFORMATION

    addCanister(#dynamic(kind), newPrincipal);

    #ok(newPrincipal)
  };
};