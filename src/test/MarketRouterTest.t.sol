// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/test.sol";
import "./utils/OracleTestHelpers.sol";
import "./../MarketRouter.sol";
import "./../Oracle.sol";
import "./../interfaces/IERC20.sol";
import "./../libraries/Math.sol";

contract MarketRouterTest is OracleTestHelpers {
    address oracle;
    address tokenC;
    address marketRouter;

    bytes32 activeMarketIdentifier;

    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));

        oracle = address(new Oracle());
        Oracle(oracle).updateCollateralToken(tokenC);
        Oracle(oracle).updateMarketConfig(
           true,
           10,
           100,
           10,
           100,
           100,
           100
        );

        marketRouter = address(new MarketRouter());

        // give max approval to marketRouter
        IERC20(tokenC).approve(marketRouter, type(uint).max);

        /*
        Prep activeMarketIdentifier
         */
        bytes32 _eventIdentifier = keccak256('activeMarketIdentifier');
        activeMarketIdentifier = getMarketIdentifier(oracle, address(this), _eventIdentifier);
        createAndFundMarket(oracle, address(this), _eventIdentifier, 10*10**18);
        buy(address(this), oracle, activeMarketIdentifier, 10*10**18, 10*10**18);


        giveApprovalERC1155(address(this), marketRouter, oracle); // give outcome tokens apporval

    }

    function test_createFundBetOnMarket(uint120 fundingAmount, uint120 amountIn, uint _for) public {
        if (fundingAmount == 0) return;
        unchecked {
            uint b = IERC20(tokenC).balanceOf(address(this));
            if (fundingAmount + amountIn < fundingAmount) return;
            if ((b - (fundingAmount + amountIn)) > b) return;
        }
        _for = _for %2 ;

        address _marketRouter = marketRouter;
        address _oracle = oracle;
        bytes32 _eventIdentifier = keccak256('eventIdentifier');
        bytes32 _marketIdentifier = MarketRouter(_marketRouter).getMarketIdentifier(address(this), _eventIdentifier, _oracle);

        MarketRouter(_marketRouter).createFundBetOnMarket(
            _eventIdentifier,
            _oracle,
            fundingAmount,
            amountIn,
            _for
        );


        uint a0;
        uint a1;
        if (_for == 0) {
            a0 = Math.getTokenAmountToBuyWithAmountC(0, 1, fundingAmount, fundingAmount, amountIn);
        }
        if (_for == 1) {
            a1 = Math.getTokenAmountToBuyWithAmountC(0, 0, fundingAmount, fundingAmount, amountIn);
        }

        checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, a0, a1);
    }

    function test_gas_createFundBetOnMarket() public {
        MarketRouter(marketRouter).createFundBetOnMarket(
            keccak256('eventIdentifier'),
            oracle,
            10*10**18,
            10*10**18,
            0
        );
    }

    function test_buyExactTokensForMaxCTokens(uint120 amountOutToken0, uint120 amountOutToken1) public {
        address _marketRouter = marketRouter;
        address _oracle = oracle;
        bytes32 _marketIdentifier = activeMarketIdentifier;

        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        uint amount = Math.getAmountCToBuyTokens(amountOutToken0, amountOutToken1, r0, r1);

        (uint bT0B, uint bT1B) = getOutcomeTokenBalance(address(this), _oracle, _marketIdentifier);

        MarketRouter(_marketRouter).buyExactTokensForMaxCTokens(amountOutToken0, amountOutToken1, amount, _oracle, _marketIdentifier);

        checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, bT0B + amountOutToken0, bT1B + amountOutToken1);
    }

    function test_gas_buyExactTokensForMaxCTokens() public {
        address _marketRouter = marketRouter;
        address _oracle = oracle;
        bytes32 _marketIdentifier = activeMarketIdentifier;
        MarketRouter(_marketRouter).buyExactTokensForMaxCTokens(10*10**18, 0, 20*10**18, _oracle, _marketIdentifier);
    }

    function test_buyMinTokensForExactCTokens(uint120 amountIn) public {
        if (amountIn == 0) return;
        address _marketRouter = marketRouter;
        address _oracle = oracle;
        bytes32 _marketIdentifier = activeMarketIdentifier;

        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        uint aT0 = Math.getTokenAmountToBuyWithAmountC(0, 1, r0, r1, amountIn);

        (uint bT0B, uint bT1B) = getOutcomeTokenBalance(address(this), _oracle, _marketIdentifier);

        MarketRouter(_marketRouter).buyMinTokensForExactCTokens(aT0, 0, amountIn, 1, _oracle, _marketIdentifier);

        checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, bT0B+aT0, bT1B);
    }

    function test_sellExactTokensForMinCTokens(uint120 a0, uint120 a1) public {
        address _marketRouter = marketRouter;
        address _oracle = oracle;
        bytes32 _marketIdentifier = activeMarketIdentifier;

        // buy to sell later
        buy(address(this), _oracle, _marketIdentifier, a0, a1);


        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        uint a = Math.getAmountCBySellTokens(a0, a1, r0, r1);

        (uint bT0B, uint bT1B) = getOutcomeTokenBalance(address(this), _oracle, _marketIdentifier);

        MarketRouter(_marketRouter).sellExactTokensForMinCTokens(a0, a1, a, _oracle, _marketIdentifier);

        checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, bT0B - a0, bT1B - a1);
    }

    function test_gas_sellExactTokensForMinCTokens() public {
        address _marketRouter = marketRouter;
        address _oracle = oracle;
        bytes32 _marketIdentifier = activeMarketIdentifier;
        MarketRouter(_marketRouter).sellExactTokensForMinCTokens(5*10**18, 5*10**18, 4*10**18, _oracle, _marketIdentifier);
    }

    function test_sellMaxTokensForExactCTokens(uint120 a0, uint120 a1) public {
        address _marketRouter = marketRouter;
        address _oracle = oracle;
        bytes32 _marketIdentifier = activeMarketIdentifier;

        // buy to sell later
        buy(address(this), _oracle, _marketIdentifier, a0, a1);

        (uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
        uint a = Math.getAmountCBySellTokens(a0, a1, r0, r1);

        (uint bT0B, uint bT1B) = getOutcomeTokenBalance(address(this), _oracle, _marketIdentifier);

        MarketRouter(_marketRouter).sellMaxTokensForExactCTokens(a0, a1, a, 1, _oracle, _marketIdentifier);

        // checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, bT0B - a0 , bT1B - a1);
    }
}
