### ARCHITECTURE

The heart of the application works with 5 kind of canisters:
- Factory: single canister, responsible for creating other canisters and automatic topping
- RegistryIndexes: the main link between the frontend and the backend, give the user the app indexes
- IndexMain: a dynamically created canister, used by the frontend to find specific buckets or some items creations
- BucketUsers: a dynamically created canister to store users data
- SearchIndexes: a dynamically created canister used to query data sorted by text (can be a principal, or a text field)

All Dynamically created canister are sorted in two ways:
- a simple list where each canister follow the last (think of a blog, where a canister would store articles from january, then a second articles from february etc)
- a ring with vnodes, when it's not possible to know the distribution beforehand, it's the case for BucketUsers and SearchIndexes, because BucketUsers is sorted by users Principal (random chain), and SearchIndexes is sorted by text (if I need to find the data of a user with the name "Alice", the user name beeing an index, I need a way to know that all users with a name starting by A are on bucket 1).
Canisters on a ring must, at the moment, be splitted manually. The way to do it is to split the remaining space between the index of the base canister and the next index occupied in two, create a new canister, and split the load between the base canister and the new one.

## Common behaviours

The app works thanks to two specific mixins:
- MixinCommon: it'as mainly the permission framework, each caniste rin the app knows about EVERY other canister in the app, updated dynamically and in real time when a new canister is created by the factory. it allows easy communication for intercanister calls: each canister can verify the caller is not a stranger
- MixinJobs: Allow any canister to easily handle retry when an async task fail, everything is automated. Concrete exemple: a user want to delete his account, I need to delete EVERYTHING at the same time, data, indexes etc. Indexes are in SearchIndexes canisters, data are in a BucketUsers. I need to launch jobs to all concerned indexes, and ensure that EVERY index is deleted at some point. If does not matter if it's not instant, but it's super important to be sure it will be done. in 99.99% of cases, it will be done in a matter of seconds at worst, jobs are here for the remaining 0.001%.