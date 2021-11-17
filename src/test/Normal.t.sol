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
		Oracle(oracle).collateralToken();
		(,,,,,,bool isActive) = Oracle(oracle).marketConfig();
		require(isActive);
		Oracle(oracle).createAndFundMarket(address(this), keccak256('E'));
	}


}
