#!/usr/bin/env bash

IDENTITY_NAME="local"
NETWORK="local"

icp build SearchIndexes

WASM=".icp/cache/artifacts/SearchIndexes"

PRINCIPALS=$(icp canister call Factory handlerGetCanistersOfKind \
  '(variant { dynamic = variant { orderedByHash = variant { searchIndexes } } })' \
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