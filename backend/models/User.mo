import Map "mo:core/Map";
import Time "mo:core/Time";
import Iter "mo:core/Iter";
import Text "mo:base/Text";
import Identifiers "../shared/identifiers";

module {
  public type User = {
    data: UserData;
    groups: Map.Map<Identifiers.Identifier, ()>;
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
    groups : [Identifiers.Identifier];
    createdAt : Time.Time;
    updatedAt : Time.Time;
  };

  public func toPublic(self : User) : PublicUser {
    {
      name = self.data.name;
      email = self.data.email;
      groups = Map.keys(self.groups).toArray();
      createdAt = self.createdAt;
      updatedAt = self.updatedAt;
    };
  };
};