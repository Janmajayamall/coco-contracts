// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IOracle.sol';
import './interfaces/IOracleDataTypes.sol';
import './interfaces/IOracleEvents.sol';
import './interfaces/IERC20.sol';
import './ERC1155.sol';

contract Oracle is IOracle, IOracleDataTypes, IOracleEvents, ERC1155 {
    /*
        marketIdentifier = keccack256(abi.encode(creator, eventIdentifier, address(this)))
    */
    mapping(bytes32 => StateDetails) public override stateDetails;
    mapping(bytes32 => Staking) public override staking;
    mapping(bytes32 => MarketDetails) public override marketDetails;
    mapping(bytes32 => Reserves) public override outcomeReserves;
    mapping(bytes32 => StakingReserves) public override stakingReserves;
    mapping(bytes32 => address) public override creators;
    // mapping(bytes32 => bytes32) public eventIdentfiiers;

    address public override collateralToken;
    MarketConfig public marketConfig;
    mapping(address => uint) public cReserves;

    address public delegate;
    address public manager; 

    constructor(address _delegate, address _manager){
        // setup oracle
        delegate = _delegate;
        manager = _manager;
    }

    function isMarketFunded(bytes32 marketIdentifier) internal view returns (bool) {
        StateDetails memory _details = stateDetails[marketIdentifier];
        if (_details.stage == uint8(Stages.MarketFunded) && block.number < _details.expireAtBlock) return true;
        return false;
    }

    function isMarketClosed(bytes32 marketIdentifier) internal returns (bool, uint8){
        StateDetails memory _stateDetails = stateDetails[marketIdentifier];    
        if (_stateDetails.stage != uint8(Stages.MarketClosed)){
            if(
                _stateDetails.stage != uint8(Stages.MarketCreated) && 
                (
                    (_stateDetails.stage != uint8(Stages.MarketResolve) && block.number >= _stateDetails.donBufferEndsAtBlock && (_stateDetails.donBufferBlocks == 0 || _stateDetails.donEscalationLimit != 0))
                    || (block.number >=  _stateDetails.resolutionEndsAtBlock && (_stateDetails.stage == uint8(Stages.MarketResolve) || _stateDetails.donEscalationLimit == 0))
                )
            )
            {
                // Set outcome by expiry  
                Staking memory _staking = staking[marketIdentifier];
                if (_staking.staker0 == address(0) && _staking.staker1 == address(0)){
                    Reserves memory _reserves = outcomeReserves[marketIdentifier];
                    if (_reserves.reserve0 < _reserves.reserve1){
                        _stateDetails.outcome = 0;
                    }else if (_reserves.reserve1 < _reserves.reserve0){
                        _stateDetails.outcome = 1;
                    }else {
                        _stateDetails.outcome = 2;
                    }
                }else{
                    _stateDetails.outcome = _staking.lastOutcomeStaked;
                }
                _stateDetails.stage = uint8(Stages.MarketClosed);
                stateDetails[marketIdentifier] = _stateDetails;
                return (true, _stateDetails.outcome); 
            }
           return (false, 2);
        }
        return (true, _stateDetails.outcome);
    }

    function getOutcomeTokenIds(bytes32 marketIdentifier) public pure override returns (uint,uint) {
        return (
            uint256(keccak256(abi.encode(marketIdentifier, 0))),
            uint256(keccak256(abi.encode(marketIdentifier, 1)))
        );
    }
    
    function getReserveTokenIds(bytes32 marketIdentifier) public pure override returns (uint,uint){
        return (
            uint256(keccak256(abi.encode('R', marketIdentifier, 0))),
            uint256(keccak256(abi.encode('R', marketIdentifier, 1)))
        );
    }

    function getMarketIdentifier(address _creator, bytes32 _eventIdentifier) public view override returns (bytes32 marketIdentifier){
        marketIdentifier = keccak256(abi.encode(_creator, _eventIdentifier, address(this)));
    }

    function createAndFundMarket(address _creator, bytes32 _eventIdentifier) external override {
        bytes32 marketIdentifier = getMarketIdentifier(_creator, _eventIdentifier);

        require(creators[marketIdentifier] == address(0), 'Market exists');

        address tokenC = collateralToken;

        uint amount = IERC20(tokenC).balanceOf(address(this)) - cReserves[tokenC] ; // fundingAmount > 0
        cReserves[tokenC] += amount;

        (uint token0Id, uint token1Id) = getOutcomeTokenIds(marketIdentifier);

        // issue outcome tokens
        _mint(address(this), token0Id, amount, '');
        _mint(address(this), token1Id, amount, '');

        // set outcomeReserves
        Reserves memory _reserves;
        _reserves.reserve0 = amount;
        _reserves.reserve1 = amount;
        outcomeReserves[marketIdentifier] = _reserves; 

        // get market config
        MarketConfig memory _marketConfig = marketConfig;

        // set market details
        MarketDetails memory _marketDetails;
        _marketDetails.tokenC = tokenC;
        _marketDetails.feeNumerator = _marketConfig.feeNumerator;
        _marketDetails.feeDenominator = _marketConfig.feeDenominator;
        marketDetails[marketIdentifier] = _marketDetails;

        // set state details
        StateDetails memory _stateDetails;
        _stateDetails.donBufferBlocks = _marketConfig.donBufferBlocks;
        _stateDetails.resolutionBufferBlocks = _marketConfig.resolutionBufferBlocks;
        _stateDetails.donEscalationLimit = _marketConfig.donEscalationLimit;
        _stateDetails.stage = uint8(Stages.MarketFunded);
        _stateDetails.outcome = 2; // undecided outcome

        _stateDetails.expireAtBlock = uint32(block.number) + _marketConfig.expireBufferBlocks;
        _stateDetails.donBufferEndsAtBlock = _stateDetails.expireAtBlock + _stateDetails.donBufferBlocks; // pre-set buffer expiry for first buffer period
        _stateDetails.resolutionEndsAtBlock = _stateDetails.expireAtBlock + _stateDetails.resolutionBufferBlocks; // pre-set resolution expiry, in case donEscalationLimit == 0 && donBufferBlocks > 0
        stateDetails[marketIdentifier] = _stateDetails;

        // set creator & event identifier
        creators[marketIdentifier] = _creator;
        // eventIdentfiiers[marketIdentifier] = _eventIdentifier;

        require(amount > 0, 'ZERO');

        // oracle is active
        require(_marketConfig.isActive, 'Oracle inactive');

        emit MarketCreated(marketIdentifier, _creator, _eventIdentifier, amount);
    }

    function buy(uint amount0, uint amount1, address to, bytes32 marketIdentifier) external override {
        require(isMarketFunded(marketIdentifier));

        // MarketDetails memory _marketDetails = marketDetails;
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
        require((_reserves.reserve0*_reserves.reserve1) <= (_reserve0New*_reserve1New), "ERR - INV");

        _reserves.reserve0 = _reserve0New;
        _reserves.reserve1 = _reserve1New;

        outcomeReserves[marketIdentifier] = _reserves;
        emit OutcomeBought(marketIdentifier, to, amount, amount0, amount1);
    } 

    function sell(uint amount, address to, bytes32 marketIdentifier) external override {
        require(isMarketFunded(marketIdentifier));

        // transfer optimistically
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).transfer(to, amount);
        cReserves[tokenC] -= amount;

        // MarketDetails memory _marketDetails = marketDetails;
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
        require((_reserves.reserve0*_reserves.reserve1) <= (_reserve0New*_reserve1New), "ERR - INV");

        _reserves.reserve0 = _reserve0New;
        _reserves.reserve1 = _reserve1New;
        
        outcomeReserves[marketIdentifier] = _reserves;

        emit OutcomeSold(marketIdentifier, to, amount, amount0, amount1);
    }


    function stakeOutcome(uint8 _for, bytes32 marketIdentifier, address to) external override {

        StateDetails memory _stateDetails = stateDetails[marketIdentifier];
        if (_stateDetails.stage == uint8(Stages.MarketFunded) && block.number >= _stateDetails.expireAtBlock){
            _stateDetails.stage = uint8(Stages.MarketBuffer);
        }
        require(
            _stateDetails.stage == uint8(Stages.MarketBuffer) 
            && _stateDetails.donEscalationCount < _stateDetails.donEscalationLimit
            && block.number < _stateDetails.donBufferEndsAtBlock
            
        );

        require(_for < 2);

        address tokenC = marketDetails[marketIdentifier].tokenC;
        uint amount = IERC20(tokenC).balanceOf(address(this)) - cReserves[tokenC];
        cReserves[tokenC] += amount;

        (uint sToken0Id, uint sToken1Id) = getReserveTokenIds(marketIdentifier);

        StakingReserves memory _stakingReserves = stakingReserves[marketIdentifier];
        Staking memory _staking = staking[marketIdentifier];

        // update staking outcomeReserves
        if (_for == 0){
            _mint(to, sToken0Id, amount, '');
            _stakingReserves.reserveS0 += amount;
            _staking.staker0 = to;
            _staking.lastOutcomeStaked = 0;
        }
        if (_for == 1){
            _mint(to, sToken1Id, amount, '');
            _stakingReserves.reserveS1 += amount;
            _staking.staker1 = to;
            _staking.lastOutcomeStaked = 1;
        }

        // update staking info
        require(_staking.lastAmountStaked * 2 <= amount, 'DBL');
        require(amount != 0, 'ZERO');
        _staking.lastAmountStaked = amount;

        stakingReserves[marketIdentifier] = _stakingReserves;
        staking[marketIdentifier] = _staking;
        
        // escalation limit
        if (_stateDetails.donEscalationCount + 1 < _stateDetails.donEscalationLimit){
            _stateDetails.donBufferEndsAtBlock = uint32(block.number) + _stateDetails.donBufferBlocks;
        }else{
            _stateDetails.resolutionEndsAtBlock = uint32(block.number) + _stateDetails.resolutionBufferBlocks;
            _stateDetails.stage = uint8(Stages.MarketResolve);
        }
        _stateDetails.donEscalationCount += 1;
        stateDetails[marketIdentifier] = _stateDetails;

        emit OutcomeStaked(marketIdentifier, to, amount, _for);
    }


    function redeemWinning(address to, bytes32 marketIdentifier) external override {
        (bool valid, uint8 outcome) = isMarketClosed(marketIdentifier);
        require(valid);

        Reserves memory _reserves = outcomeReserves[marketIdentifier];
        (uint token0Id, uint token1Id) = getOutcomeTokenIds(marketIdentifier);

        // get amount
        uint balance0 = balanceOf(address(this), token0Id);
        uint balance1 = balanceOf(address(this), token1Id);
        uint amount0 = balance0 - _reserves.reserve0;
        uint amount1 = balance1 - _reserves.reserve1;

        // burn amount
        _burn(address(this), token0Id, amount0);
        _burn(address(this), token1Id, amount1);

        uint winAmount;
        if (outcome == 2){
            winAmount = amount0/2 + amount1/2;
        }else if (outcome == 0){
            winAmount = amount0;
        }else if (outcome == 1){
            winAmount = amount1;
        }

        // transfer win amount
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).transfer(to, winAmount);
        cReserves[tokenC] -= winAmount;

        emit WinningRedeemed(marketIdentifier, to);
    }

    function redeemStake(bytes32 marketIdentifier, address to) external override {
        (bool valid, uint8 outcome) = isMarketClosed(marketIdentifier);
        require(valid);

        (uint sToken0Id, uint sToken1Id) = getReserveTokenIds(marketIdentifier);
        uint sAmount0 = balanceOf(to, sToken0Id);
        uint sAmount1 = balanceOf(to, sToken1Id);

        // burn stake tokens
        _burn(to, sToken0Id, sAmount0);
        _burn(to, sToken1Id, sAmount1);
        
        StakingReserves memory _stakingReserves = stakingReserves[marketIdentifier];
        uint winAmount;
        if (outcome == 2){    
            winAmount = sAmount0 + sAmount1;
            _stakingReserves.reserveS0 -= sAmount0;
            _stakingReserves.reserveS1 -= sAmount1;
        }else {
            Staking memory _staking = staking[marketIdentifier];
            
            if (outcome == 0){
                _stakingReserves.reserveS0 -= sAmount0;
                winAmount = sAmount0;
                if (_staking.staker0 == to || _staking.staker0 == address(0)){
                    winAmount += _stakingReserves.reserveS1;
                    _stakingReserves.reserveS1 = 0;
                    _staking.staker0 = address(this);
                }
            }else if (outcome == 1) {
                _stakingReserves.reserveS1 -= sAmount1;
                winAmount = sAmount1;
                if (_staking.staker1 == to || _staking.staker1 == address(0)){
                    winAmount += _stakingReserves.reserveS0;
                    _stakingReserves.reserveS0 = 0;
                    _staking.staker1 = address(this);
                }
            }

            staking[marketIdentifier] = _staking;
        }
        stakingReserves[marketIdentifier] = _stakingReserves;

        // transfer win amount
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).transfer(to, winAmount);
        cReserves[tokenC] -= winAmount;

        emit StakedRedeemed(marketIdentifier, to);
    }

    function setOutcome(uint8 outcome, bytes32 marketIdentifier) external override {
        require(msg.sender == delegate);
        require(outcome < 3);
        
        StateDetails memory _stateDetails = stateDetails[marketIdentifier];
        if (_stateDetails.stage == uint8(Stages.MarketFunded) 
            && block.number >= _stateDetails.expireAtBlock
            && _stateDetails.donEscalationLimit == 0
            && _stateDetails.donBufferBlocks != 0){
            // donEscalationLimit == 0, indicates direct transition to MarketResolve after Market expiry
            // But if donBufferPeriod == 0 as well, then transition to MarketClosed after Market expiry
            _stateDetails.stage = uint8(Stages.MarketResolve);
        }
        require(_stateDetails.stage == uint8(Stages.MarketResolve) && block.number < _stateDetails.resolutionEndsAtBlock);

        MarketDetails memory _marketDetails = marketDetails[marketIdentifier];

        uint fee;
        if (outcome != 2 && _marketDetails.feeNumerator != 0){
            StakingReserves memory _stakingReserves = stakingReserves[marketIdentifier];
            if (outcome == 0) {
                fee = (_stakingReserves.reserveS1*_marketDetails.feeNumerator)/_marketDetails.feeDenominator;
                _stakingReserves.reserveS1 -= fee;
            }
            if (outcome == 1) {
                fee = (_stakingReserves.reserveS0*_marketDetails.feeNumerator)/_marketDetails.feeDenominator;
                _stakingReserves.reserveS0 -= fee;
            }
            stakingReserves[marketIdentifier] = _stakingReserves;
        }


        _stateDetails.outcome = outcome;
        _stateDetails.stage = uint8(Stages.MarketClosed);
        stateDetails[marketIdentifier] = _stateDetails;

        // transfer fee
        address tokenC = marketDetails[marketIdentifier].tokenC;
        IERC20(tokenC).transfer(msg.sender, fee);
        cReserves[tokenC] -= fee;

        emit OutcomeSet(marketIdentifier);
    }

    function claimOutcomeReserves(bytes32 marketIdentifier) external override {
        (bool valid, ) = isMarketClosed(marketIdentifier);
        require(valid);

        address _creator = creators[marketIdentifier];
        require(_creator == msg.sender);

        Reserves memory _reserves = outcomeReserves[marketIdentifier];
        (uint token0Id, uint token1Id) = getOutcomeTokenIds(marketIdentifier);

        _transfer(address(this), _creator, token0Id, _reserves.reserve0);
        _transfer(address(this), _creator, token1Id, _reserves.reserve1);

        _reserves.reserve0 = 0;
        _reserves.reserve1 = 0;
        outcomeReserves[marketIdentifier] = _reserves;

        emit OutcomeReservesClaimed(marketIdentifier);
    }

    /* 
    Note on configs - 
    1. To resolve markets to favored outcome right after market expiry, set donBufferPeriod to 0
    2. To pass on outcome decision to oracle right after market expiry, set escalation limit to 0 & donBufferBlocks > 0
    3. To resolve to last staked outcome right after hitting escalation limit, set resolutionBufferBlocks to 0
     */
    function updateMarketConfig(
        bool _isActive, 
        uint32 _feeNumerator, 
        uint32 _feeDenominator,
        uint16 _donEscalationLimit, 
        uint32 _expireBufferBlocks, 
        uint32 _donBufferBlocks, 
        uint32 _resolutionBufferBlocks
    ) external override {
        // numerator < denominator
        require(_feeNumerator < _feeDenominator);
        // _expireBufferBlocks > 0 for active trading time
        require(_expireBufferBlocks != 0);

        MarketConfig memory _marketConfig;
        _marketConfig.isActive = _isActive;
        _marketConfig.feeNumerator = _feeNumerator;
        _marketConfig.feeDenominator = _feeDenominator;
        _marketConfig.donEscalationLimit = _donEscalationLimit;
        _marketConfig.expireBufferBlocks = _expireBufferBlocks;
        _marketConfig.donBufferBlocks = _donBufferBlocks;
        _marketConfig.resolutionBufferBlocks = _resolutionBufferBlocks;
        marketConfig = _marketConfig;

        emit OracleConfigUpdated();
    }

    function updateCollateralToken(address token) external override {
        collateralToken = token;
        emit OracleConfigUpdated();
    }

    function updateDelegate(address _delegate) external override {
        require(msg.sender == delegate);
        delegate = _delegate;
        emit DelegateChanged(_delegate);
    }

    function updateManager(address _manager) external override {
        require(msg.sender == delegate);
        manager = _manager;
        emit OracleConfigUpdated();
    }
}
