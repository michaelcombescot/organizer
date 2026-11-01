#!/bin/bash

# we need to create:
# 1. The factory canister
# 2. The registryIndexes canister
# 4. Create a new index dynamically (call to factory)
# 5. make the registryIndexes known to the factory

IDENTITY_NAME="local"
NETWORK="local"

# Create a new identity if needed
# icp identity new local --storage plaintext

# ===== CREATE STATIC CANISTERS =====

echo "===== CREATE STATIC CANISTERS ====="
CURRENT_ID=$(icp identity principal --identity "$IDENTITY_NAME")

# then the factory canister
icp deploy Factory -e "$NETWORK" --identity "$IDENTITY_NAME" --cycles 20_000_000_000_000

FACTORY_ID=$(icp canister status Factory -e "$NETWORK" --id-only)

# then the registryIndexes canister
icp deploy RegistryIndexes -e "$NETWORK" --identity "$IDENTITY_NAME" --cycles 2_000_000_000_000

REGISTRY_INDEXES_ID=$(icp canister status RegistryIndexes -e "$NETWORK" --id-only)

echo "===== STATIC CANISTERS DEPLOYED ====="

# ===== UPDATE FACTORY MAPPING =====
# The factory is the garant of the application full canister mapping.
# It will be interogated by everyone, admin included, to retrieve the full mapping of canisters.

echo " ===== MAKE STATIC CANISTERS KNOWN EACH OTHERS ====="

echo "--- Make factory known everyone"

icp canister call Factory handlerAddStaticCanisters \
  '(vec { record { variant { registryIndexes } ; principal "'"$REGISTRY_INDEXES_ID"'" } })' \
  -e "$NETWORK" \
  --identity "$IDENTITY_NAME"

echo "--- Make every static canister know the Factory"

icp canister call RegistryIndexes handlerAddStaticCanisters \
  '(vec { record { variant { factory }; principal "'"$FACTORY_ID"'" } })' \
  -e "$NETWORK" \
  --identity "$IDENTITY_NAME"

# ===== CREATE BUCKETS =====
# for the application to work, we need to have at least one IndexMain, one SearchIndexes, and one BucketUsers

echo "===== CREATE BUCKETS ====="

echo "--- Create SearchIndexes"

icp canister call Factory handlerCreateOrderedByHashCanister \
  '(variant { searchIndexes } , 0 )' \
  -e "$NETWORK" \
  --identity "$IDENTITY_NAME"

echo "--- Create BucketUsers"

icp canister call Factory handlerCreateOrderedByHashCanister \
  '(variant { bucketUsers } , 0)' \
  -e "$NETWORK" \
  --identity "$IDENTITY_NAME"

echo "--- Create IndexMain"

icp canister call Factory handlerCreateOrderedByTimeCanister \
  '(variant { indexMain })' \
  -e "$NETWORK" \
  --identity "$IDENTITY_NAME"

echo "===== BUCKETS CREATED ====="

echo "===== DEPLOYMENT COMPLETED ====="