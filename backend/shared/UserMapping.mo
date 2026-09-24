import Principal "mo:core/Principal";
import Nat32 "mo:core/Nat32";

module {
    public type UserRing = [Principal];

    public func helperFindUserBucket(array: [Principal], userPrincipal: Principal) : Principal {
        let userPrincipalHash = Principal.hash(userPrincipal);
        array[ Nat32.toNat(userPrincipalHash) % array.size()]
    };
}