// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Actor {
    event ActorCall(address to, bytes data, bool success);

    function send(address to, bytes memory data, bool result) public {
        (bool success, ) = to.call(data);
        emit ActorCall(to, data, success);
        require(success == result);
    }
}