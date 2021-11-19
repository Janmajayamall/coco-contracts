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

contract OracleWithZeroEscalationLimmit is OracleTestHelpers {
    /* 
    create oracle with configs
    then test for the follow
    1. No need to test BUY AND SELL since they aren't affected
    2. Test that market goes to resolution right after expirty; so no buffer period; 
     */
    
    OracleConfig oracleConfig;

    address oracle;
	address tokenC;
    uint fundAmount = 10*10**18;
    bytes32 eventIdentifier = keccak256('default');

    function setOracleConfig() public {
        // setup default oracle confing 
		oracleConfig.tokenC = tokenC;
		oracleConfig.feeNumerator = 10;
		oracleConfig.feeDenominator = 100;
    	oracleConfig.expireBufferBlocks = 100;
		oracleConfig.donBufferBlocks = 100;
		oracleConfig.resolutionBufferBlocks = 100;
		oracleConfig.donEscalationLimit = 0; // only change
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
}

/* 
Tests for StageCreated & StageFunded are skipped since
setting escalation limit to zero will not have any effect
on any stage prior to Market expiry (i.e. StageBuffer)
 */

/* 
Stage buffer is equivalent of Stage market expired.
In case of escalation limit = 0, StageBuffer shouldn't
exist. Thus you will notice that most functions expected 
to work in Stage buffer will fail.
Note that when escalation limit = 0, market transitions to
StageResolve right after market expiry, skipping buffer period. 
This is different from when donBufferPeriod = 0, when market resolves
to favored outcome right after market expiry. When both escalation limit
& donBufferPeriod are 0, preference is give to donBufferPeriod.
 */
contract OracleWithZeroEscalationLimit_StageBuffer is OracleWithZeroEscalationLimmit {
    bytes32 marketIdentifier;

    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();

        createAndFundMarket(oracle, address(this), eventIdentifier, fundAmount);
        marketIdentifier = getMarketIdentifier(oracle, address(this), eventIdentifier); 
        // perform few trades
        buy(address(this), oracle, marketIdentifier, 10*10**18, 0);
        sell(address(this), oracle, marketIdentifier, 2*10**18, 0);
        // expire market;
        roll(getStateDetail(oracle, marketIdentifier, 0));
    }

    function testFail_stakeOutcome() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        stakeOutcome(_oracle, _marketIdentifier, 0, 10*10**18, address(this));
    }   
}

/* 
Note - Stage when oracle resolves, comes right after market expiry, 
skipping buffer period
 */
contract OracleWithZeroEscalationLimit_StageOracleResolves is OracleWithZeroEscalationLimmit {
    bytes32 marketIdentifier;

    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();

        createAndFundMarket(oracle, address(this), eventIdentifier, fundAmount);
        marketIdentifier = getMarketIdentifier(oracle, address(this), eventIdentifier); 
        // perform few trades
        buy(address(this), oracle, marketIdentifier, 10*10**18, 0);
        buy(address(this), oracle, marketIdentifier, 0, 10*10**18);
        // expire market;
        roll(getStateDetail(oracle, marketIdentifier, 0));
    }

    function test_setOutcome (uint8 outcome) public {
        outcome = outcome % 3;
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        checkPassMarketResolution(_oracle, _marketIdentifier, outcome);
        checkOutcome(_oracle, _marketIdentifier, outcome);

        if (outcome == 0){
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 10*10**18);
        }else if (outcome == 1){
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 0, 10*10**18, 10*10**18);
        }else {
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 5*10**18);
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 0, 10*10**18, 5*10**18);
        }

    }
}

contract OracleWithZeroEscalationLimit_StageResolutionPeriodExpired is OracleWithZeroEscalationLimmit {
    bytes32 marketIdentifier;

    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();

        createAndFundMarket(oracle, address(this), eventIdentifier, fundAmount);
        marketIdentifier = getMarketIdentifier(oracle, address(this), eventIdentifier); 
        // perform few trades
        buy(address(this), oracle, marketIdentifier, 10*10**18, 0);
        buy(address(this), oracle, marketIdentifier, 0, 5*10**18);
        // expire market;
        roll(getStateDetail(oracle, marketIdentifier, 0));
        // expire resolution period
        roll(getStateDetail(oracle, marketIdentifier, 2));
    }

    function testFail_setOutcome (uint8 outcome) public {
        outcome = outcome % 3;
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        Oracle(_oracle).setOutcome(outcome, _marketIdentifier);
    }

    /* 
    In setUp function odds are in favor of 0, so the winning outcome
    is 0
     */
    function test_redeemWinning() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 10*10**18);
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 0, 5*10**18, 0);
    }
}