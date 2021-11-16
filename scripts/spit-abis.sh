#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

MarketRouter=$(spit_abi MarketRouter)
OracleFactory=$(spit_abi OracleFactory)
OracleMarkets=$(spit_abi OracleMarkets)