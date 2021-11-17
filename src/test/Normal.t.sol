// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../OracleMarkets.sol";
import "./../MemeToken.sol";

contract Normal is DSTest {
	address oracle;
	address tokenC;

	function setUp() public {
		tokenC = address(new MemeToken());
		MemeToken(tokenC).mint(address(this), type(uint).max);

		oracle = address(new OracleMarkets(address(this), address(this)));
		OracleMarkets(oracle).updateCollateralToken(tokenC);
		OracleMarkets(oracle).updateMarketConfig(
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
		address oracle = address(new OracleMarkets(address(this), address(this)));
		OracleMarkets(oracle).updateCollateralToken(address(this));
		OracleMarkets(oracle).updateMarketConfig(
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
		OracleMarkets(oracle).collateralToken();
		(,,,,,,bool isActive) = OracleMarkets(oracle).marketConfig();
		require(isActive);
		OracleMarkets(oracle).createAndFundMarket(address(this), keccak256('E'));
	}


}
