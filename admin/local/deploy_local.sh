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

echo "===== CREATE STATIC CANISTERS ====="
CURRENT_ID=$(icp identity principal --identity local)

# create the admin canister first
icp deploy Admin -e local --identity local --controller $CURRENT_ID --cycles 2_000_000_000_000

ADMIN_ID=$(icp canister status Admin -e local --id-only)

# then the factory canister
icp deploy Factory -e local --identity local --controller $CURRENT_ID --controller $ADMIN_ID --cycles 20_000_000_000_000

FACTORY_ID=$(icp canister status Factory -e local --id-only)

# then the registryIndexes canister
icp deploy RegistryIndexes -e local --identity local --controller $CURRENT_ID --controller $ADMIN_ID --cycles 2_000_000_000_000

REGISTRY_INDEXES_ID=$(icp canister status RegistryIndexes -e local --id-only)

echo "===== STATIC CANISTERS DEPLOYED ====="

# ===== UPDATE FACTORY MAPPING =====
# The factory is the garant of the application full canister mapping.
# It will be interogated by everyone, admin included, to retrieve the full mapping of canisters.

echo " ===== MAKE FACTORY KNOW EVERYONE ====="

icp canister call Factory systemAddStaticCanisters \
  '(vec { record { variant { admin } ; principal "'"$ADMIN_ID"'" } })' \
  -e local \
  --identity local


icp canister call Factory systemAddStaticCanisters \
  '(vec { record { variant { registryIndexes } ; principal "'"$REGISTRY_INDEXES_ID"'" } })' \
  -e local \
  --identity local

echo "===== FACTORY MAPPING UPDATED ====="

# ===== CREATE BUCKETS =====
# for the application to work, we need to have at least one IndexMain, one SearchIndexes, and one BucketUsers

echo "===== CREATE BUCKETS ====="

echo "--- Create IndexMain"
icp canister call Factory handlerCreateOrderedByTimeCanister \
  '(variant { indexMain })' \
  -e local \
  --identity local

echo "--- Create SearchIndexes"
icp canister call Factory handlerCreateOrderedByHashCanister \
  '(variant { searchIndexes } , 0 )' \
  -e local \
  --identity local

echo "--- Create BucketUsers"
icp canister call Factory handlerCreateOrderedByHashCanister \
  '(variant { bucketUsers } , 0)' \
  -e local \
  --identity local

echo "===== BUCKETS CREATED ====="

echo "===== DEPLOYMENT COMPLETE ====="