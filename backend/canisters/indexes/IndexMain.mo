import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import Canisters "../../shared/Canisters";
import { type Result } "mo:core/Result";
import { type HandlerErr } "../../shared/Errors";

shared ({ caller }) actor class IndexMain(mapping: ?Canisters.Mapping) = this {
  let self = Principal.fromActor(this);

  include MixinCanistersMapping({ self = self; selfKind = #dynamic(#orderedByTime(#indexMain)); mapping = mapping });

  // ===== SYSTEM =====

  type InspectParams = {
      arg: Blob;
      caller : Principal;
      msg : {
        #handlerGetCurrentUserBucket : () -> ();
      } or InspectMapping;
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller.isAnonymous() ) { return false; };

      if ( Blob.size(params.arg) > 5000 ) { return false; };

      return true
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetCurrentUserBucket() : async Result<Principal, HandlerErr> {
    let ?principal = findCanisterFromText(#dynamic(#orderedByHash(#bucketUsers)), caller.toText()) else return #err(#errNotFound);

    #ok(principal);
  };
};