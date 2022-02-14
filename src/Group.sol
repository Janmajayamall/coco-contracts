// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IGroup.sol';
import './interfaces/IGroupDataTypes.sol';
import './interfaces/IGroupEvents.sol';
import './interfaces/IGroupErrors.sol';
import './interfaces/IERC20.sol';
import './Group_ERC1155.sol';
import './Group_Singleton.sol';
import './libraries/Transfers.sol';

contract Group is Group_Singleton, Group_ERC1155, IGroup, IGroupDataTypes, IGroupEvents, IGroupErrors {

    using Transfers for IERC20;

    uint256 internal constant ONE = 1e18;
    string internal constant S_ID = 'S_Group_v1';

    mapping(bytes32 => MarketState) public marketStates;
    mapping(bytes32 => MarketDetails) public marketDetails;
    mapping(bytes32 => MarketReserves) public override marketReserves;
    mapping(bytes32 => MarketStakeInfo) public override marketStakeInfo;
    mapping(bytes32 => uint256) public stakes; // maps stakedId to stake

    GlobalConfig public override globalConfig;
    uint256 public donReservesLimit;
    address public override collateralToken;
    mapping(address => uint256) cReserves;
    address public override manager; 

    modifier isAuthenticated() {
        address _manager = manager;
        if (msg.sender != _manager && _manager != address(0)) revert UnAuthenticated();
        _;
    }

    constructor() {
        // Oracle is intended to be used as an singleton.
        // Thus setting manager as address(1) makes
        // this contract without proxy unusable.
        manager = address(1);
    }

    function getStakingIds(
        bytes32 marketIdentifier, 
        address _of
    ) public pure returns (
        bytes32 sId0,
        bytes32 sId1
    ) {
        sId0 = keccak256(abi.encodePacked(S_ID, marketIdentifier, _of));
        sId1 = keccak256(abi.encodePacked(S_ID, marketIdentifier, _of));
    }

    function getBalance(
        address token
    ) internal view returns (uint256 balance){
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(
                IERC20.balanceOf.selector, 
                address(this)
            )
        );
        if (!success || data.length != 32) revert BalanceError();
        balance= abi.decode(data, (uint256));
    }

    function nextState(
        bytes32 marketIdentifier,
        MarketReserves memory _marketReserves,
        MarketState memory _marketState
    ) internal {
        if (
            donReservesLimit <= (_marketReserves.reserve0 + _marketReserves.reserve1)
        ){
            _marketState.resolutionBufferEndsAt = _marketState.resolutionBuffer + block.timestamp;
            _marketState.donBufferEndsAt = 0;
        }else {
            _marketState.donBufferEndsAt = _marketState.donBuffer + block.timestamp;
            _marketState.resolutionBufferEndsAt = 0;
        }
        marketStates[marketIdentifier] = _marketState;
    }

    function createMarket(
        bytes32 marketIdentifier,
        address creator,
        address challenger,
        uint256 amount0,
        uint256 amount1
    ) external override {
        if (marketStates[marketIdentifier].donBuffer != 0) revert MarketExists();

        address tokenC = collateralToken;
        uint256 tokenBalance = getBalance(tokenC);
        uint256 tAmount = tokenBalance - cReserves[tokenC];
        cReserves[tokenC] = tokenBalance;

        if (
            tAmount == (amount0 + amount1)
        ) revert CreateMarketAmountsMismatch();

        if (
            amount0 == 0 ||
            amount1 == 0
        ) revert ZeroAmount();

        // amount1 is creator's initial stake AND amount 0 is challenger's stake.
        // Therefore, amount0 is a challenge to amount1 and should be double of amount1
        if ( amount1 * 2 > amount0 ) revert AmountNotDouble();

        // get staking ids for marketIdentifier
        (, bytes32 creatorS1Id ) = getStakingIds(marketIdentifier, creator);
        (bytes32 challengerS0Id, ) = getStakingIds(marketIdentifier, challenger);

        // update stakes
        stakes[creatorS1Id] = amount1;
        stakes[challengerS0Id] = amount0;

        // update market reserves
        MarketReserves memory reserves = MarketReserves({
            reserve0: amount0,
            reserve1: amount1
        });
        marketReserves[marketIdentifier] = reserves;

        // update market stakes info
        MarketStakeInfo memory stakeInfo = MarketStakeInfo({
            lastOutcomeStaked: 0,
            staker0: challenger,
            staker1: creator,
            lastAmountStaked: amount0
        });
        marketStakeInfo[marketIdentifier] = stakeInfo;

        // update market details
        GlobalConfig memory _globalConfig = globalConfig;
        MarketDetails memory details = MarketDetails({
            tokenC: tokenC,
            fee: _globalConfig.fee
        });

        // update market state
        MarketState memory marketState = MarketState({
            donBuffer: _globalConfig.donBuffer,
            resolutionBuffer: _globalConfig.resolutionBuffer,
            dontBufferEndsAt: 0,
            resolutionBufferEndsAt: 0,
            outcome: 2
        });

        nextState(marketIdentifier, reserves, marketState);

        if (_globalConfig.isActive == false) revert GroupInActive();

        emit MarketCreated(marketIdentifier, creator);
    }

    function challenge(
        uint8 _for, 
        bytes32 marketIdentifier, 
        address to
    ) external override {
        MarketState memory marketState = marketStates[marketIdentifier];

        if (marketState.donBufferEndsAt <= block.timestamp || marketState.donBufferEndsAt == 0) revert(); // TODO throw error of challenge period expired
        if (_for > 1) revert(); // TODO invalid outcome _for

        address tokenC = marketDetails[marketIdentifier].tokenC;
        uint256 tokenBalance = getBalance(tokenC);
        uint amount = tokenBalance - cReserves[tokenC];
        cReserves[tokenC] = tokenBalance;

        // update stakes
        (bytes32 sId0, bytes32 sId1) = getStakingIds(marketIdentifier, to);
        MarketStakeInfo memory stakeInfo = marketStakeInfo[marketIdentifier];
        MarketReserves memory reserves = marketReserves[marketIdentifier];
        if (_for == 0){
            stakes[sId0] += amount;
            stakeInfo.staker0 = to;
            stakeInfo.lastOutcomeStaked = 0;
            reserves.reserve0 += amount;
        }else {
            stakes[sId1] += amount;
            stakeInfo.staker1 = to;
            stakeInfo.lastOutcomeStaked = 1;
            reserves.reserve1 += amount;
        }
        if (stakeInfo.lastAmountStaked * 2 > amount) revert AmountNotDouble();
        stakeInfo.lastAmountStaked = amount;
        marketStakeInfo[marketIdentifier] = stakeInfo;
        marketReserves[marketIdentifier] = reserves;

        // check whether limit has been reached
        nextState(marketIdentifier, reserves, marketState);

        emit ChallangedSuccessfully(marketIdentifier, to, amount, _for);
    }

    function redeem(bytes32 marketIdentifier, address to) external override {
        MarketState memory marketState = marketStates[marketIdentifier];

        if (
            block.timestamp < marketState.resolutionBufferEndsAt
            || marketState.resolutionBufferEndsAt == 0
        ) revert();

        (bytes32 sId0, bytes32 sId1) = getStakingIds(marketIdentifier, to);
        uint256 winAmount;
        MarketReserves memory reserves = marketReserves[marketIdentifier];
        if (marketState.outcome == 2){
            winAmount = stakes[sId0];
            reserves.reserve0 -= winAmount;

            uint256 s1 = stakes[sId1];
            winAmount += s1;
            reserves.reserve1 -= s1;

            stakes[sId0] = 0;
            stakes[sId1] = 0;
        }else {
            MarketStakeInfo memory stakeInfo = marketStakeInfo[marketIdentifier];
            if (marketState.outcome == 0){
                winAmount = stakes[sId0];
                reserves.reserve0 -= winAmount;
                stakes[sId0] = 0;
                
                if (
                    stakeInfo.staker0 == to 
                    || stakeInfo.staker0 == address(0)
                ){
                    winAmount += reserves.reserve1;
                    reserves.reserve1 = 0;
                }
            }else if (marketState.outcome == 1){
                winAmount = stakes[sId1];
                reserves.reserve1 -= winAmount;
                stakes[sId1] = 0;

                if (
                    stakeInfo.staker1 == to 
                    || stakeInfo.staker1 == address(0)
                ){
                    winAmount += reserves.reserve0;
                    reserves.reserve0 = 0;
                }
            }
        }
        marketReserves[marketIdentifier] = reserves;
        
        // transfer win amount
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).safeTransfer(to, winAmount);
        cReserves[tokenC] -= winAmount;

        emit Redeemed(marketIdentifier, to);
    }


    function setOutcome(uint8 outcome, bytes32 marketIdentifier) external override isAuthenticated {
        if (outcome > 2) revert InvalidOutcome();
        
        MarketState memory marketState = marketStates[marketIdentifier];
        if (
            block.timestamp >= marketState.resolutionBufferEndsAt
            || marketState.resolutionBufferEndsAt == 0
        ) revert();

        uint256 fee;
        MarketDetails memory details = marketDetails[marketIdentifier];
        if (outcome != 2 && details.fee != 0){
            MarketReserves memory reserves = marketReserves[marketIdentifier];
            if (outcome == 0) {
                fee = (reserves.reserve1 * details.fee) / ONE;
                reserves.reserve1 -= fee;
            }
            if (outcome == 1) {
                fee = (reserves.reserve0 * details.fee) / ONE;
                reserves.reserve0 -= fee;
            }
            marketReserves[marketIdentifier] = reserves;
        }

        marketState.outcome = outcome;
        marketState.donBufferEndsAt = 0;
        marketState.resolutionBufferEndsAt = block.timestamp - 1;
        marketStates[marketIdentifier] = marketState;

        // transfer fee
        address tokenC = details[marketIdentifier].tokenC;
        IERC20(tokenC).safeTransfer(msg.sender, fee);
        cReserves[tokenC] -= fee;

        emit OutcomeSet(marketIdentifier);
    }

    function updateGlobalConfig(
        bool isActive, 
        uint32 fee,
        uint32 donBuffer, 
        uint32 resolutionBuffer
    ) external isAuthenticated override {
        if (msg.sender != manager) revert UnAuthenticated();
        if (fee > ONE) revert InvalidFee();
        if (
            donBuffer == 0 || resolutionBuffer == 0
        ) revert ZeroPeriodBuffer();


        GlobalConfig memory _globalConfig = GlobalConfig({
            fee: fee,
            donBuffer: donBuffer,
            resolutionBuffer: resolutionBuffer,
            isActive: isActive
        });
        globalConfig = _globalConfig;

        emit ConfigUpdated();
    }

    function updateDonReservesLimit(uint256 newLimit) external isAuthenticated {
        donReservesLimit = newLimit;
        emit ConfigUpdated();
    }

    function updateCollateralToken(address token) external override isAuthenticated {
        collateralToken = token;
        emit ConfigUpdated();
    }

    function updateManager(address to) external override isAuthenticated {
        address _manager = manager;
        if (msg.sender != _manager && _manager != address(0)) revert UnAuthenticated();
        if (to == address(0)) revert ZeroManagerAddress();
        manager = to;
        emit ConfigUpdated();
    }
}
