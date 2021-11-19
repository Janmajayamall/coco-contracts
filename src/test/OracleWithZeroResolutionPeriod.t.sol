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

contract OracleWithZeroResolutionPeriod is OracleTestHelpers {
 
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
		oracleConfig.resolutionBufferBlocks = 0; // only change
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
}

/* 
The only effect of resolution period = 0 is that 
the market resolves to lastStakedOutcome after 
escalation limit hits. Thus tests for anything prior 
to that are skipped.
After escalation hits limit you will notice that setOutcome
will fail. 
 */

contract OracleWithZeroResolutionPeriod_escalationLimitHit is OracleWithZeroResolutionPeriod {
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
        for (uint i; i < oracleConfig.donEscalationLimit; i++){
            uint odd = i%2;
            stakeOutcome(oracle, marketIdentifier, odd, 2*10**18*(2**i), address(this));
        } // stake till escalation limit
    }

    /* 
    Stage will be StageResolve, since escalation limit was hit,
    but oracle will not be able to resolve since resolution period == 0
     */
    function test_stage() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        checkStage(_oracle, _marketIdentifier, 3);
    }

    function testFail_setOutcome() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        Oracle(_oracle).setOutcome(0, _marketIdentifier);
    }

    function test_redeemWinning() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        (,,,uint lastOutcomeStaked) = getStaking(_oracle, _marketIdentifier);
        if (lastOutcomeStaked == 0){
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 10*10**18);
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 0, 5*10**18, 0);
        }else if (lastOutcomeStaked == 1){
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 0);
            checkRedeemWinning(address(this), _oracle, _marketIdentifier, 0, 5*10**18, 5*10**18);
        }else {
            assertTrue(false); // invalid outcome
        }
    }

    function test_redeemStake() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        (uint r0, uint r1) = getStakingReserves(_oracle, _marketIdentifier);
        checkRedeemStake(address(this), _oracle, _marketIdentifier, r0+r1);
    }
}