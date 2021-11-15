// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../OracleMarkets.sol";
import "./../../libraries/Math.sol";
import "./../../MemeToken.sol";
import "./Hevm.sol";

contract OracleMarketsTestHelpers is DSTest, Hevm {

	struct OracleConfig {
		address tokenC;
		uint32 feeNumerator;
        uint32 feeDenominator;
        uint32 expireBufferBlocks;
        uint32 donBufferBlocks;
        uint32 resolutionBufferBlocks;
        uint16 donEscalationLimit;
        bool isActive;
	}

	struct MarketDetails {
		address tokenC;
        uint32 feeNumerator;
        uint32 feeDenominator;
	}

	struct StateDetails {
		uint32 expireAtBlock;
        uint32 donBufferEndsAtBlock;
        uint32 resolutionEndsAtBlock;
        uint32 donBufferBlocks; 
        uint32 resolutionBufferBlocks;
        uint16 donEscalationCount;
        uint16 donEscalationLimit;
        uint8 outcome;
        uint8 stage;
	}

	function createAndFundMarket(address _oracle, address _creator, bytes32 _eventIdentifier, uint fundAmount) public {
		address _tokenC = OracleMarkets(_oracle).collateralToken();
		IERC20(_tokenC).transfer(_oracle, fundAmount);
		OracleMarkets(_oracle).createAndFundMarket(_creator, _eventIdentifier);
	}

	function buy(address to, address _oracle, bytes32 _marketIdentifier, uint a0, uint a1) public returns(uint a) {
        address _tokenC = getTokenC(_oracle, _marketIdentifier);
		(uint r0, uint r1) = OracleMarkets(_oracle).outcomeReserves(_marketIdentifier);
		a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
		IERC20(_tokenC).transfer(_oracle, a);
		OracleMarkets(_oracle).buy(a0, a1, to, _marketIdentifier);
	}

	function sell(address to, address _oracle, bytes32 _marketIdentifier, uint a0, uint a1) public returns (uint a) {
		(uint r0, uint r1) = OracleMarkets(_oracle).outcomeReserves(_marketIdentifier);
		a = Math.getAmountCBySellTokens(a0, a1, r0, r1);

		(uint t0, uint t1) = OracleMarkets(_oracle).getOutcomeTokenIds(_marketIdentifier);
		OracleMarkets(_oracle).safeTransferFrom(to, _oracle, t0, a0, '');
		OracleMarkets(_oracle).safeTransferFrom(to, _oracle, t1, a1, '');

		OracleMarkets(_oracle).sell(a, to, _marketIdentifier);
	}

    function getTokenC(address _oracle, bytes32 _marketIdentifier) public view returns (address _tokenC) {
        (_tokenC,,) = getMarketDetails(_oracle, _marketIdentifier);
    }

    function getMarketDetails(address _oracle, bytes32 _marketIdentifier) public view returns (address, uint32, uint32) {
        return OracleMarkets(_oracle).marketDetails(_marketIdentifier);
    }

	function getMarketIdentifier(address _oracle, address _creator, bytes32 _eventIdentifier) public view returns (bytes32){
		return OracleMarkets(_oracle).getMarketIdentifier(_creator, _eventIdentifier);
	}

	function getOutcomeReserves(address _oracle,  bytes32 _marketIdentifier) public view returns (uint r0, uint r1) {
		(r0, r1) = OracleMarkets(_oracle).outcomeReserves(_marketIdentifier);
	}

	function getOutcomeTokenIds(address _oracle,  bytes32 _marketIdentifier) public pure returns (uint t0, uint t1) {
		(t0, t1) = OracleMarkets(_oracle).getOutcomeTokenIds(_marketIdentifier);
	}

	function getTokenCBalance(address _of, address _oracle,  bytes32 _marketIdentifier) public view returns (uint b) {
		address _tokenC = getTokenC(_oracle, _marketIdentifier);
		b = IERC20(_tokenC).balanceOf(_of);
	}

	function getOutcomeTokenBalance(address _of, address _oracle,  bytes32 _marketIdentifier) public view returns (uint bt0, uint bt1) {
		(uint t0, uint t1) = getOutcomeTokenIds(_oracle, _marketIdentifier);
		bt0 = OracleMarkets(_oracle).balanceOf(_of, t0);
		bt1 = OracleMarkets(_oracle).balanceOf(_of, t1);
	}

	function getStateDetail(address _oracle, bytes32 _marketIdentifier, uint index) public view returns(uint) {
		(
			uint32 expireAtBlock,
			uint32 donBufferEndsAtBlock,
			uint32 resolutionEndsAtBlock,
			uint32 donBufferBlocks,
			uint32 resolutionBufferBlocks,
			uint16 donEscalationCount,
			uint16 donEscalationLimit,
			uint8 outcome,
			uint8 stage
		) = OracleMarkets(_oracle).stateDetails(_marketIdentifier);

		if (index == 0) return expireAtBlock;
		if (index == 1) return donBufferEndsAtBlock;
		if (index == 2) return resolutionEndsAtBlock;
		if (index == 3) return donBufferBlocks;
		if (index == 4) return resolutionBufferBlocks;
		if (index == 5) return donEscalationCount;
		if (index == 6) return donEscalationLimit;
		if (index == 7) return outcome;
		if (index == 8) return stage;
        return 0;
	}

    function deloyAndPrepTokenC(address to) public returns (address _tokenC) {
        _tokenC = address(new MemeToken());
        MemeToken(_tokenC).mint(to, type(uint).max);
    }

	function checkReserves(address _oracle, bytes32 _marketIdentifier, uint er0, uint er1) public {
		(uint r0, uint r1) = getOutcomeReserves(_oracle, _marketIdentifier);
		assertEq(r0, er0);
        assertEq(r1, er1);
	} 

	function checkMarketDetails(address _oracle, bytes32 _marketIdentifier, MarketDetails memory _marketDetails) public {
		(address tokenC, uint32 feeNum, uint32 feeDenom) = getMarketDetails(_oracle, _marketIdentifier);
		assertEq(tokenC, _marketDetails.tokenC);
		assertEq(feeNum, _marketDetails.feeNumerator);
		assertEq(feeDenom, _marketDetails.feeDenominator);
	}

	function checkExpireAtBlock(address _oracle, bytes32 _marketIdentifier, uint _block) public {
		assertEq(getStateDetail(_oracle, _marketIdentifier, 0), _block);
	}

	function checkDonBufferEndsAtBlock(address _oracle, bytes32 _marketIdentifier, uint _block) public {
		assertEq(getStateDetail(_oracle, _marketIdentifier, 1), _block);
	}

	function checkResolutionEndsAtBlock(address _oracle, bytes32 _marketIdentifier, uint _block) public {
		assertEq(getStateDetail(_oracle, _marketIdentifier, 2), _block);
	}

	function checkOutcome(address _oracle, bytes32 _marketIdentifier, uint outcome) public {
		assertEq(getStateDetail(_oracle, _marketIdentifier, 7), outcome);
	}

	function checkStage(address _oracle, bytes32 _marketIdentifier, uint stage) public {
		assertEq(getStateDetail(_oracle, _marketIdentifier, 8), stage);
	}

	function checkEscalationCount(address _oracle, bytes32 _marketIdentifier, uint count) public {
		assertEq(getStateDetail(_oracle, _marketIdentifier, 5), count);
	}

	function checkOutcomeTokenBalance(address _of, address _oracle, bytes32 _marketIdentifier, uint et0, uint et1) public {
		(uint t0, uint t1) = getOutcomeTokenIds(_oracle, _marketIdentifier);
		assertEq(OracleMarkets(_oracle).balanceOf(_of, t0), et0);
		assertEq(OracleMarkets(_oracle).balanceOf(_of, t1), et1);
	}

	function checkTokenCBalance(address _of, address _oracle, bytes32 _marketIdentifier, uint eb) public {
		assertEq(getTokenCBalance(_of, _oracle, _marketIdentifier), eb);
	}

	// function checkStateDetails(address _oracle, bytes32 _marketIdentifier, StateDetails memory _stateDetails) public {
	// 	(
	// 		uint32 expireAtBlock,
	// 		uint32 donBufferEndsAtBlock,
	// 		uint32 resolutionEndsAtBlock,
	// 		uint32 donBufferBlocks,
	// 		uint32 resolutionBufferBlocks,
	// 		uint16 donEscalationCount,
	// 		uint16 donEscalationLimit,
	// 		uint8 outcome,
	// 		uint8 stage
	// 	) = OracleMarkets(_oracle).stateDetails(_marketIdentifier);
	// }
}
