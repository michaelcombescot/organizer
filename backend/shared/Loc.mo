module {
  public type Loc = {
    #perId: LocPerId;
    #perPrincipal: LocPerPrincipal;
  };

  public type LocPerId = {
    id: Nat;
    bucket: Nat;
  };
  public type LocPerPrincipal = {
    principal: Principal;
    bucket: Nat;
  };
}