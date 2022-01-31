// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OracleProxy.sol";
import "./../../lib/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "./../../lib/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

contract OracleProxyFactory {
    event OracleCreated(OracleProxy indexed oracle);

    function createSafeAndOracle(
        address safeProxyFactory,
        address safeSingleton,
        address[] memory owners,
        uint256 safeThreshold,
        address oracleSingleton,        
        address tokenC, 
        bytes calldata oracleMarketConfig
    ) public returns (OracleProxy oracleProxy) {
        // safe proxy factory
        GnosisSafeProxyFactory safeFactory = GnosisSafeProxyFactory(safeProxyFactory);
        
        // setup safe calldata (initialzer)
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

        // deploy safe proxy with singleton, initializer, and nonce
        GnosisSafeProxy safeProxy = safeFactory.createProxyWithNonce(safeSingleton, safeSetupCall, uint256(uint160(msg.sender)));

        // deploy oracle proxy
        oracleProxy = createOracleWithSafe(address(safeProxy), oracleSingleton, tokenC, oracleMarketConfig);
    }

    function createSafeAndOracleWithSenderAsOwner(
        address safeProxyFactory,
        address safeSingleton,
        uint256 safeThreshold,
        address oracleSingleton,        
        address tokenC, 
        bytes calldata oracleMarketConfig
    ) external returns (OracleProxy oracleProxy) {
        address[] memory owners = new address[](1);
        owners[0] = msg.sender;
        oracleProxy = createSafeAndOracle(safeProxyFactory, safeSingleton, owners, safeThreshold, oracleSingleton, tokenC, oracleMarketConfig);
    }

    function createOracleWithSafe(
        address safe,
        address oracleSingleton,        
        address tokenC, 
        bytes calldata oracleMarketConfig
    ) public returns (OracleProxy oracleProxy) {
        // deploy oracle
        oracleProxy = new OracleProxy(oracleSingleton);

        // setup oracle
        // update market configs
        // 0x94eb6f2f = Oracle.updateMarketConfig.selector
        bytes memory updateMarketConfigCall = bytes.concat(bytes4(0x94eb6f2f), oracleMarketConfig);
        assembly {
            if eq(call(gas(), oracleProxy, 0, add(updateMarketConfigCall, 0x20), mload(updateMarketConfigCall), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update collateral token
        // 0x29d06108 = Oracle.updateCollateralToken.selector
        bytes memory updateCollateralToken = abi.encodeWithSelector(0x29d06108, tokenC);
        assembly {
            if eq(call(gas(), oracleProxy, 0, add(updateCollateralToken, 0x20), mload(updateCollateralToken), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update manager
        // 0x58aba00f = Oracle.updateManager.selector
        bytes memory updateManagerCall = abi.encodeWithSelector(0x58aba00f,  address(safe));
        assembly {
            if eq(call(gas(), oracleProxy, 0, add(updateManagerCall, 0x20), mload(updateManagerCall), 0, 0), 0) {
                revert(0, 0)
            }
        }

        emit OracleCreated(oracleProxy);
    }

}