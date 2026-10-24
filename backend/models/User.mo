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
    name : Text;
    email : Text;
    groups : [Loc.Loc];
    createdAt : Time.Time;
    updatedAt : Time.Time;
  };

  public func toPublic(self : User) : PublicUser {
    {
      name = self.data.name;
      email = self.data.email;
      groups = self.groups.keys().toArray();
      createdAt = self.createdAt;
      updatedAt = self.updatedAt;
    };
  };
};