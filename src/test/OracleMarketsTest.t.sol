// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../OracleMarkets.sol";
import "./../MemeToken.sol";
import "./../interfaces/IOracleMarkets.sol";
import "./utils/Hevm.sol";
import "./../libraries/Math.sol";
import "./utils/OracleMarketsTestHelpers.sol";

contract OracleMarketsTest is OracleMarketsTestHelpers {

	OracleConfig oracleConfig;
	address oracle;
	address tokenC;

    bytes32 eventIdentifier = keccak256('default');

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
        oracle = address(new OracleMarkets(address(this)));
        OracleMarkets(oracle).updateCollateralToken(tokenC);
        OracleMarkets(oracle).updateMarketConfig(
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

contract OracleMarketsTest_StageCreated is OracleMarketsTest {
    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();
    }

    function _createAndFundMarket() internal {
        address _oracle = oracle;
        IERC20(tokenC).transfer(_oracle, 10*10**18);
        OracleMarkets(_oracle).createAndFundMarket(address(this), keccak256('default'));
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

contract OracleMarketsTest_StageFunded is OracleMarketsTest {

    bytes32 marketIdentifier;
    uint fundAmount = 10*10**18;


    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        setOracleConfig();
        deployOracle();
        createAndFundMarket(oracle, address(this), eventIdentifier, fundAmount);
        marketIdentifier = getMarketIdentifier(oracle, address(this), eventIdentifier);

        // one buy trade 
        buy(address(this), oracle, marketIdentifier, 10*10**18, 10*10**18);
    }

    function test_check_buy(uint120 a0, uint120 a1) public {
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

    function testFail_check_buy(uint120 a0, uint120 a1) public {
        if (a0 == a1) return;
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        // manipulate vals
        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        uint a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
        a -= 1; // supplying less amount than needed

        IERC20(tokenC).transfer(_oracle, a);

        OracleMarkets(_oracle).buy(a0, a1, address(this), _marketIdentifier);
    }

    function test_gas_buy() public {
        address _tokenC = tokenC;
        address _oracle = oracle;
        IERC20(_tokenC).transfer(_oracle, 10*10**18 + 1);
        OracleMarkets(_oracle).buy(10*10**18, 10*10**18, address(this), marketIdentifier);
    }

    function test_check_sell(uint120 a0, uint120 a1) public {
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

    function testFail_check_sell(uint120 a0, uint120 a1) public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;

        buy(address(this), _oracle, _marketIdentifier, a0, a1);

        // manipulate vals
        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        uint a = Math.getAmountCBySellTokens(a0, a1, r0, r1);
        a += 10; // ask for more amount than selling a0 & a1 would permit

        emit log_uint(a);
        emit log_uint(a0);
        emit log_uint(a1);
        emit log_uint(r0);
        emit log_uint(r1);


        (uint t0, uint t1) = getOutcomeTokenIds(_oracle, _marketIdentifier);
        OracleMarkets(_oracle).safeTransferFrom(address(this), _oracle, t0, a0, '');
        OracleMarkets(_oracle).safeTransferFrom(address(this), _oracle, t1, a1, '');

        OracleMarkets(_oracle).sell(a, address(this), _marketIdentifier);

    }

    function test_gas_sell() public {
        address _oracle = oracle;
        bytes32 _marketIdentifier = marketIdentifier;
        (uint t0, uint t1) = getOutcomeTokenIds(_oracle, _marketIdentifier);
        OracleMarkets(_oracle).safeTransferFrom(address(this), _oracle, t0, 10*10**18, '');
        OracleMarkets(_oracle).safeTransferFrom(address(this), _oracle, t1, 10*10**18, '');
        OracleMarkets(_oracle).sell(10*10**18-1, address(this), _marketIdentifier);
    }

}
