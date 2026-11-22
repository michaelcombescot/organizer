import Map "mo:core/Map";
import { type Result } "mo:core/Result";
import { type ErrValidation } "../shared/Errors";
import Time "mo:core/Time";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import List "mo:core/List";
import Loc "../shared/Loc";

module {
  public type User = {
    name: Text;
    email: Text;
    groups: Map.Map<Loc.LocOwner, ()>;
    createdAt: Time.Time;
    updatedAt: Time.Time;
  };

  public func validate(self : User) : Result<(), [ErrValidation]> {
    let errors = List.empty<ErrValidation>();

    if (self.name.size() < 3 or self.name.size() > 100) {
      errors.add(#badLength({ field = "name"; min = 3; max = 100 }));
    };
    
    if (self.email.size() < 3 or self.email.size() > 100) {
      errors.add(#badLength({ field = "email"; min = 5; max = 100 }));
    };

    if (errors.size() > 0) {
      #err(errors.toArray())
    } else {
      #ok(())
    };
  };

  public type UserData = {
    name: Text;
    email: Text;
  };

  public type PublicUser = {
    principal: Principal;
    name : Text;
    email : Text;
  };

  public func toPublic(self : User, principal: Principal) : PublicUser {
    {
      principal = principal;
      name = self.name;
      email = self.email;
    };
  };

  public type PrivateUser = {
    name : Text;
    email : Text;
    groups : [Loc.LocOwner];
    createdAt : Time.Time;
    updatedAt : Time.Time;
  };

  public func toPrivate(self : User) : PrivateUser {
    {
      name = self.name;
      email = self.email;
      groups = self.groups.keys().toArray();
      createdAt = self.createdAt;
      updatedAt = self.updatedAt;
    };
  };
};