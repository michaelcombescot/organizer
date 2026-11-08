import { type Job } "../../../shared/Job";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import { type HandlerErr } "../../../shared/Errors";
import { type Result } "mo:core/Result";
import Map "mo:core/Map";
import { type ActorSearchIndexes } "../../../shared/Interfaces";

mixin({
  thisPrincipal: Principal;
  memKnownCanisters: Map.Map<Principal, Nat>;
  createActorSearchIndexesFor: (text: Text) -> ?ActorSearchIndexes;
}) {
  func thisIndex () : Result<Nat, HandlerErr> {
    let ?index = memKnownCanisters.get(thisPrincipal) else return #err(#errNotFound("Failed to retrieve index for this canister"));
    #ok(index);
  };

  func executeJob(job: Job) : async Result<(), HandlerErr> {
    switch (job) {
      case (#jobBucketUsers(j)) {
        switch (j) {
          case (#addPrincipalSearch(d)) {
            let ?actorSearch = createActorSearchIndexesFor(d.newPrincipal.toText()) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerSaveEntry({kind = #usersByPrincipal; loc = #perPrincipal(d.loc); key = d.newPrincipal.toText()})) {
                case (#ok(result)) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to save entry"))
            }
          };
          case (#removePrincipalSearch(d)) {
            let ?actorSearch = createActorSearchIndexesFor(d.oldPrincipal.toText()) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerLiberateEntry({kind = #usersByPrincipal; key = d.oldPrincipal.toText()})) {
                case (#ok(result)) #ok;
                case (#err(e)) #err(e);
              };
              
            } catch e {
              #err(#errInterCanisterCall("Failed to liberate entry"))
            }
          };
          case (#addNameSearch(d)) {
            let ?actorSearch = createActorSearchIndexesFor(d.newName) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerSaveEntry({kind = #usersByName; loc = #perPrincipal(d.loc); key = d.newName})) {
                case (#ok(result)) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to save entry"))
            }
          };
          case (#removeOldNameSearch(d)) {
            let ?actorSearch = createActorSearchIndexesFor(d.oldName) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerLiberateEntry({kind = #usersByName; key = d.oldName})) {
                case (#ok(result)) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to liberate entry"))
            }
          };
          case (#addEmailSearch(d)) {
            let ?actorSearch = createActorSearchIndexesFor(d.newEmail) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerSaveEntry({kind = #usersByEmail; loc = #perPrincipal(d.loc); key = d.newEmail})) {
                case (#ok(result)) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to save entry"))
            }
          };
          case (#removeOldEmailSearch(d)) {
            let ?actorSearch = createActorSearchIndexesFor(d.oldEmail) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerLiberateEntry({kind = #usersByEmail; key = d.oldEmail})) {
                case (#ok(result)) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to liberate entry"))
            }
          };
        };
      };
    };
  };
}