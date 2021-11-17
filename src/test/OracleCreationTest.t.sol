// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../Oracle.sol";
import "./../MemeToken.sol";
import "./../interfaces/IOracle.sol";
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

}
