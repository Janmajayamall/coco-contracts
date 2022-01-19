// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OracleProxy.sol";
import "./../../lib/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";

contract OracleProxyFactory {

    function createOracle(
        address oracleSingleton,
        address safeSingleton,        
        address tokenC, 
        bytes calldata oracleMarketConfig,
        address[] calldata owners,
        uint256 safeThreshold
    ) external returns (OracleProxy _oracleProxy) {
        // deploy gnosis safe
        GnosisSafeProxy _safeProxy = new GnosisSafeProxy(safeSingleton);

        // setup safe
        // 0xb63e800d = GnosisSafe.setup.selector
        bytes memory safeSetupCall = abi.encodeWithSelector(
            0xb63e800d, 
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

        // deploy oracle
        _oracleProxy = new OracleProxy(oracleSingleton);

        // setup oracle
        // update market configs
        // 0x94eb6f2f = Oracle.updateMarketConfig.selector
        bytes memory updateMarketConfigCall = bytes.concat(bytes4(0x94eb6f2f), oracleMarketConfig);
        assembly {
            if eq(call(gas(), _oracleProxy, 0, add(updateMarketConfigCall, 0x20), mload(updateMarketConfigCall), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update collateral token
        // 0x29d06108 = Oracle.updateCollateralToken.selector
        bytes memory updateCollateralToken = abi.encodeWithSelector(0x29d06108, tokenC);
        assembly {
            if eq(call(gas(), _oracleProxy, 0, add(updateCollateralToken, 0x20), mload(updateCollateralToken), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update manager
        // 0x58aba00f = Oracle.updateManager.selector
        bytes memory updateManagerCall = abi.encodeWithSelector(0x58aba00f,  address(_safeProxy));
        assembly {
            if eq(call(gas(), _oracleProxy, 0, add(updateManagerCall, 0x20), mload(updateManagerCall), 0, 0), 0) {
                revert(0, 0)
            }
        }
    }

}