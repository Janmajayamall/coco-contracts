// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GroupProxy {

    address internal singleton;

    constructor(address _singleton) {
        singleton = _singleton;
    }

    fallback() external {
       assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
       }
    }
}