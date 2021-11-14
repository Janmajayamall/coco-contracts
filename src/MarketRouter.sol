// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import './libraries/Math.sol';
import './OracleMarkets.sol';


contract MarketRouter {
    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function getMarketIdentifier(address creator, bytes32 eventIdentifier, address oracle) public pure returns (bytes32 marketIdentifier){
        marketIdentifier = keccak256(abi.encode(creator, eventIdentifier, oracle));
    }

    /// @notice Create, fund, and place bet on a market
    function createFundBetOnMarket(bytes32 eventIdentifier, address oracle, uint fundingAmount, uint amountIn, uint _for) external {
        require(_for < 2 && fundingAmount > 0);

        address tokenC = OracleMarkets(oracle).collateralToken();

        // create & fund
        TransferHelper.safeTransfer(tokenC, oracle, fundingAmount);
        OracleMarkets(oracle).createAndFundMarket(msg.sender, eventIdentifier);

        // place bet
        bytes32 marketIdentifier = getMarketIdentifier(msg.sender, eventIdentifier, oracle);
        TransferHelper.safeTransfer(tokenC, oracle, amountIn);
        if (_for == 0) OracleMarkets(oracle).buy(amountIn, 0, msg.sender, marketIdentifier);
        if (_for == 1) OracleMarkets(oracle).buy(0, amountIn, msg.sender, marketIdentifier);
    }

    /// @notice Buy exact amountOfToken0 & amountOfToken1 with collteral tokens <= amountInCMax
    function buyExactTokensForMaxCTokens(uint amountOutToken0, uint amountOutToken1, uint amountInCMax, address oracle, bytes32 marketIdentifier) external {
        (uint reserve0, uint reserve1) = OracleMarkets(oracle).reserves(marketIdentifier);
        uint amountIn = Math.getAmountCToBuyTokens(amountOutToken0, amountOutToken1, reserve0, reserve1);
        require(amountInCMax >= amountIn, "TRADE: INVALID");
        (address tokenC,,) = OracleMarkets(oracle).marketDetails(marketIdentifier);
        TransferHelper.safeTransferFrom(tokenC, msg.sender, oracle, amountIn);
        OracleMarkets(oracle).buy(amountOutToken0, amountOutToken1, msg.sender, marketIdentifier);
    }

    /// @notice Buy minimum amountOfToken0 & amountOfToken1 with collteral tokens == amountInC. 
    /// fixedTokenIndex - index to token of which amount does not change in reaction to prices 
    function buyMinTokensForExactCTokens(uint amountOutToken0Min, uint amountOutToken1Min, uint amountInC, uint fixedTokenIndex, address oracle, bytes32 marketIdentifier) external {
        require(fixedTokenIndex < 2);

        (uint reserve0, uint reserve1) = OracleMarkets(oracle).reserves(marketIdentifier);

        uint amountOutToken0 = amountOutToken0Min;
        uint amountOutToken1 = amountOutToken1Min;
        if (fixedTokenIndex == 0){
            amountOutToken1 = Math.getTokenAmountToBuyWithAmountC(amountOutToken0, fixedTokenIndex, reserve0, reserve1, amountInC);
        }else {
            amountOutToken0 = Math.getTokenAmountToBuyWithAmountC(amountOutToken1, fixedTokenIndex, reserve0, reserve1, amountInC);
        }
        require(amountOutToken0 >= amountOutToken0Min && amountOutToken1 >= amountOutToken1Min);

        (address tokenC,,) = OracleMarkets(oracle).marketDetails(marketIdentifier);
        TransferHelper.safeTransferFrom(tokenC, msg.sender, oracle, amountInC);
        OracleMarkets(oracle).buy(amountOutToken0, amountOutToken1, msg.sender, marketIdentifier);
    }

    /// @notice Sell exact amountInToken0 & amountInToken1 for collateral tokens >= amountOutTokenCMin
    function sellExactTokensForMinCTokens(uint amountInToken0, uint amountInToken1, uint amountOutTokenCMin, address oracle, bytes32 marketIdentifier) external {
        (uint reserve0, uint reserve1) = OracleMarkets(oracle).reserves(marketIdentifier);
        uint amountOutTokenC = Math.getAmountCBySellTokens(amountInToken0, amountInToken1, reserve0, reserve1);
        require(amountOutTokenC >= amountOutTokenCMin, "TRADE: INVALID");

        (uint token0, uint token1) = OracleMarkets(oracle).getOutcomeTokenIds(marketIdentifier);
        OracleMarkets(oracle).safeTransferFrom(msg.sender, oracle, token0, amountInToken0, '');
        OracleMarkets(oracle).safeTransferFrom(msg.sender, oracle, token1, amountInToken1, '');
        OracleMarkets(oracle).sell(amountOutTokenC, msg.sender, marketIdentifier);
    }

    /// @notice Sell maximum of amountInToken0Max & amountInToken1Max for collateral tokens == amountOutTokenC
    /// fixedTokenIndex - index of token of which amount does not change in reaction to prices
    function sellMaxTokensForExactCTokens(uint amountInToken0Max, uint amountInToken1Max, uint amountOutTokenC, uint fixedTokenIndex, address oracle, bytes32 marketIdentifier) external {
        require(fixedTokenIndex < 2);

        (uint reserve0, uint reserve1) = OracleMarkets(oracle).reserves(marketIdentifier);

        uint amountInToken0 = amountInToken0Max;
        uint amountInToken1 = amountInToken1Max;
        if (fixedTokenIndex == 0){
            amountInToken1 = Math.getTokenAmountToSellForAmountC(amountInToken0, fixedTokenIndex, reserve0, reserve1, amountOutTokenC);
        }else {
            amountInToken0 = Math.getTokenAmountToSellForAmountC(amountInToken1, fixedTokenIndex, reserve0, reserve1, amountOutTokenC);
        }
        require(amountInToken0 <= amountInToken0Max && amountInToken1 <= amountInToken1Max, "TRADE: INVALID");

        (uint token0, uint token1) = OracleMarkets(oracle).getOutcomeTokenIds(marketIdentifier); 
        OracleMarkets(oracle).safeTransferFrom(msg.sender, oracle, token0, amountInToken0, '');
        OracleMarkets(oracle).safeTransferFrom(msg.sender, oracle, token1, amountInToken1, '');
        OracleMarkets(oracle).sell(amountOutTokenC, msg.sender, marketIdentifier);
    }

    /// @notice Stake amountIn for outcome _for 
    function stakeForOutcome(uint _for, uint amountIn, address oracle, bytes32 marketIdentifier) external {
        require(_for < 2);
        
        (uint lastAmountStaked,,,) = OracleMarkets(oracle).staking(marketIdentifier);
        require(lastAmountStaked*2 <= amountIn, "ERR: DOUBLE");

        (address tokenC,,) = OracleMarkets(oracle).marketDetails(marketIdentifier);
        TransferHelper.safeTransferFrom(tokenC, msg.sender, oracle, amountIn);
        OracleMarkets(oracle).stakeOutcome(_for, msg.sender, marketIdentifier);
    }

    /// @notice Redeem winning for outcome
    function redeemWinning(uint _for, uint amountInToken, address oracle, bytes32 marketIdentifier) external {
        (uint token0, uint token1) = OracleMarkets(oracle).getOutcomeTokenIds(marketIdentifier);
        if (_for == 0) OracleMarkets(oracle).safeTransferFrom(msg.sender, oracle, token0, amountInToken, '');
        if (_for == 1) OracleMarkets(oracle).safeTransferFrom(msg.sender, oracle, token1, amountInToken, '');
        OracleMarkets(oracle).redeemWinning(msg.sender, marketIdentifier);
    }
}
