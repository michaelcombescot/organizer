import Nat32 "mo:core/Nat32";
import Char "mo:core/Char";

module {
  public func hashText(text: Text) : Nat {
    var hash : Nat = 0;

    for (c in text.chars()) {
      hash := hash * 31 + c.toNat32().toNat();
    };

    hash
  }
}