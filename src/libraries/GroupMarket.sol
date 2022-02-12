// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library GroupMarket {
    struct MarketData {
        address group;
        bytes32 marketIdentifier;
        uint256 fundingAmount;
        uint256 amount1;
    }

    bytes32 internal constant TYPE_HASH = hex"290101"; // TODO correct the TYPE_HASH

    function hash(
            MarketData memory market, 
            bytes32 domainSeparator
        ) 
        internal 
        pure 
        returns (bytes32 marketDigest) {
        assembly {  
            // calculate datahash
            let start := sub(market, 32)
            mstore(start, TYPE_HASH)
            let dataHash := keccak256(start, 160) // TODO correct the length of GroupMarket
            
            // calculate digest 
            let freePointer := mload(0x40)  
            mstore(freePointer, "\x19\x01")
            mstore(add(freePointer, 2), domainSeparator)
            mstore(add(freePointer, 34), dataHash)
            marketDigest := keccak256(freePointer, 66)
        }
    }

    
}
