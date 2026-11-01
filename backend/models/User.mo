import Map "mo:core/Map";
import Time "mo:core/Time";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import Loc "../shared/Loc";

module {
  public type User = {
    data: UserData;
    groups: Map.Map<Loc.Loc, ()>;
    createdAt: Time.Time;
    updatedAt: Time.Time;
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
      name = self.data.name;
      email = self.data.email;
    };
  };

  public type PrivateUser = {
    name : Text;
    email : Text;
    groups : [Loc.Loc];
    createdAt : Time.Time;
    updatedAt : Time.Time;
  };

  public func toPrivate(self : User) : PrivateUser {
    {
      name = self.data.name;
      email = self.data.email;
      groups = self.groups.keys().toArray();
      createdAt = self.createdAt;
      updatedAt = self.updatedAt;
    };
  };
};