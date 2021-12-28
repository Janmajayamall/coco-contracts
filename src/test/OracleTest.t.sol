// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../Oracle.sol";
import "./../MemeToken.sol";
import "./../interfaces/IOracle.sol";
import "./utils/Hevm.sol";
import "./../libraries/Math.sol";
import "./utils/OracleTestHelpers.sol";
import "./utils/Actor.sol";

contract OracleTest is OracleTestHelpers {

	OracleConfig oracleConfig;
	address oracle;
	address tokenC;
    uint fundAmount = 10*10**18;

    bytes32 eventIdentifier = keccak256('default');

    address actor1;

    function setOracleConfig() public {
        // setup default oracle confing 
		oracleConfig.tokenC = tokenC;
		oracleConfig.feeNumerator = 10;
		oracleConfig.feeDenominator = 100;
    	oracleConfig.expireBufferBlocks = 100;
		oracleConfig.donBufferBlocks = 100;
		oracleConfig.resolutionBufferBlocks = 100;
		oracleConfig.donEscalationLimit = 10;
		oracleConfig.isActive = true;
    }

    function deployOracle() public {
        oracle = address(new Oracle(address(this), address(this)));
        Oracle(oracle).updateCollateralToken(tokenC);
        Oracle(oracle).updateMarketConfig(
            oracleConfig.isActive, 
            oracleConfig.feeNumerator, 
            oracleConfig.feeDenominator, 
            oracleConfig.donEscalationLimit, 
            oracleConfig.expireBufferBlocks, 
            oracleConfig.donBufferBlocks, 
            oracleConfig.resolutionBufferBlocks
        );
    }

    function deployActors() public {
        actor1 = address(new Actor());
    }

    function prepRandomMarket() public returns (address _oracle, bytes32 _marketIdentifier){
        _oracle = oracle;
        bytes32 _eventIdentifier = keccak256(abi.encode(block.timestamp));
        _marketIdentifier = getMarketIdentifier(_oracle, address(this), _eventIdentifier);
        createAndFundMarket(oracle, address(this), _eventIdentifier, 10*10**18);
    }

}

contract OracleTest_StageCreated is OracleTest {
    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();
        deployActors();
    }

    function _createAndFundMarket() internal {
        address _oracle = oracle;
        IERC20(tokenC).transfer(_oracle, 10*10**18);
        Oracle(_oracle).createAndFundMarket(address(this), keccak256('default'));
    }

    function test_check_createAndFundMarket() public {
        _createAndFundMarket();

        bytes32 _marketIdentifier = getMarketIdentifier(oracle, address(this), eventIdentifier);
        address _oracle = oracle;

        // checks
        checkStage(_oracle, _marketIdentifier, 1);
        checkReserves(_oracle, _marketIdentifier, 10*10**18, 10*10**18);

        MarketDetails memory _marketDetails;
        _marketDetails.tokenC = tokenC;
        _marketDetails.feeNumerator = oracleConfig.feeNumerator;
        _marketDetails.feeDenominator = oracleConfig.feeDenominator;
        checkMarketDetails(_oracle, _marketIdentifier, _marketDetails);

        checkDonBufferEndsAtBlock(_oracle, _marketIdentifier, block.number + oracleConfig.expireBufferBlocks + oracleConfig.donBufferBlocks);
        checkExpireAtBlock(_oracle, _marketIdentifier, block.number + oracleConfig.expireBufferBlocks);
        checkResolutionEndsAtBlock(_oracle, _marketIdentifier, block.number + oracleConfig.expireBufferBlocks + oracleConfig.resolutionBufferBlocks);
        checkEscalationCount(_oracle, _marketIdentifier, 0);
    }

    function test_gas_createAndFundMarket() public {
        _createAndFundMarket();
    }   
}

