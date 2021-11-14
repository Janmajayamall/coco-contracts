// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracleFactory {
    event OracleRegistered(address indexed oracle);

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
    ) external;
}