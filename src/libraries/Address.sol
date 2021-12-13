pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool){
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}