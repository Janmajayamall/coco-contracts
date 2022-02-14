// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGroupEvents {
    event MarketCreated(bytes32 indexed marketIdentifier, address creator);
    event Challanged(bytes32 indexed marketIdentifier, address by, uint amount, uint8 outcome);
    event Redeemed(bytes32 indexed marketIdentifier, address by);
    event OutcomeSet(bytes32 indexed marketIdentifier);
    event ConfigUpdated();
}