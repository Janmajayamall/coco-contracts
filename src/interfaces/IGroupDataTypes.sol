// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IGroupDataTypes {
    struct MarketStakeInfo {
        uint8 lastOutcomeStaked;
        address staker0;
        address staker1;
        uint256 lastAmountStaked;
    }
    struct MarketReserves {
        uint256 reserve0;
        uint256 reserve1;
    }

    struct MarketState {
        uint32 donBufferEndsAt;
        uint32 resolutionBufferEndsAt;
        uint32 donBuffer; 
        uint32 resolutionBuffer;
        uint8 outcome;
    }

    struct MarketDetails {
        address tokenC;
        uint32 fee;
    }

    struct GlobalConfig {
        uint32 fee;
        uint32 donBuffer;
        uint32 resolutionBuffer;
        bool isActive;
    }
}