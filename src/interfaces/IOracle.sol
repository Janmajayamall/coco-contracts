// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IOracle {
    function getOutcomeTokenIds(bytes32 marketIdentifier) external pure returns (uint,uint);
    function getReserveTokenIds(bytes32 marketIdentifier) external pure returns (uint,uint);
    function getMarketIdentifier(address _creator, bytes32 _eventIdentifier) external view returns (bytes32 marketIdentifier);
    function collateralToken() external view returns (address);
    function outcomeReserves(bytes32 marketIdentifier) external view returns (uint256, uint256);
    function marketDetails(bytes32 marketIdentifier) external view returns (address, uint32, uint32);
    function stateDetails(bytes32 marketIdentifier) external view returns (
        uint32,
        uint32,
        uint32,
        uint32,
        uint32,
        uint16,
        uint16,
        uint8,
        uint8
    );
    function staking(bytes32 marketIdentifier) external view returns (uint256, address, address, uint8);
    function stakingReserves(bytes32 marketIdentifier) external view returns (uint256, uint256);
    function creators(bytes32 marketIdentifier) external view returns (address);
    // function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function createAndFundMarket(address _creator, bytes32 _eventIdentifier) external; 
    function buy(uint amount0, uint amount1, address to, bytes32 marketIdentifier) external;
    function sell(uint amount, address to, bytes32 marketIdentifier) external;
    function stakeOutcome(uint8 _for, bytes32 marketIdentifier, address to) external;
    function redeemWinning(address to, bytes32 marketIdentifier) external;
    function redeemStake(bytes32 marketIdentifier, address to) external;
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
}
