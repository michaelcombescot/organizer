#!/bin/bash

# we need to create:
# 1. The factory canister
# 2. The registryIndexes canister
# 3. The admin canister
# 4. Create a new index dynamically (call to factory)
# 5. make the factory known to the admin and the RegistryIndexes > they will need to know about it to retrieve the updated mapping, if needed
# 6. make the admin and the registryIndexes known to the factory


# dfx deploy registryIndexes
# dfx generate registryIndexes

# # then we do a call to add the registry to the coordinator
# # for information, synthax if the param is a record is: (record { todosRegistryPrincipal = principal \"$(dfx canister id organizerTodosRegistry)\" })
# dfx deploy coordinator \
#   --argument "(principal \"$(dfx canister id registryIndexes)\")"

# dfx generate coordinator
# dfx ledger fabricate-cycles --canister coordinator # add cycles to the coordinator, will be needed to create indexes and buckets

# # then we generate all necessary code for the dynamically created canisters
# dfx generate indexMain

# dfx generate bucketGroups
# dfx generate bucketUsers

# # deploy internet identity
# dfx deploy internet_identity
# dfx generate internet_identity

# # deploy frontend
# # dfx deploy organizerFrontend

# # create a first set of indexes
# dfx canister call coordinator handlerAddIndex '(variant { indexMain })'