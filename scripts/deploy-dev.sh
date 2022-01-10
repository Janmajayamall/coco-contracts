#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
OracleFactory=$(deploy OracleFactory)
MarketRouter=$(deploy MarketRouter)

log "OracleFactory deployed at:" $OracleFactory
log "MarketRouter deployed at:" $MarketRouter
