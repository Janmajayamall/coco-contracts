#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh


Group=$(spit_abi Group)
# GroupProxyFactory=$(spit_abi GroupProxyFactory)
GroupRouter=$(spit_abi GroupRouter)