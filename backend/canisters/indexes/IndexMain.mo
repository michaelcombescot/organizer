import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Hash "../../shared/Hash";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import MixinCanistersMapping "../../shared/mixins/MixinCanistersMapping";
import { CanisterKind; Mapping } "../../shared/Canisters";
import { type Result } "mo:core/Result";
import { type HandlerErr } "../../shared/Errors";

shared ({ caller }) actor class IndexMain(mapping: Mapping.Mapping) = this {
  let self = Principal.fromActor(this);

  include MixinCanistersMapping({ self = self; selfKind = #dynamic(#index(#indexMain)); mapping = mapping });

  // ===== SYSTEM =====

  type InspectParams = {
      arg: Blob;
      caller : Principal;
      msg : {
        #handlerGetCurrentUserBucket : () -> ();
      };
  };

  system func inspect(params: InspectParams) : Bool {
      if ( params.caller.isAnonymous() ) { return false; };

      if ( Blob.size(params.arg) > 5000 ) { return false; };

      return true
  };

  // ===== HANDLERS =====

  public query ({ caller }) func handlerGetCurrentUserBucket() : async Result<Principal, HandlerErr> {
    let ?map = memMapping.get(#dynamic(#bucket(#bucketUsers))) else return #err(#errNotFound);
    let ?principal = map.get(Hash.hashText(caller.toText())) else return #err(#errNotFound);
    #ok(principal);
  };
};