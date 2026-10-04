import Principal "mo:core/Principal";
import Canisters "../../shared/Canisters";
import MixinHandlersKnownCanisters "../../shared/mixins/MixinKnownCanisters";

shared ({ caller = owner }) persistent actor class SearchUsers(knownCanisters: [(Principal, Canisters.CanisterKind)]) = this {
  include MixinHandlersKnownCanisters({
    alreadyKnown = knownCanisters;

  });
};