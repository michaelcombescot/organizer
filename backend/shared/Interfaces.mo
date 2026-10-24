import { type Result } "mo:core/Result";
import { ReqKind } "../models/Req";
import Errors "Errors";
import Loc "Loc";

module Interfaces {
  public type Interface = {
    #queriesIndex
  };

  public type IQueriesIndexTextActor = actor {
    handlerSaveEntry : shared {kind: ReqKind.ReqKind; loc: Loc.Loc; key: Text} -> async Result<(), Errors.HandlerErr>;
    handlerLiberateEntry : shared { kind: ReqKind.ReqKind; key: Text } -> async Result<(), Errors.HandlerErr>;
  };
};