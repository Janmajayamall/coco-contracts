// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../Group.sol";
import "./../GroupRouter.sol";
import "./../proxies/GroupProxy.sol";
import "./../proxies/GroupProxyFactory.sol";
import "./../helpers/TestToken.sol";
import "./../libraries/GroupMarket.sol";


import "ds-test/test.sol";
import "./VM.sol";
import "./Console.sol";

contract TestGroup is DSTest {
    VM vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    
    Group groupSingleton;
    GroupProxyFactory groupProxyFactory;
    Group group;
    TestToken tokenC; 
    GroupRouter groupRouter;

    // PK of user1
    uint256 constant PK = 0xf678dcf6fc488386af008e8989d24d0600e6155fb64abb4db6777a9e3dd3247e;

    // default values
    bytes32 constant defaultMarketIdentifier = keccak256(abi.encode("Default Market"));

    // helper functions
    function ethSignMarketData(
        GroupMarket.MarketData memory marketData,
        bytes32 domainSeparator,
        uint256 pk
    ) internal returns (bytes memory signature) {
        bytes32 digest = GroupMarket.hash(marketData, domainSeparator);
        bytes32 ethSignDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        (uint8 v, bytes32 r, bytes32 s ) = vm.sign(pk, ethSignDigest);
        signature = abi.encodePacked(
            r, s, v
        );
    }

    function setUp() public {
        groupSingleton = new Group();
        groupProxyFactory = new GroupProxyFactory();
        tokenC = new TestToken();
        groupRouter = new GroupRouter();

        // new group
        bytes memory marketConfig = abi.encode(true, uint64(1213121), uint64(3600), uint64(3600));
        group = Group(address(groupProxyFactory.createGroupWithSafe(
            address(this), 
            address(groupSingleton), 
            address(tokenC), 
            100000000000000000 * 10 ** 18,
            marketConfig
        )));

        // transfer test tokens to user1
        tokenC.transfer(vm.addr(PK), 100000000000 * 10 ** 18);

        // address(this) gives max approval to group router
        tokenC.approve(address(groupRouter), type(uint256).max);

        // user1 gives max approval to group router
        vm.prank(vm.addr(PK)); // changes msg.sender to user1 for next call
        tokenC.approve(address(groupRouter), type(uint256).max);
    }

    function testCreateMarket() public {
        Group _group = group;
        TestToken _tokenC = tokenC;

        bytes32 marketIdentifier = keccak256(abi.encodePacked("dwadad"));
        _tokenC.transfer(address(_group), 3 * 10 ** 18);
        _group.createMarket(marketIdentifier, address(this), address(this),  2 * 10 ** 18, 1 * 10 ** 18);

        _tokenC.transfer(address(_group), 4 * 10 ** 18 );
        _group.challenge(0, marketIdentifier, address(this));
        // tokenC.transfer(, amount);
    }

    function testGroupRouterCreateAndChallengeMarket() public {
        // address(this) -> challenger
        // user1 -> creator

        Group _group = group;
        TestToken _tokenC = tokenC;
        GroupRouter _groupRouter = groupRouter;

        // preapre marketData for user1
        GroupMarket.MarketData memory marketData = GroupMarket.MarketData({
            group: address(_group),
            marketIdentifier: defaultMarketIdentifier,
            amount1: 1 * 10 ** 18
        });

        // marketData signature of user1
        bytes memory marketDataSignature = ethSignMarketData(marketData, _groupRouter.domainSeparator(), PK);

        // address(this) calls createAndChallengeMarket
        _groupRouter.createAndChallengeMarket(marketData, marketDataSignature, 2 * 10 ** 18);

        // check values
        (uint256 r0, uint256 r1) = _group.marketReserves(defaultMarketIdentifier);
        assertEq(r0, 2 * 10 ** 18);
        assertEq(r1, 1 * 10 ** 18);
    }

}