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

contract OracleWithZeroBufferPeriod is OracleTestHelpers {
    /* 
    create oracle with configs
    then test for the follow
    1. No need to test BUY AND SELL since they aren't affected
    2. test that market resolves right after marke exopiry; so no buffer period & not resolution
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
		oracleConfig.donBufferBlocks = 0; // only change
		oracleConfig.resolutionBufferBlocks = 100;
		oracleConfig.donEscalationLimit = 0; 
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
setting donBufferPeriod = 0 has no effect on any stage
prior to market expiry
 */

/* 
When donBufferPeriod = 0, market resolves to favored outcome right after
market expiry. Thus, you will notice that functions expected to work in buffer & 
resolve period will fail.
 */
contract OracleWithZeroBufferPeriod_StageBuffer is OracleWithZeroBufferPeriod {
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
    }

    function testFail_stakeOutcome() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        stakeOutcome(_oracle, _marketIdentifier, 0, 10*10**18, address(this));
    }   


    function testFail_setOutcome() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        Oracle(_oracle).setOutcome(0, _marketIdentifier);
    }

    /* 
    Since market resolves to favored outcome right after
    market expiry when donBufferPeriod = 0, the outcome in
    this case will be 0
     */
    function test_redeemWinning() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 10*10**18, 0, 10*10**18);
        checkRedeemWinning(address(this), _oracle, _marketIdentifier, 0, 5*10**18, 0);
        checkOutcome(_oracle, _marketIdentifier, 0); // outcome should be 0
    }   
}
