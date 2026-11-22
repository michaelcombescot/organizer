import { type Job } "../../../shared/Job";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import { type ErrHandler } "../../../shared/Errors";
import { type Result } "mo:core/Result";
import Map "mo:core/Map";
import { type ActorSearchIndexes } "../../../shared/Interfaces";

mixin({
  thisPrincipal: Principal;
  memKnownCanisters: Map.Map<Principal, Nat>;
  createActorSearchIndexesFor: (text: Text) -> Result<ActorSearchIndexes, ErrHandler>;
}) {
  func executeJob(job: Job) : async Result<(), ErrHandler> {
    switch (job) {
      case (#jobBucketUsers(j)) {
        switch (j) {
          case (#updateUserIndex(d)) {
            let #ok actorSearch = createActorSearchIndexesFor(d.key) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerSaveEntry({kind = #reqUsers(d.kind); owner = d.owner; key = d.key})) {
                case (#ok(())) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to save entry"))
            }
          };
          case (#removeUserIndex(d)) {
            let #ok actorSearch = createActorSearchIndexesFor(d.key) else return #err(#errNotFound("Failed to create actor search index for caller"));

            try {
              switch ( await actorSearch.handlerLiberateEntry({kind = #reqUsers(d.kind); key = d.key})) {
                case (#ok(result)) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to liberate entry"))
            }
          };
        };
      };
      case (_) {
        #err(#errSystem("Unknown job type"));
      };
    };
  };
}