contract OracleTest_StageFunded is OracleTest {

    bytes32 marketIdentifier;

    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();
        deployActors();
        
        createAndFundMarket(oracle, address(this), eventIdentifier, fundAmount);
        marketIdentifier = getMarketIdentifier(oracle, address(this), eventIdentifier);

        // one buy trade 
        buy(address(this), oracle, marketIdentifier, 10*10**18, 10*10**18);
    }

    function test_buy(uint120 a0, uint120 a1) public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        // before vals
        (uint bt0, uint bt1) = getOutcomeTokenBalance(address(this), _oracle, _marketIdentifier);
        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);

        uint a = buy(address(this), _oracle, _marketIdentifier, a0, a1);

        // checks
        checkOutcomeTokenBalance(address(this),_oracle, _marketIdentifier, bt0+a0, bt1+a1);
        checkReserves(_oracle, _marketIdentifier, r0+a-a0, r1+a-a1);
    }

    function testFail_buy_inSufficientAmount(uint120 a0, uint120 a1) public {
        if (a0 == a1 ) return;
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        // manipulate vals
        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        uint a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);

        emit log_named_uint("amount", a);
        a -= 1; // supplying less amount than needed

        IERC20(tokenC).transfer(_oracle, a);

        Oracle(_oracle).buy(a0, a1, address(this), _marketIdentifier);
    }

    function testFail_buy_notExisitingMarketIdentifier() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = keccak256('invalid');

        IERC20(tokenC).transfer(_oracle, 10*10**18);

        // note - a0 & a1 is a lot less than a, so under normal situation this succeeds
        Oracle(_oracle).buy(1*10**18, 1*10**18, address(this), _marketIdentifier);
    }


    function test_sell(uint120 a0, uint120 a1) public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        buy(address(this), _oracle, _marketIdentifier, a0, a1);

        // before vals
        uint tb = getTokenCBalance(address(this), _oracle, _marketIdentifier);
        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        (uint bt0, uint bt1) = getOutcomeTokenBalance(address(this), _oracle, _marketIdentifier);

        uint a = sell(address(this), _oracle, _marketIdentifier, a0, a1);

        // checks
        checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, bt0-a0, bt1-a1);
        checkReserves(_oracle, _marketIdentifier, r0+a0-a, r1+a1-a);
        checkTokenCBalance(address(this), _oracle, _marketIdentifier, tb+a);
    }

    function testFail_sell_inSufficientAmount(uint120 a0, uint120 a1) public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        buy(address(this), _oracle, _marketIdentifier, a0, a1);

        // manipulate vals
        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        uint a = Math.getAmountCBySellTokens(a0, a1, r0, r1);
        a += 10; // ask for more amount than selling a0 & a1 would permit

        // emit log_uint(a);
        // emit log_uint(a0);
        // emit log_uint(a1);
        // emit log_uint(r0);
        // emit log_uint(r1);

        (uint t0, uint t1) = getOutcomeTokenIds(_oracle, _marketIdentifier);
        Oracle(_oracle).safeTransferFrom(address(this), _oracle, t0, a0, '');
        Oracle(_oracle).safeTransferFrom(address(this), _oracle, t1, a1, '');

        Oracle(_oracle).sell(a, address(this), _marketIdentifier);
    }

    /* 
    Gas specific tests
     */
    function test_gas_buy() public {
        address _tokenC = tokenC;
        address _oracle = oracle;
        IERC20(_tokenC).transfer(_oracle, 10*10**18 + 1);
        Oracle(_oracle).buy(10*10**18, 10*10**18, address(this), marketIdentifier);
    } 

    function test_gas_sell() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        (uint t0, uint t1) = getOutcomeTokenIds(_oracle, _marketIdentifier);
        Oracle(_oracle).safeTransferFrom(address(this), _oracle, t0, 10*10**18, '');
        Oracle(_oracle).safeTransferFrom(address(this), _oracle, t1, 10*10**18, '');
        Oracle(_oracle).sell(10*10**18-1, address(this), _marketIdentifier);
    }


    /* 
    Invalid stage access
     */  
    function testFail_stakeOutcome() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        buy(address(this), _oracle, _marketIdentifier, 10*10**18, 10*10**18);
        stakeOutcome(_oracle, _marketIdentifier, 0, 10*10**18, address(this));
    }

    function testFail_redeemWinning() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        buy(address(this), _oracle, _marketIdentifier, 10*10**18, 10*10**18);
        Oracle(_oracle).redeemWinning(address(this), _marketIdentifier);
    }

    function testFail_redeemStake() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        buy(address(this), _oracle, _marketIdentifier, 10*10**18, 10*10**18);
        Oracle(_oracle).redeemStake(_marketIdentifier, address(this));
    }

    function testFail_setOutcome() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        Oracle(_oracle).setOutcome(0, _marketIdentifier);
    }

}

