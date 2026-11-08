import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Iter "mo:core/Iter";
import Blob "mo:core/Blob";
import MixinCommon "../../shared/mixins/MixinCommon";
import Canisters "../../shared/Canisters";
import { type Result } "mo:core/Result";
import List "mo:core/List";
import { type HandlerErr } "../../shared/Errors";
import Loc "../../shared/Loc";

shared ({ caller }) actor class IndexMain() = this {
  let self = Principal.fromActor(this);

  include MixinCommon({ thisPrincipal = self; thisKind = #dynamic(#orderedByTime(#indexMain))});

  // ===== SYSTEM =====

  type InspectParams = {
      arg: Blob;
      caller : Principal;
      msg : {
        #handlerGetBucketUsers : () -> (locs: [Loc.LocPerPrincipal]);
        #handlerGetSearchIndexes : () -> ();
        #handlerGetCurrentUserBucket : () -> ();
      } or InspectCommon;
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller.isAnonymous() ) { return false; };

      if ( Blob.size(params.arg) > 5000 ) { return false; };

      return true
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetBucketUsers(locs: [Loc.LocPerPrincipal]) : async Result<[Principal], HandlerErr> {
    if ( updateMappingOngoing ) return #err(#errUpdateOngoing);
    if ( caller.isAnonymous() ) return #err(#errForbidden);

    let ?map = memMapping.get(#dynamic(#orderedByHash(#bucketUsers))) else return #err(#errNotFound("Failed to find mapping for bucket users"));

    let results = List.empty<Principal>();
    for (loc in locs.values()) {
      switch (map.get(loc.bucket)) {
        case (?principal) results.add(principal);
        case null {};
      }
    };

    #ok(results.toArray());
  };

  public query ({ caller }) func handlerGetSearchIndexes() : async Result<[(Nat, Principal)], HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);

    let ?map = memMapping.get(#dynamic(#orderedByHash(#searchIndexes))) else return #err(#errNotFound("Failed to find mapping for search indexes"));

    #ok(map.entries().toArray());
  };

  public query ({ caller }) func handlerGetCurrentUserBucket() : async Result<Principal, HandlerErr> {
    if ( caller.isAnonymous() ) return #err(#errForbidden);

    let ?principal = findCanisterFromText(#dynamic(#orderedByHash(#bucketUsers)), caller.toText()) else return #err(#errNotFound("Failed to find canister for caller"));

    #ok(principal);
  };
};