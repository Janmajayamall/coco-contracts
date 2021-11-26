#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
# OracleFactory=$(deploy OracleFactory)
# MemeToken=$(deploy MemeToken)
MarketRouter=$(deploy MarketRouter)

# log "OracleFactory deployed at:" $OracleFactory
# log "MemeToken deployed at:" $MemeToken
log "MarketRouter deployed at:" $MarketRouter
