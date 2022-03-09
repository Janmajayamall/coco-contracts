// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../libraries/test.sol";

contract Hevm is DSTest {
    // sets the block timestamp to x
    // function warp(uint256 x) public virtual;

    constructor(){}

    // sets the block number to x
    function roll(uint256 x) public {
        (bool success, ) = HEVM_ADDRESS.call(abi.encodeWithSignature("roll(uint256)", x));
        require(success);
    }

    // sets the slot loc of contract c to val
    // function store(
    //     address c,
    //     bytes32 loc,
    //     bytes32 val
    // ) public virtual;

    // function ffi(string[] calldata) external virtual returns (bytes memory);
}
