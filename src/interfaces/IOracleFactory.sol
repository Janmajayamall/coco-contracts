// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracleFactory {
    event OracleCreated(address indexed oracle);

    function createOracle(
        address delegate,
        address manager,
        address _tokenC, 
        bool _isActive, 
        uint32 _feeNumerator, 
        uint32 _feeDenominator,
        uint16 _donEscalationLimit, 
        uint32 _expireBufferBlocks, 
        uint32 _donBufferBlocks, 
        uint32 _resolutionBufferBlocks
    ) external;
}