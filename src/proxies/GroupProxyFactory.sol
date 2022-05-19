// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GroupProxy.sol";
import "safe-contracts/proxies/GnosisSafeProxy.sol";
import "safe-contracts/proxies/GnosisSafeProxyFactory.sol";

contract GroupProxyFactory {
    event GroupCreated(GroupProxy indexed group);

    function createSafeAndGroup(
        address safeProxyFactory,
        address safeSingleton,
        address[] memory owners,
        uint256 safeThreshold,
        address groupSingleton,        
        address tokenC, 
        uint256 donReservesLimit,
        bytes calldata groupMarketConfig
    ) public returns (GroupProxy groupProxy) {
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

        // deploy group proxy
        groupProxy = createGroupWithManager(address(safeProxy), groupSingleton, tokenC, donReservesLimit, groupMarketConfig);
    }

    function createGroupWithManager(
        address manager,
        address groupSingleton,        
        address tokenC, 
        uint256 donReservesLimit,
        bytes calldata groupGlobalConfig
    ) public returns (GroupProxy groupProxy) {
        // deploy group
        groupProxy = new GroupProxy(groupSingleton);

        // setup group
        // update market configs
        // c0a7fdc5 = group.updateGlobalConfig.selector
        bytes memory updateGlobalConfigCall = bytes.concat(bytes4(0xc0a7fdc5), groupGlobalConfig);
        assembly {
            if eq(call(gas(), groupProxy, 0, add(updateGlobalConfigCall, 0x20), mload(updateGlobalConfigCall), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update donReservesLimit
        // 48438dac = group.updateDonReservesLimit.selector 
        bytes memory updateDonReservesLimit = abi.encodeWithSelector(0x48438dac, donReservesLimit);
        assembly {
            if eq(call(gas(), groupProxy, 0, add(updateDonReservesLimit, 0x20), mload(updateDonReservesLimit), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update collateral token
        // 0x29d06108 = group.updateCollateralToken.selector
        bytes memory updateCollateralToken = abi.encodeWithSelector(0x29d06108, tokenC);
        assembly {
            if eq(call(gas(), groupProxy, 0, add(updateCollateralToken, 0x20), mload(updateCollateralToken), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update manager
        // 0x58aba00f = group.updateManager.selector
        bytes memory updateManagerCall = abi.encodeWithSelector(0x58aba00f,  manager);
        assembly {
            if eq(call(gas(), groupProxy, 0, add(updateManagerCall, 0x20), mload(updateManagerCall), 0, 0), 0) {
                revert(0, 0)
            }
        }

        emit GroupCreated(groupProxy);
    }

    function createSafeAndGroupWithSenderAsOwner(
        address safeProxyFactory,
        address safeSingleton,
        uint256 safeThreshold,
        address groupSingleton,        
        address tokenC, 
        uint256 donReservesLimit,
        bytes calldata groupMarketConfig
    ) external returns (GroupProxy groupProxy) {
        address[] memory owners = new address[](1);
        owners[0] = msg.sender;
        groupProxy = createSafeAndGroup(safeProxyFactory, safeSingleton, owners, safeThreshold, groupSingleton, tokenC, donReservesLimit, groupMarketConfig);
    }
}