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
          case (#updateUserIndex(d)) {
            let ?actorSearch = createActorSearchIndexesFor(d.key) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerSaveEntry({kind = #reqUsers(#usersByPrincipal); owner = d.owner; key = d.key})) {
                case (#ok(())) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to save entry"))
            }
          };
          case (#removeUserIndex(d)) {
            let ?actorSearch = createActorSearchIndexesFor(d.key) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerLiberateEntry({kind = #reqUsers(#usersByPrincipal); key = d.key})) {
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