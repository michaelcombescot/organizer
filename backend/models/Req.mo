import { type Order } "mo:core/Order";
import Text "mo:core/Text";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import { type Identifier } "../shared/Identifiers";

module {
  public module ReqBy {
    public type ReqBy = {
      #text: Text;
      #nat: Nat;
      #principal: Principal;
    };

    public func compare(a : ReqBy, b : ReqBy) : Order {
      switch (a, b) {
        // same variant: compare the inner values
        case (#text x, #text y) Text.compare(x, y);
        case (#nat x, #nat y) Nat.compare(x, y);
        case (#principal x, #principal y) Principal.compare(x, y);
        // different variants: order by variant (text < nat < principal)
        case (#text _, _) #less;
        case (#nat _, #text _) #greater;
        case (#nat _, #principal _) #less;
        case (#principal _, _) #greater;
      }
    };
  };

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

  public module ReqReservation {
    public type ReserveEntryResult = {
      #reserved;
      #alreadyTaken;
      #alreadyBelongs;
      #alreadyReserved;
    };
  };
}