contract OracleTest_StageBuffer is OracleTest {

    bytes32 marketIdentifier;

    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();
        deployActors();
        
        createAndFundMarket(oracle, address(this), eventIdentifier, fundAmount);
        marketIdentifier = getMarketIdentifier(oracle, address(this), eventIdentifier);

        // commences buffer period; rolls to block at which market expires
        roll(getStateDetail(oracle, marketIdentifier, 0));
    }

    function test_stakeOutcome() public {
        emit log_named_address("origin", tx.origin);
        emit log_named_address("address", address(this));
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        uint rTokenC = getTokenCResereves(_oracle, _marketIdentifier);

        stakeOutcome(_oracle, _marketIdentifier, 0, 2*10**18, address(this));

        checkStake(tx.origin, _oracle, _marketIdentifier, 2*10**18, 0); // stake exists
        checkTokenCReserves(_oracle, _marketIdentifier, rTokenC + 2*10**18); // tokenC reserves increased by stake

        // more valid staking
        stakeOutcome(_oracle, _marketIdentifier, 1, 4*10**18, actor1);
        stakeOutcome(_oracle, _marketIdentifier, 0, 8*10**18, address(this));

        checkStake(tx.origin, _oracle, _marketIdentifier, 10*10**18, 0);
        checkStake(actor1, _oracle, _marketIdentifier, 0, 4*10**18);

        checkTokenCReserves(_oracle, _marketIdentifier, rTokenC + 14*10**18);
        checkTokenCReserveMatchesBalance(_oracle, _marketIdentifier);
    }

    function testFail_stakeOutcome_invalidDoubling() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        stakeOutcome(_oracle, _marketIdentifier, 0, 2*10**18, address(this));

        stakeOutcome(_oracle, _marketIdentifier, 1, 4*10**18-1, actor1);
    }

    function testFail_stakeOutcome_amountZero() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        stakeOutcome(_oracle, _marketIdentifier, 0, 0, address(this));
    }

    function test_stakeOutcome_tillBeforeEscalationLimit() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        uint el = getStateDetail(_oracle, _marketIdentifier, 6);
        for (uint i; i < el; i++){
            uint odd = i%2;
            address from;
            if (odd == 1){
                from = actor1;
            }else {
                from = address(this);
            }
            stakeOutcome(_oracle, _marketIdentifier, i%2, 2*10**18*(2**i), from);
        }
    }

    function testFail_stakeOutcome_tillAfterHittingEscalationLimit() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        uint el = getStateDetail(_oracle, _marketIdentifier, 6);
        for (uint i; i < el+1; i++){
            uint odd = i%2;
            address from;
            if (odd == 1){
                from = actor1;
            }else {
                from = address(this);
            }
            stakeOutcome(_oracle, _marketIdentifier, i%2, 2*10**18*(2**i), from);
        }
    }

    /* 
    Gas tests */
    function test_gas_stakeOutcome() public {
        address _oracle = oracle;
        IERC20(tokenC).transfer(_oracle, 10*10**18);
        Oracle(oracle).stakeOutcome(0, marketIdentifier, address(this));
    }

    /* 
    Invalid stage access
     */
    function testFail_buy() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        roll(getStateDetail(_oracle, _marketIdentifier, 0)); // expires market
        buy(address(this), _oracle, _marketIdentifier, 10*10**18, 10*10**18);
    }

    function testFail_sell() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        roll(getStateDetail(_oracle, _marketIdentifier, 0)); // expires market
        Oracle(oracle).sell(10*10**18, address(this), _marketIdentifier);
    }

    function testFail_redeemWinning() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        Oracle(_oracle).redeemWinning(address(this), _marketIdentifier);
    }

    function testFail_redeemStake() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        Oracle(_oracle).redeemStake(_marketIdentifier, address(this));
    }

    function testFail_setOutcome() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        Oracle(_oracle).setOutcome(0, _marketIdentifier);
    }

}

