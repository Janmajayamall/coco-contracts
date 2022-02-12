// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IGroup.sol"; 
import "./interfaces/IERC1155.sol";

import "./GroupSigning.sol";

import "./libraries/GroupMarket.sol";
import "./libraries/Transfers.sol";

contract GroupRouter is GroupSigning {

    using Transfers for IERC20;

    // ERRORS
    error InvalidTokenIndex();
    error TradeConditionViolated();

    function calculateToken0Out(uint256 a, uint256 r0, uint256 r1) internal pure returns (uint256 x){
        x = r0 + a - ((r0 * r1) / (r1 + a));
    }

    function getOutcomeTokenIds(
        bytes32 marketIdentifier
    ) internal pure returns (uint,uint) {
        return (
            uint256(keccak256(abi.encode(marketIdentifier, 0))),
            uint256(keccak256(abi.encode(marketIdentifier, 1)))
        );
    }
    
    function createAndBetOnMarket(
        GroupMarket.MarketData memory marketData,
        bytes calldata signature,
        uint256 challengeAmount
    ) external {
        address creator = recoverSigner(marketData, signature, Scheme.EthSign);
        address cToken = IGroup(marketData.group).collateralToken();

        // transfer amount from creator & challenger
        IERC20(cToken).safeTransferFrom(creator, marketData.group, marketData.fundingAmount + marketData.amount1);
        IERC20(cToken).safeTransferFrom(msg.sender, marketData.group, challengeAmount);
        
        // call market creation
        IGroup(marketData.group).createMarket(
            marketData.marketIdentifier,
            creator,
            msg.sender,
            marketData.fundingAmount,
            challengeAmount, 
            marketData.amount1
        );
    }

    function buyMinOutcomeTokensWithFixedAmount(
        IGroup group,
        bytes32 marketIdentifier,
        uint256 minTokenOut,
        uint256 tokenIndex, 
        uint256 amountIn
    ) external {
        // outcome reserves
        (uint256 r0, uint256 r1) = group.outcomeReserves(marketIdentifier);

        // calculate out amount
        uint256 a0;
        uint256 a1;
        if (tokenIndex == 0){
            a0 = calculateToken0Out(amountIn, r0, r1);
        }else if (tokenIndex == 1){
            a1 = calculateToken0Out(amountIn, r1, r0);
        }else {
            revert InvalidTokenIndex();
        }

        // check min amount out condition
        if (a0+a1 < minTokenOut) revert TradeConditionViolated();

        // transfer
        (address tokenC,) = group.marketDetails(marketIdentifier);
        IERC20(tokenC).safeTransferFrom(msg.sender, address(group), amountIn);

        // buy
        group.buy(a0, a1, msg.sender, marketIdentifier);
    }

    function redeemWins(
        IGroup group,
        bytes32 marketIdentifier,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) public {
        // transfer token amount
        (uint256 t0Id, uint256 t1Id) = getOutcomeTokenIds(marketIdentifier);
        if (tokenIndex == 0){
            group.safeTransferFrom(msg.sender, address(this), t0Id, tokenAmount, '');
        }else if (tokenIndex == 1){
            group.safeTransferFrom(msg.sender, address(this), t1Id, tokenAmount, '');
        }

        group.redeemWins(marketIdentifier, tokenIndex, msg.sender);
    }

    function redeemStake(
        IGroup group,
        bytes32 marketIdentifier
    ) public {
        group.redeemStake(marketIdentifier, msg.sender);
    }

    function redeemWinsAndStake(
        IGroup group,
        bytes32 marketIdentifier,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external {
        redeemWins(group, marketIdentifier, tokenAmount, tokenIndex);
        redeemStake(group, marketIdentifier);
    }
}