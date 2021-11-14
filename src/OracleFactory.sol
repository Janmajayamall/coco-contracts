// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IOracleFactory.sol';
import './OracleMarkets.sol';

contract OracleFactory is IOracleFactory {
    function createOracle(
        address delegate,
        address _tokenC, 
        bool _isActive, 
        uint8 _feeNumerator, 
        uint8 _feeDenominator,
        uint16 _donEscalationLimit, 
        uint32 _expireBufferBlocks, 
        uint32 _donBufferBlocks, 
        uint32 _resolutionBufferBlocks
    ) external override {
        address oracle = address(new OracleMarkets(delegate));

        OracleMarkets(oracle).updateCollateralToken(_tokenC);
        OracleMarkets(oracle).updateMarketConfig(
            _isActive, 
            _feeNumerator, 
            _feeDenominator,
            _donEscalationLimit, 
            _expireBufferBlocks, 
            _donBufferBlocks, 
            _resolutionBufferBlocks
        );

        emit OracleRegistered(oracle);
    }
}