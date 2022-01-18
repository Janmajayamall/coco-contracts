// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OracleProxy.sol";

contract OracleProxyFactory {

    function createProxy(address _singleton, bytes memory data) external returns (OracleProxy _proxy) {
        _proxy = new OracleProxy(_singleton);
        assembly {
            if eq(call(gas(), _proxy, 0,add(data, 0x20), mload(data), 0, 0), 0) {
                revert(0, 0)
            }
        }
    }

}