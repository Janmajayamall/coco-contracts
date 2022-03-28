// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IGroup {
    function collateralToken() external view returns (address);
    function globalConfig() external view returns (
        uint64,
        uint64,
        uint64,
        bool
    );
    function donReservesLimit() external returns (uint256);
    function cReserves(address token) external returns (uint256);
    function manager() external view returns (address);
    function getStakingIds(
        bytes32 marketIdentifier, 
        address _of
    ) external view returns (bytes32, bytes32);

    function marketStates(bytes32 marketIdentifier) external returns (uint64, uint64, uint64, uint64);
    function marketDetails(bytes32 marketIdentifier) external returns (address, uint64, uint8);
    function marketReserves(bytes32 marketIdentifier) external returns (uint256, uint256);
    function marketStakeInfo(bytes32 marketIdentifier) external returns (address, address, uint256);
    function stakes(bytes32 stakeId) external returns (uint256);

    function createMarket(
        bytes32 marketIdentifier,
        address creator,
        address challenger,
        uint256 amount0,
        uint256 amount1
    ) external;
    function challenge(uint8 _for, bytes32 marketIdentifier, address to) external;
    function redeem(bytes32 marketIdentifier, address to) external;
    function setOutcome(uint8 outcome, bytes32 marketIdentifier) external;
    function updateGlobalConfig(
        bool isActive, 
        uint64 fee,
        uint64 donBuffer, 
        uint64 resolutionBuffer
    ) external;
    function updateDonReservesLimit(uint256 newLimit) external;
    function updateCollateralToken(address token) external;
    function updateManager(address to) external;
}
