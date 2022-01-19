// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./../proxies/OracleProxyFactory.sol";
import "./utils/OracleTestHelpers.sol";
import "./utils/SafeTestHelpers.sol";
import "ds-test/test.sol";

import "./../OracleFactory.sol";

interface Caller {
    function data() external view returns(address,address);
}

contract Normal is DSTest {

    OracleTestHelpers oracleTestHelpers;
    SafeTestHelpers safeTestHelpers;

    OracleProxyFactory factory;
    Oracle oracleSingleton;
    GnosisSafe safeSingleton;

    OracleFactory oracleFactory;

    function setUp() public {
        oracleTestHelpers = new OracleTestHelpers();
        safeTestHelpers = new SafeTestHelpers();

        factory = new OracleProxyFactory();
        oracleSingleton = oracleTestHelpers.deploySingleton();
        safeSingleton = safeTestHelpers.deploySingleton();

        oracleFactory = new OracleFactory();
    }

    event log_bytes4(bytes4 f);

    function test_gff() external {
        oracleFactory.createOracle(
            address(this),
            address(this),
            address(this),
            true,
            5,
            8,
            100,
            100,
            100,
            100
        );
    }

    function test_creating() external {
        bytes memory oracleMarketConfig = abi.encode(
            true,
            5, 
            100, 
            5, 
            100, 
            100, 
            100
        );
        address[] memory owners = new address[](1);
        owners[0] = address(4);

        address proxy = address(factory.createOracle(
            address(oracleSingleton), 
            address(safeSingleton), 
            address(0), 
            oracleMarketConfig, 
            owners, 
            1
        ));
    }

}