import { type Result } "mo:core/Result";
import { ReqKind } "../shared/Req";
import Errors "Errors";
import Loc "Loc";
import Principal "mo:core/Principal";
import { CanisterKind } "Canisters";

module Interfaces {
  public type ActorFactory = actor {
    handlerGetFullMapping : shared () -> async Result<{ version: Nat; canisters: [(CanisterKind.CanisterKind, [(Nat, Principal)])] }, Errors.HandlerErr>;
  };

  public type ActorSearchIndex = actor {
    handlerSaveEntry : shared {kind: ReqKind.ReqKind; loc: Loc.Loc; key: Text} -> async Result<(), Errors.HandlerErr>;
    handlerLiberateEntry : shared { kind: ReqKind.ReqKind; key: Text } -> async Result<(), Errors.HandlerErr>;
  };
};