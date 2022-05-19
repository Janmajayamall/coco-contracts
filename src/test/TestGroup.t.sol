// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../Group.sol";
import "./../GroupRouter.sol";
import "./../GroupSigning.sol";
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

    uint256 constant ONE = 1e18;

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
        // bytes32 ethSignDigest = keccak256(
        //     abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        // );
        (uint8 v, bytes32 r, bytes32 s ) = vm.sign(pk, digest);
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
        sId0 = keccak256(abi.encodePacked("S_Group_v1", "0", marketIdentifier, _of));
        sId1 = keccak256(abi.encodePacked("S_Group_v1", "1", marketIdentifier, _of));
    }

    // creator -> user1
    // challenger -> address(this)
    // uses default settings
    function defaultCreateAndChallengeMarket(
        Group _group,
        GroupRouter _groupRouter,
        uint256 creatorAmount,
        uint256 challengerAmount
        
    ) internal {
        // preapre marketData for user1
        GroupMarket.MarketData memory marketData = GroupMarket.MarketData({
            group: address(_group),
            marketIdentifier: defaultMarketIdentifier,
            amount1: creatorAmount
        });

        // marketData signature of user1
        bytes memory marketDataSignature = ethSignMarketData(marketData, _groupRouter.domainSeparator(), PK);

        // address(this) calls createAndChallengeMarket
        _groupRouter.createAndChallengeMarket(marketData, marketDataSignature, GroupSigning.Scheme.Eip712, challengerAmount);
    }

    function matchMarketReserves(
        Group _group,
        bytes32 marketIdentifier,
        uint256 eReserve0,
        uint256 eReserve1
    ) internal {
        (uint256 r0, uint256 r1) = _group.marketReserves(marketIdentifier);
        assertEq(r0, eReserve0);
        assertEq(r1, eReserve1);
    }

    function matchMarketStakes(
        Group _group,
        bytes32 marketIdentifier,
        address _for,
        uint256 eS0,
        uint256 eS1
    ) internal {
        (bytes32 s0Id,bytes32 s1Id) = getStakingIds(marketIdentifier, _for);
        assertEq(_group.stakes(s0Id), eS0);
        assertEq(_group.stakes(s1Id), eS1);
    }

    function matchMarketState(
        Group _group,
        bytes32 marketIdentifier,
        uint64 eDonBufferEndsAt, 
        uint64 eResolutionBufferEndsAt,
        uint64 eDonBuffer,
        uint64 eResolutionBuffer
    )  internal {
        (
            uint64 cDonBufferEndsAt, 
            uint64 cResolutionBufferEndsAt,
            uint64 cDonBuffer,
            uint64 cResolutionBuffer
        ) = _group.marketStates(marketIdentifier);
        assertEq(cDonBufferEndsAt, eDonBufferEndsAt);
        assertEq(cResolutionBufferEndsAt, eResolutionBufferEndsAt);
        assertEq(cDonBuffer, eDonBuffer);
        assertEq(cResolutionBuffer, eResolutionBuffer);
    }

    function matchMarketStakeInfo(
        Group _group,
        bytes32 marketIdentifier,
        address eStaker0,
        address eStaker1,
        uint256 eLastAmountStaked
    ) internal {
        (
            address cStaker0,
            address cStaker1,
            uint256 cLastAmountStaked
        ) = _group.marketStakeInfo(marketIdentifier);
        assertEq(cStaker0, eStaker0);
        assertEq(cStaker1, eStaker1);
        assertEq(cLastAmountStaked, eLastAmountStaked);
    }

    function setUp() public {
        groupSingleton = new Group();
        groupProxyFactory = new GroupProxyFactory();
        tokenC = new TestToken();
        groupRouter = new GroupRouter();

        // new group
        bytes memory marketConfig = abi.encode(true, defaultFee, defaultDonBuffer, defaultResolutionBuffer);
        group = Group(address(groupProxyFactory.createGroupWithManager(
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


        // bytes32 k = keccak256("MarketData(address group,bytes32 marketIdentifier,uint256 amount1)");
        // emit FF(k);

        // assertTrue(false);
    }
    function testSignHelper() public {
        GroupMarket.MarketData memory _marketData = GroupMarket.MarketData({
            group:address(0xaD67843A0CC312a5B0e295E9192a4f575Bc104B3),
            marketIdentifier: hex"f46d83587ba9524e4b954832f83b19bab7189cde3b040661ea67a2a546d0a93b",
            amount1: uint256(50000000000000000)
        });

        uint256 pvKey = uint256(0xbff706dc5bb72ac228325d17223776d6474a8ad0c2f6dec26838840bac652b7b);

        bytes memory signature = ethSignMarketData(_marketData, groupRouter.domainSeparator(), pvKey);
        // emit F(signature);
        // assertTrue(false);
    
        // bytes memory signature = hex"54438918944217a3696455cd25ded51a8f1bf6e9540f626cf0d435d41ea8854b4b16f9d2982ac3b927750a290cbe4ed0e578545e49b888e6a314e9cff046db491c";
        assertEq(
            groupRouter.recoverSigner(
                _marketData,
                signature,
                GroupSigning.Scheme.Eip712
            ),
            vm.addr(pvKey)
        );

        // console.log(f);
    }
    event F(bytes s);
    // function testHJ() public  {
    //     (bytes32 s0, bytes32 s1) = getStakingIds(hex"29e7f1d6fa5a6aa908168535a734f12eb327860ce90f760e17d35f0a2ca32070", address(0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6));
    //     emit F(s0);
    //     emit F(s1);
    //     assertTrue(false);
    // }

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

        defaultCreateAndChallengeMarket(_group, _groupRouter, 1 * 10 ** 18, 2 * 10 ** 18);
       
        // check stuff

        // check reserves
        matchMarketReserves(_group, defaultMarketIdentifier, 2 * 10 ** 18, 1 * 10 ** 18);

        // check respective stakes
        matchMarketStakes(_group, defaultMarketIdentifier, user1, 0, 1 * 10 ** 18);
        matchMarketStakes(_group, defaultMarketIdentifier, address(this), 2 * 10 ** 18, 0);

        // check market state 
        matchMarketState(
            _group, 
            defaultMarketIdentifier, 
            defaultDonBuffer + uint64(block.timestamp), 
            0, 
            defaultDonBuffer, 
            defaultResolutionBuffer
        );
    
        // check market stake info
        matchMarketStakeInfo(
            _group, 
            defaultMarketIdentifier, 
            address(this), 
            user1, 
            2 * 10 ** 18
        );
    }

    // test subsequent challenges
    function testChallenges()  public {
        Group _group = group;
        GroupRouter _groupRouter = groupRouter;
        defaultCreateAndChallengeMarket(_group, _groupRouter, 1 * 10 ** 18, 2 * 10 ** 18);

        // warp time but stay below block buffer
        vm.warp(block.timestamp + 1000);

        // round 1
        vm.prank(user1);
        _groupRouter.challenge(address(_group), defaultMarketIdentifier, 1, 4 * 10 ** 18); // user1

        matchMarketReserves(_group, defaultMarketIdentifier, 2 * 10 ** 18, 5 * 10 ** 18);
        matchMarketStakes(_group, defaultMarketIdentifier, user1, 0, 5 * 10 ** 18); // user1 stakes
        matchMarketStakeInfo(_group, defaultMarketIdentifier, address(this), user1, 4 * 10 ** 18); 
        matchMarketState(
            _group, 
            defaultMarketIdentifier, 
            uint64(block.timestamp) + defaultDonBuffer, 
            0, 
            defaultDonBuffer, 
            defaultResolutionBuffer
        );
        
    }

    // check that one cannot challenge after buffer time expires
    function testFailDonBufferExpired() public {
        Group _group = group;
        GroupRouter _groupRouter = groupRouter;
        defaultCreateAndChallengeMarket(_group, _groupRouter, 1 * 10 ** 18, 2 * 10 ** 18);

        // a few challenges
        vm.prank(user1);
        _groupRouter.challenge(address(_group), defaultMarketIdentifier, 1, 4 * 10 ** 18); // user1
        _groupRouter.challenge(address(_group), defaultMarketIdentifier, 0, 8 * 10 ** 18); // addresss(this)
        vm.prank(user1);
        _groupRouter.challenge(address(_group), defaultMarketIdentifier, 1, 16 * 10 ** 18); // user1


        vm.warp(block.timestamp + defaultDonBuffer);

        // address(this) tries to challenge, but should fail
        _groupRouter.challenge(address(_group), defaultMarketIdentifier, 0, 32 * 10 ** 18); // address(this)
    }

    function testOutcomeIsLastChallengePostBufferExpiry() public {
        Group _group = group;
        GroupRouter _groupRouter = groupRouter;
        defaultCreateAndChallengeMarket(_group, _groupRouter, 1 * 10 ** 18, 2 * 10 ** 18);

        vm.warp(block.timestamp + defaultDonBuffer);

        // outcome should 0
        (,, uint8 outcome) = _group.marketDetails(defaultMarketIdentifier);
        assertEq(0, outcome);
    }

    function testRedeemPostBufferExpiry() public {
        Group _group = group;
        GroupRouter _groupRouter = groupRouter;
        TestToken _tokenC = tokenC;
        defaultCreateAndChallengeMarket(_group, _groupRouter, 1 * 10 ** 18, 2 * 10 ** 18);

        vm.prank(user1);
        _groupRouter.challenge(address(_group), defaultMarketIdentifier, 1, 4 * 10 ** 18); // user 1 challenges

        // buffer period expires
        vm.warp(block.timestamp + defaultDonBuffer);
    
        // user1 wins, since wasn't challenged before buffer period expired
        // should win 2 * 10 ** 18 + should get their stake back
        (uint256 balanceBefore) = _tokenC.balanceOf(user1);
        _group.redeem(defaultMarketIdentifier, user1);
        (uint256 balanceAfter) = _tokenC.balanceOf(user1);
        assertEq(balanceAfter, balanceBefore + 7 * 10 ** 18); // 4 + 1 => user1's stake + 2 => address(this) stake (i.e. stake in losing outcome)

        // address(this) should not win anything
        balanceBefore = _tokenC.balanceOf(address(this));
        _group.redeem(defaultMarketIdentifier, address(this));
        assertEq(_tokenC.balanceOf(address(this)), balanceBefore);
    }

    function testMarketTransitionsToResolutionAfterLimitHits() public {
        Group _group = group;
        GroupRouter _groupRouter = groupRouter;
        TestToken _tokenC = tokenC;
        defaultCreateAndChallengeMarket(_group, _groupRouter, 1 * 10 ** 18, 2 * 10 ** 18);

        // address(this) challenges again with amount that exceeds lmimit, thus market transitions to resolution
        _groupRouter.challenge(address(_group), defaultMarketIdentifier, 0, defaultDonReservesLimit);

        // check that market state has transitioned to resolution period
        matchMarketState(
            _group, 
            defaultMarketIdentifier, 
            uint64(block.timestamp), 
            uint64(block.timestamp) + defaultResolutionBuffer, 
            defaultDonBuffer, 
            defaultResolutionBuffer
        );
    }

    function testFeeCollectionByManager() public {
        // Timestamp is by default zero.
        // Setting it to some other value 
        // avoids underflow
        vm.warp(10);  

        Group _group = group;
        GroupRouter _groupRouter = groupRouter;
        TestToken _tokenC = tokenC;
        defaultCreateAndChallengeMarket(_group, _groupRouter, 1 * 10 ** 18, 2 * 10 ** 18);

        // address(this) challenges again with amount that exceeds lmimit, thus market transitions to resolution
        _groupRouter.challenge(address(_group), defaultMarketIdentifier, 0, defaultDonReservesLimit);

        // check fee collection after outcome is set
        // note - address(this) is also the manager
        uint256 balanceBefore = _tokenC.balanceOf(address(this));
        _group.setOutcome(0, defaultMarketIdentifier); // outcone is set to 0, so fee collected is (FEE * 1)
        assertEq(_tokenC.balanceOf(address(this))-balanceBefore, (uint256(defaultFee) * (1 * 10 ** 18))/ONE);
    }

    // function testFee
}