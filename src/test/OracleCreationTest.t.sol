// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../OracleMarkets.sol";
import "./../MemeToken.sol";
import "./../interfaces/IOracleMarkets.sol";
import "./utils/Hevm.sol";
import "./../libraries/Math.sol";

contract OracleCreationTest is DSTest, Hevm {
	struct OracleConfig {
		address tokenC;
		uint32 feeNumerator;
        uint32 feeDenominator;
        uint32 expireBufferBlocks;
        uint32 donBufferBlocks;
        uint32 resolutionBufferBlocks;
        uint16 donEscalationLimit;
        bool isActive;
	}


	OracleConfig defaultOracleConfig;

	/* 
	Edge case oracle configs 
	isActive = false
	feeNum > fee Denom
	escalation limit == 0
	buffer period = 0
	es && bp = 0
	 */
	

	address oracle;
	address tokenC;

	/* 
	Market Identifiers for every possible market state

	Under normal oracle configs (i.e. all buffers & escalation limit > 0)
		created
		funded (i.e. active trading)
		active buffer period
			with prior trades
			with no prior trades
		buffer period expires 
			with no staking & prior trades -> resolves to favored outcome
			with no staking & no prior trades -> resolves to 2
			with stakes
				with stakes on both sides -> resolves to last staked & last staker wins full stake in opposition
				with 0 opposite stakes -> resolves to last staked & last staker wins nothing
		el hit 
		resolution
			resolves to last staked
				with some opposite stake -> last staker wins opposite stake (afteer deducting oracle fee)
				with no opposite stake -> last staker wins nothing; 0 oracle fee
			resolves to !last staked
				with opposite staked right before last staked -> opposite staker wins & received amount - oracle fee
				with opposite staked long before last staked -> opposite staker wins & received amount - oracle fee
				with no opposite stake -> anyone can claim the winning amount

	Oracle confg - el = 0; rest remains the same
		created & funded as normal
		no buffer period
		resolution passed
		resolution period expires -> resolves to favoured outcome
	
	Oracle config - bp = 0; rest remains the same
		created & funded as normal
		market expires -> resolves to favoured outcome
		no buffer period
		no resolution period
	
	Oracle confg - el = 0 & bp = 0; rest remains the same
		created & funded as normal
		market expires -> resolves to favoured outcome
		no buffer period
		no resolution period

	Oracle config - rp = 0; rest remains the same
		created & funded as normal
		buffer period normal
		el hit -> resolves to last staked
		buffer period expires -> resolves to last staked
		no resolution period

	 */
	bytes32 resolvedMarket;
	bytes32 inBufferMarket;
	bytes32 activeMarket;

	function buy(address _oracle, bytes32 _marketIdentifier, uint a0, uint a1) public {
		(uint r0, uint r1) = OracleMarkets(_oracle).outcomeReserves(_marketIdentifier);
		uint a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
		IERC20(tokenC).transfer(oracle, a);
		OracleMarkets(oracle).buy(a0, a1, address(this), _marketIdentifier);
	}

	function sell(address _oracle, bytes32 _marketIdentifier, uint a0, uint a1) public {
		(uint r0, uint r1) = OracleMarkets(_oracle).outcomeReserves(_marketIdentifier);
		uint a = Math.getAmountCBySellTokens(a0, a1, r0, r1);

		(uint t0, uint t1) = OracleMarkets(_oracle).getOutcomeTokenIds(_marketIdentifier);
		OracleMarkets(_oracle).safeTransferFrom(address(this), oracle, t0, a0, '');
		OracleMarkets(_oracle).safeTransferFrom(address(this), oracle, t1, a1, '');

		OracleMarkets(_oracle).sell(a, address(this), _marketIdentifier);
	}

	function getStateDetail(address _oracle, bytes32 _marketIdentifier, uint index) public returns(uint) {
		(
			uint32 expireAtBlock,
			uint32 donBufferEndsAtBlock,
			uint32 resolutionEndsAtBlock,
			uint32 donBufferBlocks,
			uint32 resolutionBufferBlocks,
			uint16 donEscalationCount,
			uint16 donEscalationLimit,
			uint8 outcome,
			uint8 stage
		) = OracleMarkets(_oracle).stateDetails(_marketIdentifier);

		if (index == 0) return expireAtBlock;
		if (index == 1) return donBufferEndsAtBlock;
		if (index == 2) return resolutionEndsAtBlock;
		if (index == 3) return donBffeerBlocks;
		if (index == 4) return resolutionBufferBlocks;
		if (index == 5) return donEscalationCount;
		if (index == 6) return donEscalationLimit;
		if (index == 7) return outcome;
		if (index == 8) return stage;
	}


	function setUp() public {
		tokenC = address(new MemeToken());
		MemeToken(tokenC).mint(address(this), type(uint).max);

		// default oracle config 
		defaultOracleConfig.tokenC = tokenC;

		/* 
		Edge case oracle config
s 
isActive = false

 */

		defaultOracleConfig.feeNumerator = 10;

		/* 
		Edge case oracle config
s 
isActive = false

 */

		defaultOracleConfig.feeDenominator = 100;

		/* 
		Edge case oracle config
s 
isActive = false

 */

		defaultOracleConfig.expireBufferBlocks = 100;

		/* 
		Edge case oracle config
s 
isActive = false

 */

		defaultOracleConfig.donBufferBlocks = 100;

		/* 
		Edge case oracle config
s 
isActive = false

 */

		defaultOracleConfig.resolutionBufferBlocks = 100;

		/* 
		Edge case oracle config
s 
isActive = false

 */

		defaultOracleConfig.donEscalationLimit = 10;

		/* 
		Edge case oracle config
s 
isActive = false

 */

		defaultOracleConfig.isActive = true;

		/* 
		Edge case oracle config
s 
isActive = false

 */

		
		// create oracle with default configs
		oracle = address(new OracleMarkets(address(this)));
		OracleMarkets(oracle).updateCollateralToken(tokenC);
		OracleMarkets(oracle).updateMarketConfig(
			defaultOracleConfig.isActive, 

			/* 
			Edge case oracle config
	s 
	isActive = false

	 */
	
			defaultOracleConfig.feeNumerator, 

			/* 
			Edge case oracle config
	s 
	isActive = false

	 */
	
			defaultOracleConfig.feeDenominator, 

			/* 
			Edge case oracle config
	s 
	isActive = false

	 */
	
			defaultOracleConfig.donEscalationLimit, 

			/* 
			Edge case oracle config
	s 
	isActive = false

	 */
	
			defaultOracleConfig.expireBufferBlocks, 

			/* 
			Edge case oracle config
	s 
	isActive = false

	 */
	
			defaultOracleConfig.donBufferBlocks, 

			/* 
			Edge case oracle config
	s 
	isActive = false

	 */
	
			defaultOracleConfig.resolutionBufferBlocks

			/* 
			Edge case oracle config
	s 
	isActive = false

	 */
	
		);

		OracleMarkets(oracle).createAndFundMarket(address(this), keccak256('resolvedMarket'));
		resolvedMarket = OracleMarkets(oracle).getMarketIdentifier(address(this), keccak256('resolvedMarket'));
		buy(oracle, resolvedMarket, 10*10**18, 0);
		uint 
		roll();
	}

	function test_updateCollateralToken() public {
		OracleMarkets(oracle).updateCollateralToken(tokenC);
		assertEq(OracleMarkets(oracle).collateralToken(), tokenC); 
	}

	function test_updateMarketConfig() public {
		OracleMarkets(oracle).updateMarketConfig(
			true,
			10,
			100,
			10,
			100,
			100,
			100
		);

		(
			uint32 feeNumerator,
			uint32 feeDenominator,
			uint32 expireBufferBlocks,
			uint32 donBufferBlocks,
			uint32 resolutionBufferBlocks,
			uint16 donEscalationLimit,
			bool isActive
		) = OracleMarkets(oracle).marketConfig();

	
		assertEq(feeNumerator, 10);
		assertEq(feeDenominator, 100);
		assertEq(expireBufferBlocks, 100);
		assertEq(donBufferBlocks, 100);
		assertEq(resolutionBufferBlocks, 100);
		assertEq(donEscalationLimit, 10);
		assertTrue(isActive);
	}

	function test_updateDelegate() public {
		OracleMarkets(oracle).updateDelegate(tokenC);
		assertEq(OracleMarkets(oracle).delegate(), tokenC);
	}
}
