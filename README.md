### Rationnal

This is a scaffold, you can use it as a baseline to create whatever you want.
It's a solid base to have gloal search, infinite data, authentification, and centralized topping (via the factory).

### App architecture

#### Different flavors of canisters

This is a multi canisters architecture, Naturally, we will work with several specialized canisters, sorted by kind.
Each kind can be found in backend/shared/Canisters.mo module, and each new kind should be declared here.

Kind are sorted in two main categories: #static and #dynamic.

#static canisters are the one which are not created by the factory.
It can be due to two things:
- only one of the kind must exists at anytime (here it's the factory)
- there may be severals of the same kind (same actor, same wasm) and they are the one handling the discovery of canisters from the frontend
  (here it's the registryIndexes)

Then, for the dynamic ones, there is 2 subcategories: #orderedByHash and #orderedByTime.

#orderedByHash: the canisters the application will need to find from a hash of a text/principal.
For exemple, the bucketUsers canister store users data. At the beginning, we only have a single one. When the canisters memory will be filled up,
we will need to create a second one.
The goal, for scaling, is to be able to split fairly among both bucketUsers all users, identified by principals.
To know where is the data for a specific principal, we hash the principal, and we find the right bucket in a ring with vnodes with the hash as an index.
This logic willm be the same for global search buckets, where we will split the data (like name/email etc) evenly splitted among existing canisters.

#orderedByTime: canisters where data don't need to be evenly splitted, and the order of creation is the index in the ring.
ex: You have a blog, each article take memory, when the bucket is full, you simply create a new one, you don't care about distribution,
    you just need more storage when the precedent is full

#### How all of this works together

First, a little recap of the responsbility of each kind of canisters:
- the Factory create new buckets, and top up all canisters in the app automatically via a job. It's capital that it have a LOT of cycles avaialbles at all time.
- the RegistryIndexes is the only visible canister from the frontend. We may have several RegistryIndexes, but they must be declared in the icp.yml as new canisters
  (RegistryIndexes, RegistryIndexes1, ...). Should not need a second one ever except if you have dozens of millions of users, a single call per connection, no data.
  Main goal is to make all IndexMain discoverable by the frontend. 
- the IndexMain is the routing canister. It can give to the frontend adresses of any other canister of interest. It can also be used as a middleman for
  more complicated architectures where buckets are automatically created.
- the BucketUsers: storage of users data (name, email, and whatever you'll need for your app). It's your responsability to split it/create a new one if the
  memory/compute becomes a bottleneck.
- the searchIndexes: storage of all indexes for global search (think index, like a normal db, find a user by name etc). Same as the BucketUsers, your *
  responsability to split it if needed.

The normal workflow:
Launch the network:
```
icp network start -e local
```
You create all necessary canisters
```
./admin/local/initApp.sh
```
You start the frontend in dev mod
```
npm run dev --prefix frontend
```