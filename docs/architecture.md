# Goal

The goal of this project is to be a blueprint for multicanister with infinite scalability.
It will consist of the bare minimum to have a landing page, create a user, and be able to search a user among
potentially hundreds of canisters and millions of users.

# Base architecture

The architecture consist of several canisters:

## admin

Own the bucket rings, create new buckets, top up all buckets, is the source of truth for the whole app.
It have 3 endpoints:
- one to get all principals of buckets of a specific kind. This endpoint will be paired with a bash script to loop on those principals and update 
```
// rust
use ic_cdk::management_canister::{install_code, InstallCodeArgs, CanisterInstallMode};

#[ic_cdk::update(guard="is_controller")]
async fn upgrade_child(canister_id: Principal, wasm_module: Vec<u8>) {
    let args = InstallCodeArgs {
        mode: CanisterInstallMode::Upgrade(None),
        canister_id,
        wasm_module,
        arg: vec![],
    };
    install_code(&args).await.expect("Failed to upgrade child canister");
}

// motoko
import Management "ic:aaaaa-aa";

// In your factory actor:
public shared ({ caller }) func upgradeChild(canisterId : Principal, newWasm : Blob) : async () {
  // Only allow authorized callers
  await Management.install_code({
    mode = #upgrade;
    canister_id = canisterId;
    wasm_module = newWasm;
    arg = to_candid (); // post_upgrade argument
    sender_canister_version = null;
  });
};
```