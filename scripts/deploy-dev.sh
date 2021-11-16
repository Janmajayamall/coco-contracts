#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
MarketFactory=$(deploy MarketFactory "")
MarketRouter=$(deploy MarketRouter "" "$MarketFactory")
OracleMultiSig=$(deploy OracleMultiSig "" "[$ETH_FROM]" 1 10)
MemeToken=$(deploy MemeToken "")
ContractHelper=$(deploy ContractHelper helpers/)
OracleFactory=$(deploy OracleFactory "")
# export MarketFactory=$MarketFactory
# export MarketRouter=$MarketRouter
# export OracleMultiSig=$OracleMultiSig
# export MemeToken=$MemeToken
# export ETH_FROM=$ETH_FROM
# export ContractHelper=$ContractHelper

log "MarketFactory deployed at:" $MarketFactory
log "MarketRouter deployed at:" $MarketRouter
log "OracleMultiSig deployed at:" $OracleMultiSig
log "MemeToken deployed at:" $MemeToken
log "ContractHelper deployed at:" $ContractHelper
log "OracleFactory deployed at:" $OracleFactory
