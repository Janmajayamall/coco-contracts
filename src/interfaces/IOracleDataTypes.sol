// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IOracleDataTypes {
    
    struct Staking {
        uint256 lastAmountStaked;
        address staker0;
        address staker1;
        uint8 lastOutcomeStaked;
    }

   enum Stages {
        MarketCreated,
        MarketFunded,
        MarketBuffer,
        MarketResolve,
        MarketClosed
    }

    struct StateDetails {
        uint32 expireAtBlock;
        uint32 donBufferEndsAtBlock;
        uint32 resolutionEndsAtBlock;
        // uint32 expireBufferBlocks; // no need of storing this
        uint32 donBufferBlocks; 
        uint32 resolutionBufferBlocks;

        uint16 donEscalationCount;
        uint16 donEscalationLimit;
        uint8 outcome;
        uint8 stage;
    }

    struct MarketDetails {
        address tokenC;
        uint32 feeNumerator;
        uint32 feeDenominator;
    }

    struct Reserves {
        uint256 reserve0;
        uint256 reserve1;
    }

    struct StakingReserves {
        uint256 reserveS0;
        uint256 reserveS1;
    }

    struct MarketConfig {
        uint32 feeNumerator;
        uint32 feeDenominator;
        uint32 expireBufferBlocks;
        uint32 donBufferBlocks;
        uint32 resolutionBufferBlocks;
        uint16 donEscalationLimit;
        bool isActive;
    }
}