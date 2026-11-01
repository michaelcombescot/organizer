#!/usr/bin/env bash

IDENTITY_NAME="local"
NETWORK="local"

icp build Factory

WASM=".icp/cache/artifacts/Factory"

PRINCIPALS=$(icp canister call Factory handlerGetCanistersOfKind \
  '(variant { static = variant { factory } })' \
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