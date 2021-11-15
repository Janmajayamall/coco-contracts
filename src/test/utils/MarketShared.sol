// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import './../../OracleMarkets.sol';
import './../../MemeToken.sol';
import './../../libraries/Math.sol';
import './Hevm.sol';

contract MarketShared {

    address oracle;
    address tokenC;

    bytes32 sharedEventIdentifier;
 
    struct OracleConfig {
        address tokenC;
        bool isActive;
        uint8 feeNumerator;
        uint8 feeDenominator;
        uint16 donEscalationLimit;
        uint32 expireBufferBlocks;
        uint32 donBufferBlocks;
        uint32 resolutionBufferBlocks;
    }

    OracleConfig defaultOracleConfig;


    address hevm = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function createTokenC() public {
        tokenC = address(new MemeToken());
        MemeToken(tokenC).mint(address(this), type(uint).max);
    }

    function createDefaultOracle() public {
        OracleConfig memory config;
        config.tokenC = tokenC;
        config.isActive = true;
        config.feeNumerator = 10;
        config.feeDenominator = 100;
        config.donEscalationLimit = 10;
        config.expireBufferBlocks = 100;
        config.donBufferBlocks = 100;
        config.resolutionBufferBlocks = 100;
        defaultOracleConfig = config;

        oracle = address(new OracleMarkets(address(this)));
        OracleMarkets(oracle).updateCollateralToken(tokenC);
        OracleMarkets(oracle).updateMarketConfig(config.isActive, config.feeNumerator, config.feeDenominator, config.donEscalationLimit, config.expireBufferBlocks, config.donBufferBlocks, config.resolutionBufferBlocks);
    }

    function createDefaultMarket() public {
        sharedEventIdentifier = keccak256('S');
        createMarket(sharedEventIdentifier, 10*10**18);
    }

    function createMarket(bytes32 eventIdentifier, uint fundingAmount) public {
        MemeToken(tokenC).transfer(oracle, fundingAmount);
        OracleMarkets(oracle).createAndFundMarket(address(this), eventIdentifier);
    }

    function getOutcomeTokensReserves(address _oracle, bytes32 _marketIdentifier) public  returns (uint,uint) {
        return OracleMarkets(_oracle).reserves(_marketIdentifier);
    }

    function getStakingReserves(address _oracle, bytes32 _marketIdentifier) public returns (uint,uint){
        return OracleMarkets(_oracle).stakingReserves(_marketIdentifier);
    }

    function getAmounCToBuyTokens(uint a0, uint a1, address _oracle, bytes32 _marketIdentifier) internal returns (uint a){
        (uint r0, uint r1) = getOutcomeTokensReserves(_oracle, _marketIdentifier);
        a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
    }

    function getTokenAmountToBuyWithAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint a, address _oracle, bytes32 _marketIdentifier) internal returns (uint tokenAmount) {
        (uint r0, uint r1) = getOutcomeTokensReserves(_oracle, _marketIdentifier);
        tokenAmount = Math.getTokenAmountToBuyWithAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
    }

    function getAmountCBySellTokens(uint a0, uint a1) internal returns (uint a, address _oracle, bytes32 _marketIdentifier){
        (uint r0, uint r1) = getOutcomeTokensReserves(_oracle, _marketIdentifier);
        a = Math.getAmountCBySellTokens(a0, a1, r0, r1);
    }

    function getTokenAmountToSellForAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint a, address _oracle, bytes32 _marketIdentifier) internal returns (uint tokenAmount) {
        (uint r0, uint r1) = getOutcomeTokensReserves(_oracle, _marketIdentifier);
        tokenAmount = Math.getTokenAmountToSellForAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
    }

    // function getMarketStage(address _oracle, bytes32 _marketIdentifier) internal view returns (uint8 stage) {
    //     uint[12] memory details = Market(_marketAddress).getMarketDetails();
    //     return uint8(details[11]);
    // }

    // function getMarketOutcome(address _marketAddress) internal view returns (uint8 outcome) {
    //     uint[12] memory details = Market(_marketAddress).getMarketDetails();
    //     return uint8(details[10]);
    // }

    // function getStakeAmount(address _marketAddress, uint _for, address _of) internal returns (uint){
    //     return Market(marketAddress).getStake(_for, _of);
    // }

    // function getTokenBalances(address _of) internal returns (uint balanceC, uint balance0, uint balance1) {
    //     (,address token0, address token1) = Market(marketAddress).getTokenAddresses();
    //     balanceC = MemeToken(memeToken).balanceOf(_of);
    //     balance0 = OutcomeToken(token0).balanceOf(_of);
    //     balance1 = OutcomeToken(token1).balanceOf(_of);
    // }

    function advanceBlocksBy(uint by) public {
        Hevm(hevm).roll(by);
    } 
}
