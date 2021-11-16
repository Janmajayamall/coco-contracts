// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./utils/OracleMarketsTestHelpers.sol";
import "./../MarketRouter.sol";
import "./../OracleMarkets.sol";
import "./../interfaces/IERC20.sol";
import "./../libraries/Math.sol";

contract MarketRouterTest is OracleMarketsTestHelpers {
    address oracle;
    address tokenC;
    address marketRouter;

    bytes32 activeMarketIdentifier;
    
    function setUp() public {
        tokenC = deloyAndPrepTokenC(address(this));
        
        oracle = address(new OracleMarkets(address(this)));
        OracleMarkets(oracle).updateCollateralToken(tokenC);
        OracleMarkets(oracle).updateMarketConfig(
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


    }

    function test_createFundBetOnMarket() public {
        address _marketRouter = marketRouter;
        address _oracle = oracle;
        bytes32 _eventIdentifier = keccak256('eventIdentifier');

        MarketRouter(_marketRouter).createFundBetOnMarket(
            _eventIdentifier, 
            _oracle, 
            10*10**18, 
            10*10**18, 
            1
        );

        bytes32 _marketIdentifier = MarketRouter(_marketRouter).getMarketIdentifier(address(this), _eventIdentifier, _oracle);

        checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, 0, 10*10**18);
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

        MarketRouter(_marketRouter).buyExactTokensForMaxCTokens(amountOutToken0, amountOutToken1, amount, _oracle, _marketIdentifier);

        checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, amountOutToken0, amountOutToken1);
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

        MarketRouter(_marketRouter).buyMinTokensForExactCTokens(aT0, 0, amountIn, 1, _oracle, _marketIdentifier);

        checkOutcomeTokenBalance(address(this), _oracle, _marketIdentifier, aT0, 0);
    }
}