contract OracleTest_StageBufferPeriodExpired is OracleTest {

    bytes32 marketWithNoStakesAndNoTrades; // resolves to 2
    bytes32 marketWithNoStakesAndBiasedTrades; // resolves to biased outcome
    bytes32 marketWithNoStakesAndEqualTrades; // resolves to 2

    /* 
    marketWithStakesOnBothSide would always resolve to
    last staked outcome. Thus, prior trades do not matter.
     */
    bytes32 marketWithStakesOnBothSides;

    /* 
    marketWithStakesOnSingleSide would always resolve to
    last staked outcome. Thus, prior trades do not matter.
    In this case, the last staker does not wins anything, since 
    there's no opposition stake.
     */
    bytes32 marketWithStakesOnSingleSide;
    
    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();
        deployActors();
        
        /* 
        Prep marketWithNoStakesAndNoTrades
         */
        bytes32 _eventIdentifier = keccak256('marketWithNoStakesAndNoTrades');
        bytes32 _marketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        marketWithNoStakesAndNoTrades = _marketIdentifier;
        createAndFundMarket(oracle, address(this), _eventIdentifier, fundAmount);
        roll(getStateDetail(oracle, _marketIdentifier, 1)); // buffer period expires

        /* 
        Prep marketWithNoStakesAndBiasedTrades
         */
        _eventIdentifier = keccak256('marketWithNoStakesAndBiasedTrades');
        _marketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        marketWithNoStakesAndBiasedTrades = _marketIdentifier;
        createAndFundMarket(oracle, address(this), _eventIdentifier, fundAmount);
        // biased trade; tilt favor to 0
        buy(address(this), oracle, _marketIdentifier, 10*10**18, 0);
        buy(actor1, oracle, _marketIdentifier, 0, 5*10**18);
        roll(getStateDetail(oracle, _marketIdentifier, 1)); // buffer period expires

        /* 
        Prep marketWithNoStakesAndEqualTrades
         */
        _eventIdentifier = keccak256('marketWithNoStakesAndEqualTrades');
        _marketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        marketWithNoStakesAndEqualTrades = _marketIdentifier;
        createAndFundMarket(oracle, address(this), _eventIdentifier, fundAmount);
        // equal trades
        buy(address(this), oracle, _marketIdentifier, 10*10**18, 0);
        buy(actor1, oracle, _marketIdentifier, 0, 10*10**18);
        roll(getStateDetail(oracle, _marketIdentifier, 1));

        /* 
        Prep marketWithStakesOnBothSides
         */
        _eventIdentifier = keccak256('marketWithStakesOnBothSides');
        _marketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        marketWithStakesOnBothSides = _marketIdentifier;
        createAndFundMarket(oracle, address(this), _eventIdentifier, fundAmount);
        buy(address(this), oracle, _marketIdentifier, 10*10**18, 0);
        buy(actor1, oracle, _marketIdentifier, 0, 5*10**18);
        roll(getStateDetail(oracle, _marketIdentifier, 0)); // market expires
        stakeOutcome(oracle, _marketIdentifier, 0, 2*10**18, address(this));
        stakeOutcome(oracle, _marketIdentifier, 1, 4*10**18, actor1); 
        stakeOutcome(oracle, _marketIdentifier, 0, 8*10**18, address(this)); // winning stake
        roll(getStateDetail(oracle, _marketIdentifier, 1)); // buffer period expires

        /* 
        Prep marketWithStakesOnSingleSide
         */
        _eventIdentifier = keccak256('marketWithStakesOnSingleSide');
        _marketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        marketWithStakesOnSingleSide = _marketIdentifier;
        createAndFundMarket(oracle, address(this), _eventIdentifier, fundAmount);
        buy(address(this), oracle, _marketIdentifier, 0, 10*10**18);
        buy(actor1, oracle, _marketIdentifier, 5*10**18, 0);
        roll(getStateDetail(oracle, _marketIdentifier, 0)); // market expires
        stakeOutcome(oracle, _marketIdentifier, 1, 2*10**18, actor1);
        stakeOutcome(oracle, _marketIdentifier, 1, 4*10**18, address(this)); // winning stake, but nothing to win
        roll(getStateDetail(oracle, _marketIdentifier, 1)); // buffer period expires
    }

    function test_redeem_marketWithNoStakesAndNoTrades() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithNoStakesAndNoTrades;
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 0, 0, 0);
        checkRedeemStake(address(this), _oracle, _marketIdentifier, 0);
        checkOutcome(_oracle, _marketIdentifier, 2);
    }

    function test_redeem_marketWithNoStakesAndBiasedTrades() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithNoStakesAndBiasedTrades;
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 10*10**18);
        checkOutcome(_oracle, _marketIdentifier, 0);
        checkRedeemStake(address(this), _oracle, _marketIdentifier, 0);
    }

    function test_redeem_marketWithNoStakesAndEqualTrades() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithNoStakesAndEqualTrades;
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 5*10**18);
        checkRedeemWinning(actor1, _oracle, _marketIdentifier, 0, 10*10**18, 5*10**18);
        checkOutcome(_oracle, _marketIdentifier, 2);
        checkRedeemStake(address(this), _oracle, _marketIdentifier, 0);
    }

    function test_redeem_marketWithStakesOnBothSides() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 10*10**18);
        checkOutcome(_oracle, _marketIdentifier, 0); // last staked outcome
        checkRedeemWinning(actor1, _oracle, _marketIdentifier, 0, 5*10**18, 0);
        checkRedeemStake(address(this), _oracle, _marketIdentifier, 2*10**18 + 8*10**18 + 4*10**18); // i.e. win amount = amount winner staked + loser's stake
        checkRedeemStake(actor1, _oracle, _marketIdentifier, 0); // win amount = 0, since actor1 lost staking
    }

    function test_redeem_marketWithStakesOnSingleSide() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnSingleSide;
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 0, 10*10**18, 10*10**18);
        checkOutcome(_oracle, _marketIdentifier, 1); // last staked outcome
        checkRedeemWinning(actor1, _oracle, _marketIdentifier, 5*10**18, 0, 0);
        checkRedeemStake(address(this), _oracle, _marketIdentifier, 4*10**18); // winning stake, but they win nothing since opposition stake == 0
        checkRedeemStake(actor1, _oracle, _marketIdentifier, 2*10**18);
    }

    /* 
    Gas Test
     */
    function test_gas_redeemWinning_marketWithStakesOnBothSides() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;
        (uint t0,) = Oracle(_oracle).getOutcomeTokenIds(_marketIdentifier);
        Oracle(_oracle).safeTransferFrom(address(this), _oracle, t0, 10*10**18, '');
        Oracle(_oracle).redeemWinning(address(this), _marketIdentifier);
    }

    function test_gas_redeemStake_marketWithStakesOnBothSides() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;
        Oracle(_oracle).redeemStake(_marketIdentifier, address(this));
    }

    /* 
    Invalid stage access
     */
    function testFail_buy() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        roll(getStateDetail(_oracle, _marketIdentifier, 1)); // buffer period expires
        buy(address(this), _oracle, _marketIdentifier, 10*10**18, 10*10**18);
    }

    function testFail_sell() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        roll(getStateDetail(_oracle, _marketIdentifier, 1)); // buffer period expires
        Oracle(oracle).sell(10*10**18, address(this), _marketIdentifier);
    }

    function testFail_stakeOutcome() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        roll(getStateDetail(_oracle, _marketIdentifier, 1)); // buffer period expires
        stakeOutcome(_oracle, _marketIdentifier, 0, 10*10**18, address(this));
    }

    function testFail_setOutcome() public {
        (address _oracle, bytes32 _marketIdentifier) = prepRandomMarket();
        roll(getStateDetail(_oracle, _marketIdentifier, 1)); // buffer period expires
        Oracle(_oracle).setOutcome(0, _marketIdentifier);
    }
}

