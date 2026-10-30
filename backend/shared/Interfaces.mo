import { type Result } "mo:core/Result";
import { ReqKind } "../shared/Req";
import Errors "Errors";
import Loc "Loc";
import Principal "mo:core/Principal";
import Canisters "Canisters";

module Interfaces {
  public type ActorFactory = actor {
    handlerGetFullMapping : shared () -> async Result<?Canisters.Mapping, Errors.HandlerErr>;
  };

  public type ActorSearchIndexes = actor {
    handlerSaveEntry : shared {kind: ReqKind.ReqKind; loc: Loc.Loc; key: Text} -> async Result<(), Errors.HandlerErr>;
    handlerLiberateEntry : shared { kind: ReqKind.ReqKind; key: Text } -> async Result<(), Errors.HandlerErr>;
  };
};