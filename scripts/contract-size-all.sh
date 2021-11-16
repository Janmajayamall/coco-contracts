#!/usr/bin/env bash

set -eo pipefail

. $(dirname $0)/common.sh

DIRECTORY=.
for file in $DIRECTORY/src/*.sol; do 
        echo "------------------"
        fileName=$(basename ${file} .sol)
        contract_size=$(contract_size ${fileName})
        echo "Contract Name: ${fileName}"
        echo "Contract Size: ${contract_size} bytes"
        echo "$(( 24576 - ${contract_size} )) bytes left to reach the smart contract size limit of 24576 bytes."
        echo "------------------"
done
