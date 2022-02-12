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

    mapping(bytes32 => address) public override creators;
    mapping(bytes32 => StateDetails) public override stateDetails;
    mapping(bytes32 => MarketDetails) public override marketDetails;
    mapping(bytes32 => Reserves) public override outcomeReserves;
    mapping(bytes32 => StakesInfo) public stakesInfo;
    mapping(bytes32 => uint256) public stakes;

    address public override collateralToken;
    GlobalConfig public globalConfig;
    address public override manager; 
    mapping(address => uint) cReserves;

    modifier isAuthenticated() {
        address _manager = manager;
        if (msg.sender != _manager && _manger != address(0)) revert UnAuthenticated();
    }

    constructor() {
        // Oracle is intended to be used as an singleton.
        // Thus setting manager as address(1) makes
        // this contract without proxy unusable.
        manager = address(1);
    }

    function atMarketFunded(bytes32 marketIdentifier) internal view returns (bool) {
        StateDetails memory _details = stateDetails[marketIdentifier];
        if (!(
            _details.stage == uint8(Stages.MarketFunded) 
            && block.timestamp < _details.expiresAt
        )) revert MarketPeriodExpired();
    }

    function atMarketClosed(bytes32 marketIdentifier) internal returns (uint8){
        StateDetails memory _stateDetails = stateDetails[marketIdentifier];    
        if (_stateDetails.stage != uint8(Stages.MarketClosed)){
            if(
               block.timestamp >= _stateDetails.donBufferEndsAt
               && (
                   _stateDetails.stage != uint8(Stages.MarketResolve) 
                   || block.timestamp >= _stateDetails.resolutionBufferEndsAt
                )
            )
            {
                // Set outcome by expiry  
                StakesInfo memory _stakesInfo = stakesInfo[marketIdentifier];
                if (_stakesInfo.staker0 == address(0) && _stakesInfo.staker1 == address(0)){
                    Reserves memory _reserves = outcomeReserves[marketIdentifier];
                    if (_reserves.reserve0 < _reserves.reserve1){
                        _stateDetails.outcome = 0;
                    }else if (_reserves.reserve1 < _reserves.reserve0){
                        _stateDetails.outcome = 1;
                    }else {
                        _stateDetails.outcome = 2;
                    }
                }else{
                    _stateDetails.outcome = _stakesInfo.lastOutcomeStaked;
                }
                _stateDetails.stage = uint8(Stages.MarketClosed);
                stateDetails[marketIdentifier] = _stateDetails;
                return _stateDetails.outcome; 
            }else {
                revert MarketNotResolved();
            }           
        }
        return _stateDetails.outcome;
    }

    function getOutcomeTokenIds(
        bytes32 marketIdentifier
    ) internal view returns (uint256, uint256) {
        return (
            uint256(keccak256(abi.encode('O1', marketIdentifier))),
            uint256(keccak256(abi.encode('O1', marketIdentifier)))
        );
    }

    function getStakingIds(
        bytes32 marketIdentifier, 
        address _of
    ) public view returns (
        bytes32 sId0,
        bytes32 sId1
    ) {
        sId0 = keccak256(abi.encodePacked('S0', marketIdentifier, _of));
        sId1 = keccak256(abi.encodePacked('S1', marketIdentifier, _of));
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

    function createMarket(
        bytes32 marketIdentifier,
        address creator,
        address challenger,
        uint256 fundingAmount,
        uint256 amount0,
        uint256 amount1
    ) external {
        if (creators[marketIdentifier] != address(0)) revert MarketExists();

        address tokenC = collateralToken;
        uint256 tAmount = getBalance(tokenC) - cReserves[tokenC];

        if (
            tAmount - (amount0 + amount1) != fundingAmount
        ) revert CreateMarketAmountsMismatch();

        if (
            fundingAmount == 0 
            || amount0 == 0
            || amount1 == 0
        ) revert ZeroAmount();

        // distribute tokens
        (uint token0Id, uint token1Id) = getOutcomeTokenIds(marketIdentifier);
        _mint(address(this), token0Id, tAmount, '');
        _mint(address(this), token1Id, tAmount, '');
        _transfer(address(this), creator, token1Id, amount1);
        _transfer(address(this), challenger, token0Id, amount0);

        // set reserves
        Reserves memory _reserves;
        _reserves.reserve0 = fundingAmount;
        _reserves.reserve1 = fundingAmount;
        outcomeReserves[marketIdentifier] = _reserves;
        
        // market details
        GlobalConfig memory _globalConfig = globalConfig;
        if (_globalConfig.isActive == false) revert GroupInActive();
        MarketDetails memory _marketDetails;
        _marketDetails.tokenC = tokenC;
        _marketDetails.fee = _globalConfig.fee;
        marketDetails[marketIdentifier] = _marketDetails;

        // state details
        StateDetails memory _stateDetails;
        _stateDetails.expiresAt = uint32(block.timestamp) + _globalConfig.expireBuffer;
        _stateDetails.donBufferEndsAt = uint32(block.timestamp) + _globalConfig.expireBuffer + _globalConfig.donBuffer;
        _stateDetails.resolutionBufferEndsAt = uint32(block.timestamp) + _stateDetails.donBufferEndsAt + _globalConfig.resolutionBuffer;
        _stateDetails.donBuffer = _globalConfig.donBuffer;
        _stateDetails.resolutionBuffer = _globalConfig.resolutionBuffer;
        _stateDetails.donEscalationLimit = _globalConfig.donEscalationLimit;
        _stateDetails.outcome = 2;
        _stateDetails.stage = uint8(Stages.MarketFunded);
        stateDetails[marketIdentifier] = _stateDetails;

        creators[marketIdentifier] = creator;

        MarketCreated(marketIdentifier, creator);
    }

    function buy(uint amount0, uint amount1, address to, bytes32 marketIdentifier) external override {
        atMarketFunded(marketIdentifier);

        Reserves memory _reserves = outcomeReserves[marketIdentifier];
        (uint token0Id, uint token1Id) = getOutcomeTokenIds(marketIdentifier);

        address tokenC = marketDetails[marketIdentifier].tokenC;
        uint amount = IERC20(tokenC).balanceOf(address(this)) - cReserves[tokenC];
        cReserves[tokenC] += amount;

        // buy outcome tokens
        _mint(address(this), token0Id, amount, '');
        _mint(address(this), token1Id, amount, '');

        // transfer outcome tokens
        _transfer(address(this), to, token0Id, amount0);
        _transfer(address(this), to, token1Id, amount1);

        uint _reserve0New = (_reserves.reserve0 + amount) - amount0;
        uint _reserve1New = (_reserves.reserve1 + amount) - amount1;
        if (
            (_reserves.reserve0*_reserves.reserve1) <= (_reserve0New*_reserve1New)
        ) revert BuyFPMMInvarianceViolated();

        _reserves.reserve0 = _reserve0New;
        _reserves.reserve1 = _reserve1New;

        outcomeReserves[marketIdentifier] = _reserves;

        emit OutcomeBought(marketIdentifier, to, amount, amount0, amount1);
    } 

    function sell(uint amount, address to, bytes32 marketIdentifier) external override {
        atMarketFunded(marketIdentifier);

        // transfer optimistically
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).transfer(to, amount);
        cReserves[tokenC] -= amount;

        Reserves memory _reserves = outcomeReserves[marketIdentifier];
        (uint token0Id, uint token1Id) = getOutcomeTokenIds(marketIdentifier);

        // check transferred outcome tokens
        uint balance0 = balanceOf(address(this), token0Id);
        uint balance1 = balanceOf(address(this), token1Id);
        uint amount0 = balance0 - _reserves.reserve0;
        uint amount1 = balance1 - _reserves.reserve1;

        // burn outcome tokens
        _burn(address(this), token0Id, amount);
        _burn(address(this), token1Id, amount);

        // update outcomeReserves 
        uint _reserve0New = (_reserves.reserve0 + amount0) - amount;
        uint _reserve1New = (_reserves.reserve1 + amount1) - amount;
        if (
            (_reserves.reserve0*_reserves.reserve1) <= (_reserve0New*_reserve1New)
        ) revert SellFPMMInvarianceViolated();

        _reserves.reserve0 = _reserve0New;
        _reserves.reserve1 = _reserve1New;
        outcomeReserves[marketIdentifier] = _reserves;

        emit OutcomeSold(marketIdentifier, to, amount, amount0, amount1);
    }

    function stakeOutcome(uint8 _for, bytes32 marketIdentifier, address to) external override {
        StateDetails memory _stateDetails = stateDetails[marketIdentifier];

        if (
            !((
                _stateDetails.stage == uint8(Stages.MarketBuffer) ||
                block.timestamp >= _stateDetails.expiresAt
            ) && 
            block.timestamp < _stateDetails.donBufferEndsAt)
        ) revert MarketBufferPeriodExpired();

        require(_for < 2);

        address tokenC = marketDetails[marketIdentifier].tokenC;
        uint amount = getBalance(tokenC) - cReserves[tokenC];
        cReserves[tokenC] += amount;

        // update stakes
        (bytes32 sId0, bytes32 sId1) = getStakingIds(marketIdentifier, to);
        StakesInfo memory _stakesInfo = stakesInfo[marketIdentifier];
        if (_for == 0){
            stakes[sId0] += amount;
            _stakesInfo.reserve0 += amount;
            _stakesInfo.staker0 = to;
            _stakesInfo.lastOutcomeStaked = 0;
        }else {
            stakes[sId1] += amount;
            _stakesInfo.reserve1 += amount;
            _stakesInfo.staker1 = to;
            _stakesInfo.lastOutcomeStaked = 1;
        }
        require(_stakesInfo.lastAmountStaked * 2 <= amount && amount != 0);
        _stakesInfo.lastAmountStaked = amount;
        stakesInfo[marketIdentifier] = _stakesInfo;
        
        // escalation limit
        if (_stateDetails.donEscalationCount + 1 < _stateDetails.donEscalationLimit){
            _stateDetails.donBufferEndsAt = uint32(block.timestamp) + _stateDetails.donBuffer;
            _stateDetails.stage = uint8(Stages.MarketBuffer);
        }else{
            _stateDetails.resolutionBufferEndsAt = uint32(block.timestamp)+ _stateDetails.resolutionBuffer;
            _stateDetails.stage = uint8(Stages.MarketResolve);
        }
        _stateDetails.donEscalationCount += 1;
        stateDetails[marketIdentifier] = _stateDetails;

        emit OutcomeStaked(marketIdentifier, to, amount, _for);
    }

    function redeemWins(bytes32 marketIdentifier, uint8 tokenIndex, address to) external override {
        uint8 outcome = atMarketClosed(marketIdentifier);
        if (tokenIndex > 1) revert InvalidTokenIndex();

        // get & burn token amount transferred
        uint256 tokenAmount;
        (uint token0Id, uint token1Id) = getOutcomeTokenIds(marketIdentifier);
        Reserves memory _reserves = outcomeReserves[marketIdentifier];
        if (tokenIndex == 0){
            tokenAmount = balanceOf(address(this), token0Id) - _reserves.reserve0;
            _burn(address(this), token0Id, tokenAmount);
        }else {    
            tokenAmount = balanceOf(address(this), token1Id) - _reserves.reserve1;
            _burn(address(this), token1Id, tokenAmount);
        }

        if (outcome == 2){
            tokenAmount = tokenAmount/2;
        }else if (outcome != tokenIndex){
            tokenAmount = 0;
        }

        // transfer win amount
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).transfer(to, tokenAmount);
        cReserves[tokenC] -= tokenAmount;

        emit WinningRedeemed(marketIdentifier, to);
    }

    function redeemStake(bytes32 marketIdentifier, address to) external override {
        uint8 outcome = atMarketClosed(marketIdentifier);

        (bytes32 sId0, bytes32 sId1) = getStakingIds(marketIdentifier, to);
        uint256 winAmount;
        if (outcome == 2){
            winAmount = stakes[sId0];
            winAmount += stakes[sId1];
            stakes[sId0] = 0;
            stakes[sId1] = 0;
        }else {
            StakesInfo memory _stakesInfo = stakesInfo[marketIdentifier];
            if (outcome == 0)   { 
                winAmount = stakes[sId0];
                stakes[sId0] = 0;

                if (
                    _stakesInfo.staker0 == to 
                    || _stakesInfo.staker0 == address(0)
                ){
                    winAmount += _stakesInfo.reserve1;
                    _stakesInfo.reserve1 = 0;
                    stakesInfo[marketIdentifier] = _stakesInfo;
                }
            }else {
                winAmount = stakes[sId1];
                stakes[sId1] = 0;

                if (
                    _stakesInfo.staker1 == to 
                    || _stakesInfo.staker1 == address(0)
                ){
                    winAmount += _stakesInfo.reserve0;
                    _stakesInfo.reserve0 = 0;
                    stakesInfo[marketIdentifier] = _stakesInfo;
                }
            }
        }

        // transfer win amount
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).transfer(to, winAmount);
        cReserves[tokenC] -= winAmount;

        emit StakedRedeemed(marketIdentifier, to);
    }

    function setOutcome(uint8 outcome, bytes32 marketIdentifier) external override {
        if (msg.sender != manager) revert UnAuthenticated();
        if (outcome > 2) revert InvalidOutcome();
        
        StateDetails memory _stateDetails = stateDetails[marketIdentifier];
        if (!(
            _stateDetails.stage == uint8(Stages.MarketResolve)
            && block.timestamp < _stateDetails.resolutionBufferEndsAt
        )) revert MarketResolutionPeriodExpired();

        uint256 fee;
        MarketDetails memory _marketDetails = marketDetails[marketIdentifier];
        if (outcome != 2 && _marketDetails.fee != 0){
            StakesInfo memory _stakesInfo = stakesInfo[marketIdentifier];
            if (outcome == 0) {
                fee = (_stakesInfo.reserve1 * _marketDetails.fee) / ONE;
                _stakesInfo.reserve1 -= fee;
            }
            if (outcome == 1) {
                fee = (_stakesInfo.reserve0 * _marketDetails.fee) / ONE;
                _stakesInfo.reserve0 -= fee;
            }
            stakesInfo[marketIdentifier] = _stakesInfo;
        }

        _stateDetails.outcome = outcome;
        _stateDetails.stage = uint8(Stages.MarketClosed);
        stateDetails[marketIdentifier] = _stateDetails;

        // transfer fee
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).safeTransfer(msg.sender, fee);
        cReserves[tokenC] -= fee;

        emit OutcomeSet(marketIdentifier);
    }

    function claimOutcomeReserves(bytes32 marketIdentifier) external override {
        atMarketClosed(marketIdentifier);

        address _creator = creators[marketIdentifier];

        Reserves memory _reserves = outcomeReserves[marketIdentifier];
        (uint token0Id, uint token1Id) = getOutcomeTokenIds(marketIdentifier);

        _transfer(address(this), _creator, token0Id, _reserves.reserve0);
        _transfer(address(this), _creator, token1Id, _reserves.reserve1);

        _reserves.reserve0 = 0;
        _reserves.reserve1 = 0;
        outcomeReserves[marketIdentifier] = _reserves;

        emit OutcomeReservesClaimed(marketIdentifier);
    }

    function updateMarketConfig(
        bool isActive, 
        uint32 fee,
        uint16 donEscalationLimit, 
        uint32 expireBuffer, 
        uint32 donBuffer, 
        uint32 resolutionBuffer
    ) external isAuthenticated {
        if (msg.sender != manager) revert UnAuthenticated();
        if (fee > ONE) revert InvalidFee();
        if (donEscalationLimit == 0) revert ZeroEscalationLimit();
        if (
            expireBuffer == 0
            || donBuffer == 0
            || resolutionBuffer == 0
        ) revert ZeroPeriodBuffer();


        GlobalConfig memory _globalConfig;
        _globalConfig.fee = fee;
        _globalConfig.isActive = isActive;
        _globalConfig.donEscalationLimit = donEscalationLimit;
        _globalConfig.expireBuffer = expireBuffer;
        _globalConfig.donBuffer = donBuffer;
        _globalConfig.resolutionBuffer = resolutionBuffer;
        globalConfig = _globalConfig;

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
