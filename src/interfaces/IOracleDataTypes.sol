// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IOracleDataTypes {
    struct StakesInfo {
        uint8 lastOutcomeStaked;
        address staker0;
        address staker1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 lastAmountStaked;
    }

    struct StateDetails {
        uint32 expiresAt;
        uint32 donBufferEndsAt;
        uint32 resolutionBufferEndsAt;

        uint32 donBuffer; 
        uint32 resolutionBuffer;

        uint16 donEscalationCount;
        uint16 donEscalationLimit;
        
        uint8 outcome;
        uint8 stage;
    }

    struct MarketDetails {
        address tokenC;
        uint96 fee;
    }

    struct Reserves {
        uint256 reserve0;
        uint256 reserve1;
    }

    struct StakingReserves {
        uint256 reserveS0;
        uint256 reserveS1;
    }

    struct GlobalConfig {
        uint32 fee;
        uint32 expireBuffer;
        uint32 donBuffer;
        uint32 resolutionBuffer;
        uint16 donEscalationLimit;
        bool isActive;
    }

    enum Stages {
        MarketFunded,
        MarketBuffer,
        MarketResolve,
        MarketClosed
    }
}