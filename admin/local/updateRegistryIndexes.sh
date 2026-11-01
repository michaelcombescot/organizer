#!/usr/bin/env bash

IDENTITY_NAME="local"
NETWORK="local"

icp build RegistryIndexes

WASM=".icp/cache/artifacts/RegistryIndexes"

PRINCIPALS=$(icp canister call Factory handlerGetCanistersOfKind \
  '(variant { static = variant { registryIndexes } })' \
  -e "$NETWORK" --identity "$IDENTITY_NAME" \
  | grep -oP 'principal "\K[^"]+')

for PRINCIPAL in $PRINCIPALS; do
  echo "Upgrading canister: $PRINCIPAL"
  icp canister install "$PRINCIPAL" \
    --wasm "$WASM" \
    --mode upgrade \
    --identity "$IDENTITY_NAME" \
    -e "$NETWORK"
done