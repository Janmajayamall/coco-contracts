#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

MarketRouter=$(spit_abi MarketRouter)
OracleFactory=$(spit_abi OracleFactory)
Oracle=$(spit_abi Oracle)
MemeToken=$(spit_abi MemeToken)
OracleHelper=$(spit_abi OracleHelper)
TokenDistributor=$(spit_abi TokenDistributor)