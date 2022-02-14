// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IGroupErrors {
    error UnAuthenticated();
    error ZeroManagerAddress();
    error GroupInActive();
    error MarketExists();
    error CreateMarketAmountsMismatch();
    error ZeroAmount();
    error AmountNotDouble();
    error InvalidOutcome();
    error InvalidChallengeCall();
    error InvalidRedeemCall();
    error InvalidSetOutcomeCall();
    error OutcomeNotSet();
    error BalanceError();
    error ZeroPeriodBuffer();
    error InvalidFee();
}