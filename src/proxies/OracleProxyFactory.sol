// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OracleProxy.sol";
import "./../../lib/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";

contract OracleProxyFactory {

    function createOracle(
        address _oracleSingleton,
        address _safeSingleton,        
        address _tokenC, 
        bool _isActive, 
        uint32 _feeNumerator, 
        uint32 _feeDenominator,
        uint16 _donEscalationLimit, 
        uint32 _expireBufferBlocks, 
        uint32 _donBufferBlocks, 
        uint32 _resolutionBufferBlocks,
        address[] memory owners,
        uint256 threshold
    ) external returns (OracleProxy _proxy) {
        // deploy gnosis safe
        GnosisSafeProxy _safeProxy = new GnosisSafeProxy(_safeSingleton);
        
        // setup safe
        bytes memory safeSetupCall = abi.encodeWithSignature(
                "setup(address[] calldata,uint256,address,bytes calldata,address,address,uint256,address payable)",
                owners,
                threshold,
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
        bytes memory updateMarketConfigCall = abi.encodeWithSignature(
                "updateMarketConfig(bool,uint32,uint32,uint16,uint32,uint32,uint32)",
                _isActive, 
                _feeNumerator, 
                _feeDenominator,
                _donEscalationLimit, 
                _expireBufferBlocks, 
                _donBufferBlocks, 
                _resolutionBufferBlocks
            );
        assembly {
            if eq(call(gas(), _oracleProxy, 0, add(updateMarketConfigCall, 0x20), mload(updateMarketConfigCall), 0, 0), 0) {
                revert(0, 0)
            }
        }
    }

}