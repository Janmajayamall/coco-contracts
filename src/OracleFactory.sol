// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IOracleFactory.sol';
import './Oracle.sol';

contract OracleFactory is IOracleFactory {
    function createOracle(
        address delegate,
        address manager,
        address _tokenC, 
        bool _isActive, 
        uint8 _feeNumerator, 
        uint8 _feeDenominator,
        uint16 _donEscalationLimit, 
        uint32 _expireBufferBlocks, 
        uint32 _donBufferBlocks, 
        uint32 _resolutionBufferBlocks
    ) external override {
        address oracle = address(new Oracle(delegate, manager));

        Oracle(oracle).updateCollateralToken(_tokenC);
        Oracle(oracle).updateMarketConfig(
            _isActive, 
            _feeNumerator, 
            _feeDenominator,
            _donEscalationLimit, 
            _expireBufferBlocks, 
            _donBufferBlocks, 
            _resolutionBufferBlocks
        );

        emit OracleCreated(oracle);
    }
}