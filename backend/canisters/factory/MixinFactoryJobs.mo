import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Error "mo:core/Error";
import { type Result } "mo:core/Result";
import { type CanisterKind; type Mapping } "../../shared/Canisters";
import { type Job } "../../shared/Job";
import { type HandlerErr } "../../shared/Errors";
import { type ActorUpdateMapping } "../../shared/Interfaces";

mixin({
  mappingToPublic: () -> Mapping;
}) {
  func executeJob(job: Job) : async Result<(), HandlerErr> {
    switch (job) {
      case (#jobFactory(j)) {
        switch (j) {
          case (#sendMappingTo(to)) {
            let canister = actor(to.toText()) : ActorUpdateMapping;

            try {
              switch ( await canister.handlerUpdateMapping(mappingToPublic()) ) {
                case (#ok(())) #ok;
                case (#err(e)) #err(e);
              };
            } catch e {
              #err(#errInterCanisterCall("Failed to save mapping: " # e.message()))
            }
          };
        };
      };
      case (_) {
        #err(#errJobExec("Unknown job type"));
      };
    };
  };
}