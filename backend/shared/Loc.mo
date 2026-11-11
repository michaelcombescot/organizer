module {
  public type Loc = {
    bucket: Nat;
    owner: LocOwner;
  };

  public type LocOwner = {
    #id: Nat;
    #principal: Principal;
  };
}