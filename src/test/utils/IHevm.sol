// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "ds-test/test.sol";

interface IHevm {
    // sets the block number to x
    function roll(uint256 x) external;
    function sign(uint sk, bytes32 digest) external returns (uint8 v, bytes32 r, bytes32 s);
    function addr(uint sk) external returns (address addr);

}
