// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./../proxies/OracleProxyFactory.sol";
// import "./utils/OracleTestHelpers.sol";
import "./utils/SafeTestHelpers.sol";
import "ds-test/test.sol";

interface Caller {
    function data() external view returns(address,address);
}

contract Normal is DSTest {



    OracleProxyFactory _factory;
    // Oracle _oracleSingleton;
    GnosisSafe _safeSingleton;

    function setUp() public {
        // _oracleSingleton = new Oracle();
        // _safeSingleton = new GnosisSafe();
        // _factory = new OracleProxyFactory();
    }

    event log_bytes4(bytes4 f);

    function test_creating() external {
        bytes memory creationCode = type(GnosisSafe).creationCode;
        emit log_bytes(creationCode);
        bytes4 d = bytes4(keccak256("updateMarketConfig(bool,uint32,uint32,uint16,uint32,uint32,uint32)"));
        emit log_bytes4(d);
        assertTrue(false);
        // address[] memory owners = new address[](1);
        // owners[0] = address(this);
        // address _proxy = _factory.createOracle(
        //     _oracleSingleton, 
        //     _safeSingleton, 
        //     _oracleSingleton, 
        //     true, 
        //     5, 
        //     100, 
        //     5, 
        //     100, 
        //     100, 
        //     100, 
        //     owners, 
        //     1
        // );
    }

}