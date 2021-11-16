// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Actor {
    function send(address to, bytes memory data, bool result) public {
        (bool success, ) = to.call(data);
        require(success == result);
    }
}