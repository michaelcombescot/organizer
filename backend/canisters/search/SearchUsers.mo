import Principal "mo:core/Principal";
import Map "mo:core/Map";
import { type Result } "mo:core/Result";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import MixinKnownCanistersByPrincipal "../../shared/mixins/MixinCanistersByPrincipal";
import { type HandlerErr } "../../shared/Errors";

shared ({ caller = owner }) persistent actor class SearchUsers(canisters: [Principal]) = this {
  include MixinKnownCanistersByPrincipal(canisters);

  // ===== MEMORY ======

  let memUserPerName = Map.empty<Text, Principal>(); 
  let memUserPerEmail = Map.empty<Text, Principal>();

  // ===== SYSTEM =====

  type inspectParams = {
    arg : Blob;
    caller : Principal;
    msg : {
      #handlerSearchUserBy : () -> (params: SearchUserParams);
      #handlerUserUpdated : () -> (params: UserUpdatedParams);
      #handlerUserDeleted : () -> (params: UserDeletedParams);
    } or InspectParamsMsgKnownCanistersByPrincipal;
  };

  system func inspect(params: inspectParams) : Bool {
    if ( params.caller.isAnonymous() ) return false;
    if ( params.arg.size() > 5000 ) return false;

    isControllerOrKnownCanister(params.caller)
  };

  // ===== HANDLERS =====

  public type SearchUserParams = {
    field: SearchUserField;
    value: Text;
  };

  public type SearchUserField = {
    #name;
    #email;
  };

  public query func handlerSearchUserBy(params: SearchUserParams) : async [Principal] {
    let map = switch (params.field) {
      case (#name) memUserPerName;
      case (#email) memUserPerEmail;
    };

    map
      .entriesFrom(params.value)
      .filter(func ((k, v)) = k.startsWith(#text(params.value)))
      .take(20)
      .map(func ((k, v)) { v })
      .toArray()
  };

  public type UserUpdatedParams = {
    oldName: Text;
    oldEmail: Text;
    name: Text;
    email: Text;
    principal: Principal;
  };

  public shared ({ caller }) func handlerUserUpdated(params: UserUpdatedParams) : async Result<(), HandlerErr> {
    if (not isControllerOrKnownCanister(caller)) return #err(#errForbidden);

    memUserPerName.remove(Text.compare, params.oldName.toLower());
    memUserPerEmail.remove(Text.compare, params.oldEmail.toLower());

    memUserPerName.add(Text.compare, params.name.toLower(), params.principal);
    memUserPerEmail.add(Text.compare, params.email.toLower(), params.principal);

    #ok
  };

  public type UserDeletedParams = {
    name: Text;
    email: Text;
  };

  public shared ({ caller }) func handlerUserDeleted(params: UserDeletedParams) : async Result<(), HandlerErr> {
    if (not isControllerOrKnownCanister(caller)) return #err(#errForbidden);

    memUserPerName.remove(Text.compare, params.name.toLower());
    memUserPerEmail.remove(Text.compare, params.email.toLower());

    #ok
  };
}