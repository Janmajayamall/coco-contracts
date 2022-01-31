// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGnosisSafe {
    function isOwner(address owner) external view returns (bool);
    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures) external view;
}