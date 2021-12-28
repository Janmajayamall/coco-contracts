// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracleEvents {
    event MarketCreated(bytes32 indexed marketIdentifier, address creator, bytes32 eventIdentifier, uint fundingAmount);
    event OutcomeBought(bytes32 indexed marketIdentifier, address by, uint amountC, uint amount0, uint amount1);
    event OutcomeSold(bytes32 indexed marketIdentifier, address by, uint amountC, uint amount0, uint amount1);
    event OutcomeStaked(bytes32 indexed marketIdentifier, address by, uint amount, uint8 outcome);
    event OutcomeSet(bytes32 indexed marketIdentifier);
    event OutcomeReservesClaimed(bytes32 indexed marketIdentifier);
    event WinningRedeemed(bytes32 indexed marketIdentifier, address by);
    event StakedRedeemed(bytes32 indexed marketIdentifier, address by);
    event OracleConfigUpdated();
    event DelegateChanged(address indexed to);
}