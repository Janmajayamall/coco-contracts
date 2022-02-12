// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./Group.sol"; // replace with group interface

import "./GroupSigning.sol";

import "./libraries/GroupMarket.sol";
import "./libraries/Transfers.sol";

contract GroupRouter is GroupSigning {

    using Transfers for IERC20;
    
    function createAndBetOnMarket(
        GroupMarket.MarketData memory marketData,
        bytes calldata signature,
        uint256 challengeAmount
    ) external {
        address creator = recoverSigner(marketData, signature, Scheme.EthSign);

        address cToken = Group(marketData.group).collateralToken();

        // transfer amount from creator & challenger
        IERC20(cToken).safeTransferFrom(creator, marketData.group, marketData.fundingAmount + marketData.amount1);
        IERC20(cToken).safeTransferFrom(msg.sender, marketData.group, challengeAmount);
        
        // call market creation
        Group(marketData.group).createMarket(
            marketData.marketIdentifier,
            creator,
            msg.sender,
            marketData.fundingAmount,
            challengeAmount, 
            marketData.amount1
        );
    }



}