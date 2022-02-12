// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IGroupErrors {
    error UnAuthenticated();
    error ZeroManagerAddress();
    error GroupInActive();

    error MarketExists();
    error CreateMarketAmountsMismatch();
    error ZeroAmount();
    error MarketPeriodExpired();
    error MarketBufferPeriodExpired();
    error MarketResolutionPeriodExpired();
    error MarketNotResolved();
    error BuyFPMMInvarianceViolated();
    error SellFPMMInvarianceViolated();
    error OutcomeAlreadySet();
    error InvalidOutcome();
    error InvalidTokenIndex();
    error OutcomeNotSet();
    error BalanceError();

    error ZeroPeriodBuffer();
    error ZeroEscalationLimit();
    error InvalidFee();
}