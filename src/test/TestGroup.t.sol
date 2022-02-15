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
    address immutable user1;

    // default values
    bytes32 constant defaultMarketIdentifier = keccak256(abi.encode("Default Market"));
    uint64 constant defaultFee = 5 * 10 ** 16; // 0.05
    uint64 constant defaultDonBuffer = 60 * 60 * 24; // 1 day
    uint64 constant defaultResolutionBuffer = 60 * 60 * 24; // 1 day
    uint256 constant defaultDonReservesLimit = 10000000 * 10 ** 18;

    constructor() {
        user1 = vm.addr(PK);
    }

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

    function getStakingIds(
        bytes32 marketIdentifier, 
        address _of
    ) internal pure returns (
        bytes32 sId0,
        bytes32 sId1
    ) {
        sId0 = keccak256(abi.encodePacked("S_Group_v1", marketIdentifier, _of));
        sId1 = keccak256(abi.encodePacked("S_Group_v1", marketIdentifier, _of));
    }

    function setUp() public {
        groupSingleton = new Group();
        groupProxyFactory = new GroupProxyFactory();
        tokenC = new TestToken();
        groupRouter = new GroupRouter();

        // new group
        bytes memory marketConfig = abi.encode(true, defaultFee, defaultDonBuffer, defaultResolutionBuffer);
        group = Group(address(groupProxyFactory.createGroupWithSafe(
            address(this), 
            address(groupSingleton), 
            address(tokenC), 
            defaultDonReservesLimit,
            marketConfig
        )));

        // transfer test tokens to user1
        tokenC.transfer(user1, 100000000000 * 10 ** 18);

        // address(this) gives max approval to group router
        tokenC.approve(address(groupRouter), type(uint256).max);

        // user1 gives max approval to group router
        vm.prank(user1); // changes msg.sender to user1 for next call
        tokenC.approve(address(groupRouter), type(uint256).max);
    }

    function testCreateMarket() public {
        Group _group = group;
        TestToken _tokenC = tokenC;

        _tokenC.transfer(address(_group), 3 * 10 ** 18);
        _group.createMarket(defaultMarketIdentifier, address(this), address(this),  2 * 10 ** 18, 1 * 10 ** 18);

        _tokenC.transfer(address(_group), 4 * 10 ** 18 );
        _group.challenge(0, defaultMarketIdentifier, address(this));
    }

    function testGroupRouterCreateAndChallengeMarket() public {
        // address(this) -> challenger
        // user1 -> creator

        Group _group = group;
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

        // check stuff

        // check reserves
        (uint256 r0, uint256 r1) = _group.marketReserves(defaultMarketIdentifier);
        assertEq(r0, 2 * 10 ** 18);
        assertEq(r1, 1 * 10 ** 18);

        // check respective stakes
        bytes32 s0Id;
        bytes32 s1Id;
        // checking stake of user1
        (s0Id, s1Id) = getStakingIds(defaultMarketIdentifier, user1);
        assertEq(_group.stakes(s1Id), 1 * 10 ** 18);
        // checking stake of address(this)
        (s0Id, s1Id) = getStakingIds(defaultMarketIdentifier, address(this));
        assertEq(_group.stakes(s0Id), 2 * 10 ** 18);

        // check market state 
        (
            uint64 cDonBufferEndsAt, 
            uint64 cResolutionBufferEndsAt,
            uint64 cDonBuffer,
            uint64 cResolutionBuffer
        ) = _group.marketStates(defaultMarketIdentifier);
        assertEq(cDonBufferEndsAt, defaultDonBuffer + uint64(block.timestamp));
        assertEq(cResolutionBufferEndsAt, 0);
        assertEq(cDonBuffer, defaultDonBuffer);
        assertEq(cResolutionBuffer, defaultResolutionBuffer);

        // check market stake info
        (
            address cStaker0,
            address cStaker1,
            uint256 cLastAmountStaked
        ) = _group.marketStakeInfo(defaultMarketIdentifier);
        assertEq(cStaker0, address(this));
        assertEq(cStaker1, user1);
        assertEq(cLastAmountStaked, 2 * 10 ** 18);
    }

    


}