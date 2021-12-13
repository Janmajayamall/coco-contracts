// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../Oracle.sol";
import "./../MemeToken.sol";

contract Normal is DSTest {
	address oracle;
	address tokenC;

	function setUp() public {
		tokenC = address(new MemeToken());
		MemeToken(tokenC).mint(address(this), type(uint).max);

		oracle = address(new Oracle(address(this), address(this)));
		Oracle(oracle).updateCollateralToken(tokenC);
		Oracle(oracle).updateMarketConfig(
			true,
			10,
			100,
			10,
			10,
			100,
			100
		);

		MemeToken(tokenC).transfer(oracle, 10*10**18);
	}

	function test_createOracle() public {
		address oracle = address(new Oracle(address(this), address(this)));
		Oracle(oracle).updateCollateralToken(address(this));
		Oracle(oracle).updateMarketConfig(
			true,
			10,
			100,
			10,
			10,
			100,
			100
		);
	}

	function test_creatMarket() public {
		Oracle(oracle).createAndFundMarket(address(this), keccak256('E'));
	}

	// function test_lala() public {
	// 	bytes4 f = bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^ bytes4(keccak256("balanceOf(address,uint256)")) ^ bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^ bytes4(keccak256("setApprovalForAll(address,bool)")) ^ bytes4(keccak256("isApprovedForAll(address,address)"));
	// 	emit log_named_bytes32("signature ", f);
	// 	emit log_named_bytes32("fvgbhijo ", bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")));
	// 	assertTrue(false);
	// }

}
