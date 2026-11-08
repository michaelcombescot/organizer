import { type Result } "mo:core/Result";
import { ReqKind } "../shared/Req";
import Errors "Errors";
import Loc "Loc";
import Canisters "Canisters";

module Interfaces {
  public type ActorReceiveMapping = actor {
    handlerUpdateMapping : shared (mapping: Canisters.Mapping) -> async Result<(), Errors.HandlerErr>;
  };

  public type ActorFactory = actor {
    handlerGetFullMapping : shared () -> async Result<Canisters.Mapping, Errors.HandlerErr>;
  };

  public type ActorSearchIndexes = actor {
    handlerSaveEntry : shared {kind: ReqKind.ReqKind; loc: Loc.Loc; key: Text} -> async Result<(), Errors.HandlerErr>;
    handlerLiberateEntry : shared { kind: ReqKind.ReqKind; key: Text } -> async Result<(), Errors.HandlerErr>;
  };
};