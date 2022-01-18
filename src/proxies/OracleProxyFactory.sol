// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OracleProxy.sol";
// import "./../../lib/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";

contract OracleProxyFactory {

    function createOracle(
        address oracleSingleton,
        address safeSingleton,        
        address tokenC, 
        bytes calldata oracleMarketConfig,
        address[] calldata owners,
        uint256 safeThreshold
    ) external returns (OracleProxy) {
        // deploy gnosis safe
        // GnosisSafeProxy _safeProxy = new GnosisSafeProxy(_safeSingleton);
        address _safeProxy = address(0);
        
        // setup safe
        bytes memory safeSetupCall = abi.encodeWithSignature(
                "setup(address[] calldata,uint256,address,bytes calldata,address,address,uint256,address payable)",
                owners,
                safeThreshold,
                address(0),
                0,
                0,
                0,
                0,
                0
            );
        assembly {
            if eq(call(gas(), _safeProxy, 0, add(safeSetupCall, 0x20), mload(safeSetupCall), 0, 0), 0) {
                revert(0, 0)
            }
        }


        OracleProxy _oracleProxy = new OracleProxy(_oracleSingleton);

        // setup oracle
        bytes memory updateManagerCall = abi.encodeWithSignature(
                "updateManager(address)",
                address(_safeProxy)
            );
        assembly {
            if eq(call(gas(), _oracleProxy, 0, add(updateManagerCall, 0x20), mload(updateManagerCall), 0, 0), 0) {
                revert(0, 0)
            }
        }
        
        // 0x94eb6f2f = Oracle.updateMarketConfig.selector
        bytes memory updateMarketConfigCall = bytes.concat(0x94eb6f2f, oracleMarketConfig);
        assembly {
            if eq(call(gas(), _oracleProxy, 0, add(updateMarketConfigCall, 0x20), mload(updateMarketConfigCall), 0, 0), 0) {
                revert(0, 0)
            }
        }
    }

}