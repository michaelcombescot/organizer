#!/bin/bash

# we need to create:
# 1. The factory canister
# 2. The registryIndexes canister
# 3. The admin canister
# 4. Create a new index dynamically (call to factory)
# 5. make the factory known to the admin and the RegistryIndexes > they will need to know about it to retrieve the updated mapping, if needed
# 6. make the admin and the registryIndexes known to the factory

# Create a new identity if needed
# icp identity new local --storage plaintext

# ===== CREATE STATIC CANISTERS =====
icp deploy Admin -e local --identity local
icp deploy Factory -e local --identity local
icp deploy RegistryIndexes -e local --identity local

ADMIN_ID=$(icp canister status Admin -e local --id-only)
FACTORY_ID=$(icp canister status Factory -e local --id-only)
REGISTRY_INDEXES_ID=$(icp canister status RegistryIndexes -e local --id-only)

echo "_________________________"


icp canister call Admin systemAddStaticCanisters \
  '(vec { record { variant { factory } ; principal "'"$FACTORY_ID"'" } })' \
  -e local --identity local

icp canister call Admin systemAddStaticCanisters \
  '(vec { record { variant { registryIndexes } ; principal "'"$REGISTRY_INDEXES_ID"'" } })' \
  -e local --identity local

echo "--------------------------"

# ===== CREATE A SINGLE INDEX TO BEGIN WITH =====

# icp canister call $FACTORY_ID createIndex '(record { name = "IndexMain" })' -e local

# icp deploy IndexMain -e local
# INDEX_MAIN_ID=$(icp canister id IndexMain)

# ===== CREATE A SINGLE SEARCHINDEXES =====

# icp deploy SearchIndexes -e local
# SEARCH_INDEXES_ID=$(icp canister id SearchIndexes)

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