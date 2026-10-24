import { type Order } "mo:core/Order";
import Text "mo:core/Text";

module {
  public module ReqKind {
    public type ReqKind = {
      #usersByPrincipal;
      #usersByName;
      #usersByEmail;
    };

    public func compare(a : ReqKind, b : ReqKind) : Order {
      Text.compare(debug_show(a), debug_show(b))
    };
  };
}