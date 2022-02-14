// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IGroupDataTypes {
    struct MarketStakeInfo {
        address staker0;
        address staker1;
        uint256 lastAmountStaked;
    }
    struct MarketReserves {
        uint256 reserve0;
        uint256 reserve1;
    }

    struct MarketState {
        uint64 donBufferEndsAt;
        uint64 resolutionBufferEndsAt;
        uint64 donBuffer; 
        uint64 resolutionBuffer;
    }

    struct MarketDetails {
        address tokenC;
        uint64 fee;
        uint8 outcome;
    }

    struct GlobalConfig {
        uint64 fee;
        uint64 donBuffer;
        uint64 resolutionBuffer;
        bool isActive;
    }
}