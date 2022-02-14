// SPDX-License-Identifier: MIT

import "./../interfaces/IGroup.sol";
import "./../interfaces/IGnosisSafe.sol";

pragma solidity ^0.8.0;

contract Caller {
    function isGoverningGroupMember(address user, address oracle) external view returns (bool) {
        address safeWallet = IGroup(oracle).manager();
        bool isOwner = IGnosisSafe(safeWallet).isOwner(user);
        return isOwner;
    }

    function marketExistsInOracle(address oracle, bytes32 marketIdentifier) external view returns (bool){
        // address creator = IGroup(oracle).creators(marketIdentifier);
        // if (creator != address(0)){
        //     return true;
        // }
        return false;
    }

    function manager(address oracle) external view returns (address){
        return IGroup(oracle).manager();
    }

    function didReceivedEnoughSignatures(bytes memory data, bytes memory signatures, address oracle) external view returns (bool){
        address safeWallet = IGroup(oracle).manager();
        IGnosisSafe(safeWallet).checkSignatures(keccak256(data), data, signatures);
        return true;
    }
}
