#!/usr/bin/env bash

# Deploy Contract
truffle migrate --reset --network rinkeby

# Verify Contract on Etherscan
truffle run verify swapico --network rinkeby --license SPDX-License-Identifier

# Flatten Contract
./node_modules/.bin/truffle-flattener contracts/swapico_flat.sol > flats/swapico_flat.sol