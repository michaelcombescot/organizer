import { type Job } "../../models/Job";
import { type Result } "mo:core/Result";

module {
  public func handlerJobs(job: Job) : async Result<(), Text> {
    switch (job) {
      case(#adminJob(a)) {
        #ok;
      };
      case(_) #ok;
      // Add cases for different job types here
    };
  };
}