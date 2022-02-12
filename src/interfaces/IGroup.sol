// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface IGroup is IERC1155 {
    function collateralToken() external view returns (address);
    function globalConfig() external view returns (
        uint32,
        uint32,
        uint32,
        uint32,
        uint16,
        bool
    );
    function outcomeReserves(bytes32 marketIdentifier) external view returns (uint256, uint256);
    function marketDetails(bytes32 marketIdentifier) external view returns (address, uint96);
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
    function stakesInfo(bytes32 marketIdentifier) external view returns (
        uint8,
        address,
        address,
        uint256,
        uint256,
        uint256
    );
    function stakes(bytes32 stakeId) external view returns (uint256);
    function creators(bytes32 marketIdentifier) external view returns (address);
    function manager() external view returns (address);

    function createMarket(
        bytes32 marketIdentifier,
        address creator,
        address challenger,
        uint256 fundingAmount,
        uint256 amount0,
        uint256 amount1
    ) external;

    function buy(uint amount0, uint amount1, address to, bytes32 marketIdentifier) external;
    function sell(uint amount, address to, bytes32 marketIdentifier) external;
    function stakeOutcome(uint8 _for, bytes32 marketIdentifier, address to) external;
    function redeemWins(bytes32 marketIdentifier, uint8 tokenIndex, address to) external;
    function redeemStake(bytes32 marketIdentifier, address to) external;
    function setOutcome(uint8 outcome, bytes32 marketIdentifier) external;
    function claimOutcomeReserves(bytes32 marketIdentifier) external;
    function updateMarketConfig(
        bool isActive, 
        uint32 fee,
        uint16 donEscalationLimit, 
        uint32 expireBuffer, 
        uint32 donBuffer, 
        uint32 resolutionBuffer
    ) external;
    function updateCollateralToken(address token) external;
    function updateManager(address _manager) external;
}
