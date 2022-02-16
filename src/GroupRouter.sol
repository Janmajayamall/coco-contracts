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

    function createAndChallengeMarket(
        GroupMarket.MarketData memory marketData,
        bytes calldata signature,
        Scheme signatureScheme,
        uint256 challengeAmount
    ) external {
        address creator = recoverSigner(marketData, signature, signatureScheme);
        address tokenC = IGroup(marketData.group).collateralToken();

        // transfer amount from creator & challenger
        IERC20(tokenC).safeTransferFrom(creator, marketData.group, marketData.amount1);
        IERC20(tokenC).safeTransferFrom(msg.sender, marketData.group, challengeAmount);

        // call market creation
        IGroup(marketData.group).createMarket(
            marketData.marketIdentifier,
            creator, 
            msg.sender,
            challengeAmount, 
            marketData.amount1
        );
    }

    function challenge(
        address group,
        bytes32 marketIdentifier,
        uint8 _for,
        uint256 amountIn
    ) external {
        (address tokenC,,) = IGroup(group).marketDetails(marketIdentifier);
        IERC20(tokenC).safeTransferFrom(msg.sender, group, amountIn);
        IGroup(group).challenge(_for, marketIdentifier, msg.sender);
    }
}