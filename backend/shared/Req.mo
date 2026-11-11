import { type Order } "mo:core/Order";
import Text "mo:core/Text";

module {
  public module ReqKind {
    public type ReqKind = {
      #reqUsers: ReqUser.ReqUser;
    };

    public func compare(a : ReqKind, b : ReqKind) : Order {
      Text.compare(debug_show(a), debug_show(b))
    };
  };

  public module ReqUser {
    public type ReqUser = {
      #usersByPrincipal;
      #usersByName;
      #usersByEmail;
    };
  };
}