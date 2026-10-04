

### App schema

The admin canister is fixed, responsability is to:
- create new canisters
- handle topping for cycles for all app canisters (job to check canister status for all canisters like all hours), then send it => remove the need to have a timer in each and every canister for that.
- trigger update for all dynamically created canisters -> send a job to the worker to do that (worker should be compiled with the updated version of all other canisters, then updated, then the job should be send, otherwise the wasms won't be up to date)
- send a job when a new canister is created to
  -> all indexes which need to have a mapping of full app
  -> all RegistryIndexes if the new canister is an index

the registry index is fixed responsability is to:
- make all indexes known to the frontend

All other canisters are dynamically created

Indexes responsabilities are:
- knowing all the app topology (same level of knowledge as the admin canister)
- give to the frontend (once known via the registryIndexes) the adresses of buckets of interest. For exemple
  -> if a user want to create a new group, the index must give him the adress of a canister with enough space to create the new group.
     One way to do this: an index ask a new bucket of each kind and keep it as the current bucket in memory, do the call to create itself, and keep a counter to know if the number of group is under the limit
- The precedent point imply that the index is a mandatory relay for any action which may lead to the creation of a new bucket (here create a new user, create a new group)

worker responsabilities are:
- execute sequentially all jobs given to it, we will have a ring of workers to achieve that (selecting a random entry in an array of known workers)

bucket users/groups:
- store data
- handle via direct frontend call any mono canister update, otherwise send multi canister call to a worker

### Difficulties:

Inter bucket comunication necessiting synchronized updates (like adding a group to a user, -> need a call to the user bucket and a call to the group bucket )
Solution ===> if one bucket is concerned => update the bucket diectly
              if several buckets must be synched, pass by the worker

The only thing is, buckets need to know all workers at any time, so how ?
1) sync all buckets each time a worker is added => will do, the other solution is super annoying


### Init

- create admin
- create indexRegistry
- add index registry principal to admin
- launch admin init endpoint (create an index, a worker, a user bucket, a group bucket)



##### REFLEXION

créer user => index call directement le bucket.

créer group => check group canister de l'index => index groups => name -> identifier
                                                => identifier => bucket


