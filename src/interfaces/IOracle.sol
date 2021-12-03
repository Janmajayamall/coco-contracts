// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {

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

    function getOutcomeTokenIds(bytes32 marketIdentifier) external pure returns (uint,uint);
    function getReserveTokenIds(bytes32 marketIdentifier) external pure returns (uint,uint);
    function getMarketIdentifier(address _creator, bytes32 _eventIdentifier) external view returns (bytes32 marketIdentifier);
    // function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function createAndFundMarket(address _creator, bytes32 _eventIdentifier) external; 
    function buy(uint amount0, uint amount1, address to, bytes32 marketIdentifier) external;
    function sell(uint amount, address to, bytes32 marketIdentifier) external;
    function stakeOutcome(uint8 _for, bytes32 marketIdentifier) external;
    function redeemWinning(address to, bytes32 marketIdentifier) external;
    function redeemStake(bytes32 marketIdentifier) external;
    function setOutcome(uint8 outcome, bytes32 marketIdentifier) external;
    function claimOutcomeReserves(bytes32 marketIdentifier) external;

    function updateMarketConfig(
        bool _isActive, 
        uint32 _feeNumerator, 
        uint32 _feeDenominator,
        uint16 _donEscalationLimit, 
        uint32 _expireBufferBlocks, 
        uint32 _donBufferBlocks, 
        uint32 _resolutionBufferBlocks
    ) external;
    function updateCollateralToken(address token) external;
    function updateDelegate(address _delegate) external;
    function updateManager(address _manager) external;

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
