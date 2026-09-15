import Debug "mo:core/Debug";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Map "mo:core/Map";
import Nat64 "mo:core/Nat64";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Error "mo:core/Error";
import Blob "mo:core/Blob";
import IC "mo:ic";
import List "mo:core/List";
import Runtime "mo:core/Runtime";
import Canisters "../../shared/Canisters";
import Index "../index/Index";
import BucketGroups "../buckets/bucketGroups";
import BucketUsers "../buckets/bucketUsers";
import Array "mo:core/Array";

// The coordinator is the main entry point to launch the application.
// Launching the coordinator will create all necessary buckets and indexes, it's the ONLY entry point, everything else is dynamically created.
// It will have several missions:
// - top up canisters when asked
// - be a bucket factory
// - save the users ring mapping
// - give resgistry to indexes
// - give indexes to buckets
// - manage canisters upgrades
shared ({ caller = owner }) persistent actor class Coordinator() = this {
    let thisPrincipal = Principal.fromActor(this);

    // ===== MEMORY =====

    let memCanisters = Map.empty<Canisters.CanisterKind, Map.Map<Principal, ()>>();
    let memUsersMapping: [Principal] = Array.empty(100);

    // ===== SYSTEM =====

    type inspectParams = {
        arg : Blob;
        caller : Principal;
        msg : {
        #handlerTopCanister : () -> (canisterPrincipal : Principal, nbCycles : Nat);
        #handlerUpgradeCanister : () -> (nature : CanistersKinds.CanistersKind, wasmModule : Blob);
        #handlerAddCanister : () -> (registryPrincipal : Principal, registryKind : CanistersKinds.RegistriesKind);
        #handlerCreateBucket : () -> (bucketKind : CanistersKinds.BucketsKind);
      }
    };

    system func inspect(params: inspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) return false;
        if ( params.arg.size > 200 ) return false;

        true
    };

    // ===== LIFECYCLE =====

    system func init() {
        initJobs();
    };

    system func postupgrade () {
        initJobs();
    };

    func initJobs() {
        ignore Timer.setTimer<system>(
            #seconds(0),
            func () : async () {
                handleJobs();
            }
        );
    };

    // ===== PEMISSIONS =====

    func isControllerOrCanister(principal: Principal) : Bool {
        if ( principal.isController() ) return true;

        let ?map = memCanisters.get(kind) else Runtime.trap("No canisters of type " # debug_show(kind) # " found");
        map.containsKey(principal)
    };

    // ===== HANDLERS =====

    public shared ({ caller }) func handlerTopCanister(canisterPrincipal: Principal, kind: Canisters.CanisterKind) : async Result.Result<(), Errors.Err> {
        if ( not isControllerOrCanister(caller) ) return #err(#errForbidden("[Coordinator] Unauthorized request"));

        Debug.print("[Coordinator] requesting top-up for " # canisterPrincipal.toText() # " of kind " # debug_show(kind));

        let nbCycles = switch ( kind ) {
            case (#coordinator) ();
            case (#index) Configs.toppingThresholdIndex;
            case (#registry) Configs.toppingThresholdRegistry;
            case (#bucket) Configs.toppingThresholdBuckets;
        };

        try {
            await (with cycles = nbCycles) IC.ic.deposit_cycles({ canister_id = canisterPrincipal });
            #ok
        } catch (e) {
            let msg = "[Coordinator] Error while topping bucket " # Principal.toText(canisterPrincipal) # ": " # Error.message(e);
            Debug.print(msg);
            #err(#errInterCanisterCall(msg))
        }
    };

    public shared func handlerUpgradeCanisterKind(nature : CanistersKinds.CanistersKind, wasmModule: Blob.Blob) : async () {
        // let ?canistersMap = memCanisters.get(CanistersKinds.compareCanistersKinds, #static(nature)) else Runtime.trap("No canisters of type " # debug_show(nature) # " found");

        // for ( canisterPrincipal in Map.keys(canistersMap) ) {
        //     try {
        //         await IC.ic.install_code({
        //             mode = #upgrade(?{ 
        //                 wasm_memory_persistence = ?#keep; 
        //                 skip_pre_upgrade = null; 
        //             });
        //             canister_id = canisterPrincipal;
        //             wasm_module = wasmModule;
        //             arg = to_candid((thisPrincipal));
        //             sender_canister_version = null;
        //     });                 
        //         Debug.print("[coordinator] Upgraded canister " # Principal.toText(canisterPrincipal));
        //     } catch (e) {
        //         Debug.print("[coordinator] Cannot upgrade bucket, error: " # Error.message(e));
        //     };
        // };
    };

    public shared ({ caller }) func handlerAddCanister(kind: Canisters.CanisterKind, principal: Principal) : async () {
        if ( caller.isController() == false ) {
            Runtime.trap("Caller is not the controller");
        };

        switch ( memCanisters.get(kind) ) {
            case (null) memCanisters.add(kind, Map.singleton(principal, ()));
            case (?map) map.add(principal, ());
        };
    };

    public shared func handlerCreateBucket(kind: CanistersKinds.BucketKind) : async Result.Result<Principal, Errors.Err> {
        try {
            // create bucket
            let newPrincipal =  switch (kind) {
                                    case (#bucketUsers) Principal.fromActor(await (with cycles = Configs.newBucketNbCycles) BucketUsers.BucketUsers());
                                    case (#groupsBucket) Principal.fromActor(await (with cycles = Configs.newBucketNbCycles) BucketGroups.BucketGroups());
                                };
            
            // add new bucket to map of canisters
            switch ( memory.canisters.get(CanistersKinds.compareCanistersKinds, #dynamic(canisterType)) ) {
                case (?map) map.add(newPrincipal, ());
                case (null) memory.canisters.add(CanistersKinds.compareCanistersKinds, #dynamic(canisterType), Map.singleton(newPrincipal, ()));
            };

            #ok(newPrincipal)
        } catch (e) {
            #err(#errInterCanisterCall("Cannot create canister, error: " # Error.message(e)))
        }
    };

    // ===== HELPERS =====

    public func helperSendNewIndexToIndexesRegistry({ registryPrincipal: Principal; indexPrincipal: Principal; indexKind: CanistersKinds.IndexesKind}) : async () {
        try {
            await (actor(registryPrincipal.toText()) : RegistryIndexes.RegistryIndexes).systemAddIndex(indexPrincipal, indexKind);
        } catch (e) {
            Debug.print("[coordinator] Cannot send index to IndexesRegistry, error: " # Error.message(e));
            apiErrorsRetryList.add(#errSendingIndexToIndexesRegistry({ registryPrincipal = registryPrincipal; indexPrincipal = indexPrincipal; indexKind = indexKind }));
        };
    };

    func helperSendUsersMapping({ indexPrincipal: Principal }) : async () {
        try {
            // init user mapping if no already initialized
            if ( memory.usersMapping.size() == 0 ) {
                let newPrincipal = Principal.fromActor(await (with cycles = Configs.newBucketNbCycles) BucketUsers.BucketUsers());
                memory.usersMapping := Array.tabulate<Principal>(10000, func(i) = newPrincipal);
            };

            await (actor(indexPrincipal.toText()) : IndexMain.IndexMain).systemSetUserMapping(memory.usersMapping);
            Debug.print("[coordinator] Sent users mapping to mainIndex " # Principal.toText(indexPrincipal));
        } catch (e) {
            Debug.print("[coordinator] Cannot send users mapping to MainIndex, error: " # Error.message(e));
            apiErrorsRetryList.add(#errSendUsersMappingToMainIndex({ indexPrincipal = indexPrincipal }));
        };
    };

    func handleJobs() : async () {
        let errors = apiErrorsRetryList.values();
        apiErrorsRetryList.clear();

        for ( err in errors ) {
            switch (err) {
                case(#errSendingIndexToIndexesRegistry(params)) await helperSendNewIndexToIndexesRegistry(params);
                case(#errSendUsersMappingToMainIndex(params))   await helperSendUsersMapping(params);
            };
        };
    };
};