contract OracleTest_StageEscalationLimitHitOracleResolves is OracleTest {

    /* 
    With stakes on both sides, oracle collects fee from the losing stake
     */
    bytes32 marketWithStakesOnBothSides;

    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();
        deployActors();

        /* 
        Prep marketWithStakesOnBothSides
         */
        bytes32 _eventIdentifier = keccak256('marketWithStakesOnBothSides');
        bytes32 _marketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        marketWithStakesOnBothSides = _marketIdentifier;
        createAndFundMarket(oracle, address(this), _eventIdentifier, fundAmount);
        buy(address(this), oracle, _marketIdentifier, 10*10**18, 0);
        buy(actor1, oracle, _marketIdentifier, 0, 5*10**18);
        roll(getStateDetail(oracle, _marketIdentifier, 0)); // market expires
        for (uint i; i < oracleConfig.donEscalationLimit; i++){
            uint odd = i%2;
            address from;
            if (odd == 1){
                from = actor1;
            }else {
                from = address(this);
            }
            stakeOutcome(oracle, _marketIdentifier, odd, 2*10**18*(2**i), from);
        } // stake till escalation limit

        /* 
        Prep marketWithStakesOnSingleSide
         */
        // _eventIdentifier = keccak256('marketWithStakesOnSingleSide');
        // _marketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        // marketWithStakesOnSingleSide = _marketIdentifier;
        // createAndFundMarket(oracle, address(this), _eventIdentifier, fundAmount);
        // buy(address(this), oracle, _marketIdentifier, 10*10**18, 0);
        // buy(actor1, oracle, _marketIdentifier, 0, 5*10**18);
        // roll(getStateDetail(oracle, _marketIdentifier, 0)); // market expires
        // for (uint i; i < oracleConfig.donEscalationLimit; i++){
        //     uint odd = i%2;
        //     address from;
        //     if (odd == 1){
        //         from = actor1;
        //     }else {
        //         from = address(this);
        //     }
        //     stakeOutcome(oracle, _marketIdentifier, 0, 2*10**18*(2**i), from);
        // } // stake till escalation limit with only single sided stake
    }

    /* 
    Estimates amount staked to reach escalation limit.
    Assumes that staking competition is between 2 actors
    taking alternate turns for their favored outcome, 
    starting with outcome = 0. Their favored outcome is 
    represented by their index (hence, actorIndex should
    alays be < 2).
     */
    function estimateAmountStakedToReachEscalation(address _oracle, bytes32 _marketIdentifier, uint actorIndex) internal view returns (uint amountStaked) {
        require(actorIndex < 2);
        uint el = getStateDetail(_oracle, _marketIdentifier, 6);
        for (uint i=0; i < el; i++){
            uint odd = i%2;
            if (actorIndex == odd){
                amountStaked += 2*10**18*(2**i);
            }
        }
    }

    function test_marketWithStakesOnBothSides_setOutcome(uint8 outcome) public {
        outcome = outcome % 3;
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;

        checkPassMarketResolution(_oracle, _marketIdentifier, outcome);
        checkOutcome(_oracle, _marketIdentifier, outcome);

        if (outcome == 0){
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 10*10**18);
            checkRedeemWinning(actor1, _oracle, _marketIdentifier, 0, 5*10**18, 0);
        }else if (outcome == 1){
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 0);
            checkRedeemWinning(actor1, _oracle, _marketIdentifier, 0, 5*10**18, 5*10**18);
        }else {
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 5*10**18);
            checkRedeemWinning(actor1, _oracle, _marketIdentifier, 0, 5*10**18, 25*10**17);
        }

        (uint sR0, uint sR1) = getStakingReserves(_oracle, _marketIdentifier);
        uint oracleFee;
        if (outcome != 2){
            if (outcome == 0){
                oracleFee = getOracleFeeAmount(_oracle, _marketIdentifier, sR1);
            }else {
                oracleFee = getOracleFeeAmount(_oracle, _marketIdentifier, sR0);
            }
        }
        if (outcome == 0){
            checkRedeemStake(address(this), _oracle, _marketIdentifier, sR0 + sR1); // winning amount = amount staked + losing stake - oracle fee; sR1 represents stake losing stake - oracle fee since setOutcome was called before
            checkRedeemStake(actor1, _oracle, _marketIdentifier, 0); 
        }else if (outcome == 1) {
            checkRedeemStake(address(this), _oracle, _marketIdentifier, 0);
            checkRedeemStake(actor1, _oracle, _marketIdentifier, sR1 + sR0);
        }else {
            checkRedeemStake(address(this), _oracle, _marketIdentifier, sR0);
            checkRedeemStake(actor1, _oracle, _marketIdentifier, sR1);
        }
    }

    function testFail_setOutcomeToInvalidValue(uint8 outcome) public {
        if (outcome >= 3) Oracle(oracle).setOutcome(outcome, marketWithStakesOnBothSides);
        assertTrue(false);
    }

    function testFail_setOutcomeInvalidDelegate() public {
        bytes memory data = abi.encodeWithSignature("setOutcome(uint8,bytes32)", 0, marketWithStakesOnBothSides);
        (bool success, ) = actor1.call(abi.encodeWithSignature("send(address,bytes,bool)", oracle, data, true));
        assertTrue(success);
    }

    /* 
    Gas Test
     */
    function test_gas_setOutcome() public {
        Oracle(oracle).setOutcome(0, marketWithStakesOnBothSides);
    }

    /* 
    Invalid stage access
     */
    function testFail_buy() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;
        buy(address(this), _oracle, _marketIdentifier, 10*10**18, 10*10**18);
    }

    function testFail_sell() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;
        Oracle(_oracle).sell(10*10**18, address(this), _marketIdentifier);
    }

    function testFail_stakeOutcome() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;
        // current stakes
        (uint amount,,,) = getStaking(_oracle, _marketIdentifier);
        stakeOutcome(_oracle, _marketIdentifier, 0, amount*2, address(this));
    }

    function testFail_redeemWinning() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;
        Oracle(_oracle).redeemWinning(address(this), _marketIdentifier);
    }

    function testFail_redeemStake() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSides;
        Oracle(_oracle).redeemStake(_marketIdentifier, address(this));
    }
}


