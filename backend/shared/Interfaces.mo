import { type Result } "mo:core/Result";
import { ReqKind } "../shared/Req";
import Errors "Errors";
import Loc "Loc";
import Canisters "Canisters";

module Interfaces {
  public type ActorUpdateMapping = actor {
    handlerUpdateMapping : shared (mapping: Canisters.Mapping) -> async Result<(), Errors.ErrHandler>;
  };

  public type ActorFactory = actor {
    handlerGetFullMapping : shared () -> async Result<Canisters.Mapping, Errors.ErrHandler>;
  };

  public type ActorSearchIndexes = actor {
    handlerSaveEntry : shared ({kind: ReqKind.ReqKind; owner: Loc.LocOwner; key: Text}) -> async Result<(), Errors.ErrHandler>;
    handlerLiberateEntry : shared ({ kind: ReqKind.ReqKind; key: Text }) -> async Result<(), Errors.ErrHandler>;
  };
};