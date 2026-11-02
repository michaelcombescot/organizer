import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Iter "mo:core/Iter";
import Blob "mo:core/Blob";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import Canisters "../../shared/Canisters";
import { type Result } "mo:core/Result";
import List "mo:core/List";
import { type HandlerErr } "../../shared/Errors";
import Loc "../../shared/Loc";

shared ({ caller }) actor class IndexMain(mapping: ?Canisters.Mapping) = this {
  let self = Principal.fromActor(this);

  include MixinCanistersMapping({ self = self; selfKind = #dynamic(#orderedByTime(#indexMain)); mapping = mapping });

  // ===== SYSTEM =====

  type InspectParams = {
      arg: Blob;
      caller : Principal;
      msg : {
        #handlerGetBucketUsers : () -> (locs: [Loc.Loc]);
        #handlerGetSearchIndexes : () -> ();
        #handlerGetCurrentUserBucket : () -> ();
      } or InspectMapping;
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller.isAnonymous() ) { return false; };

      if ( Blob.size(params.arg) > 5000 ) { return false; };

      return true
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetBucketUsers(locs: [Loc.Loc]) : async Result<[Principal], HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);

    let ?map = memMapping.get(#dynamic(#orderedByHash(#bucketUsers))) else return #err(#errNotFound("Failed to find mapping for bucket users"));

    let results = List.empty<Principal>();
    for (loc in locs.values()) {
      switch (map.get(loc.bucketHash)) {
        case (?principal) results.add(principal);
        case null {};
      }
    };

    #ok(results.toArray());
  };

  public query ({ caller }) func handlerGetSearchIndexes() : async Result<[(Nat, Principal)], HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);

    let ?map = memMapping.get(#dynamic(#orderedByHash(#searchIndexes))) else return #ok([]);

    #ok(map.entries().toArray());
  };

  public query ({ caller }) func handlerGetCurrentUserBucket() : async Result<Principal, HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);

    let ?principal = findCanisterFromText(#dynamic(#orderedByHash(#bucketUsers)), caller.toText()) else return #err(#errNotFound("Failed to find canister for caller"));

    #ok(principal);
  };
};