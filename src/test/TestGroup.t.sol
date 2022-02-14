// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../Group.sol";
import "./../proxies/GroupProxy.sol";
import "./../proxies/GroupProxyFactory.sol";
import "./../helpers/TestToken.sol";
import "ds-test/test.sol";

contract TestGroup is DSTest {

    Group groupSingleton;
    GroupProxyFactory groupProxyFactory;
    GroupProxy groupProxy;
    TestToken tokenC; 
    function setUp() public {
        groupSingleton = new Group();
        groupProxyFactory = new GroupProxyFactory();
        tokenC = new TestToken();

        // new group
        bytes memory marketConfig = abi.encode(true, uint64(1213121), uint64(3600), uint64(3600));
        groupProxy = groupProxyFactory.createGroupWithSafe(
            address(this), 
            address(groupSingleton), 
            address(tokenC), 
            100000000000000000 * 10 ** 18,
            marketConfig
        );
    }

    function testCreateMarket() public {
        Group _group = Group(address(groupProxy));
        TestToken _tokenC = tokenC;

        bytes32 marketIdentifier = keccak256(abi.encodePacked("dwadad"));
        _tokenC.transfer(address(_group), 3 * 10 ** 18);
        _group.createMarket(marketIdentifier, address(this), address(this),  2 * 10 ** 18, 1 * 10 ** 18);

        _tokenC.transfer(address(_group), 4 * 10 ** 18 );
        _group.challenge(0, marketIdentifier, address(this));
        // tokenC.transfer(, amount);
    }

}