contract OracleTest_StageResolutionPeriodExpired is OracleTest {

    bytes32 marketWithStakesOnBothSidesResolutionPeriodExpired;

    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();
        deployActors();

        /* 
        Prep marketWithStakesOnBothSides with resolution period expired
         */
        bytes32 _eventIdentifier = keccak256('marketWithStakesOnBothSides');
        bytes32 _marketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        marketWithStakesOnBothSidesResolutionPeriodExpired = _marketIdentifier;
        createAndFundMarket(oracle, address(this), _eventIdentifier, fundAmount);
        buy(address(this), oracle, _marketIdentifier, 10*10**18, 0);
        buy(actor1, oracle, _marketIdentifier, 0, 5*10**18);
        roll(getStateDetail(oracle, _marketIdentifier, 0)); // market expires
        for (uint i; i < oracleConfig.donEscalationLimit; i++){
            uint odd = i%2;
            address from;
            if (odd == 1){
                from = actor1;
            }else {
                from = address(this);
            }

            stakeOutcome(oracle, _marketIdentifier, odd, 2*10**18*(2**i), from);
        } // stake till escalation limit
        roll(getStateDetail(oracle, _marketIdentifier, 2)); // resolution period expires

    }

    /* 
    Post resolution period expiry, market resolves to last staked outcome
     */
    function test_redeem_marketWithStakesOnBothSidesResolutionPeriodExpired() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSidesResolutionPeriodExpired;

        uint outcome;
        if (oracleConfig.donEscalationLimit-1%2 == 0){
            outcome = 0;
        }else {
            outcome = 1;
        }

        if (outcome == 0){
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 10*10**18);
            checkRedeemWinning(actor1, _oracle, _marketIdentifier, 0, 5*10**18, 0);
        }else{
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 0);
            checkRedeemWinning(actor1, _oracle, _marketIdentifier, 0, 5*10**18, 5*10**18);
        }

        (uint sR0, uint sR1) = getStakingReserves(_oracle, _marketIdentifier);
        if (outcome == 0){
            checkRedeemStake(address(this), _oracle, _marketIdentifier, sR0 + sR1); // win amount = amount staked + losing amount staked (Note - orcle fee isn't deducted)
            checkRedeemStake(actor1, _oracle, _marketIdentifier, 0);
        }else {
            checkRedeemStake(address(this), _oracle, _marketIdentifier, 0);
            checkRedeemStake(actor1, _oracle, _marketIdentifier, sR0 + sR1);
        }
    }

    /* 
    Invalid stage access
     */
    function testFail_buy() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSidesResolutionPeriodExpired;
        buy(address(this), _oracle, _marketIdentifier, 10*10**18, 10*10**18);
    }

    function testFail_sell() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSidesResolutionPeriodExpired;
        Oracle(_oracle).sell(10*10**18, address(this), _marketIdentifier);
    }

    function testFail_stakeOutcome() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSidesResolutionPeriodExpired;
        // current stakes
        (uint amount,,,) = getStaking(_oracle, _marketIdentifier);
        stakeOutcome(_oracle, _marketIdentifier, 0, amount*2, address(this));
    }

    function testFail_setOutcome() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketWithStakesOnBothSidesResolutionPeriodExpired;
        Oracle(_oracle).setOutcome(0, _marketIdentifier);
    }
}