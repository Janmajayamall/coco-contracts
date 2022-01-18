// SPDX-License-Identifier: MIT

import "./../interfaces/IOracle.sol";

pragma solidity ^0.8.0;

contract Caller {
    function isGoverningGroupMember(address user, address oracle) external returns (bool) {
        address safeWallet = IOracle(oracle).manager();
        (bool success,) = safeWallet.call(abi.encodeWithSignature("isOwner(address)", user));
        require(success, "Invalid Safe");
        return true;
    }
}
