// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/GroupMarket.sol";

abstract contract GroupSigning {
    enum Scheme {
        Eip712,
        EthSign,
        Eip1271
    }


    bytes32 private constant DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant DOMAIN_NAME = keccak256("Group Router");

    bytes32 private constant DOMAIN_VERSION = keccak256("v1");

    bytes32 domainSeparator;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );
    }

    // TODO finish this
    function recoverSigner(
        GroupMarket.MarketData memory marketData,
        bytes calldata signature,
        Scheme scheme
    ) public view returns (address owner){

    }

}