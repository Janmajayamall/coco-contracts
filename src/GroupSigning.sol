// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/GroupMarket.sol";
import "./interfaces/IEIP1271Verifier.sol";

/// ref - https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/mixins/GPv2Signing.sol
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

    uint256 private constant ECDSA_SIGNATURE_LENGTH = 65;

    bytes32 public domainSeparator;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        // TODO fix this
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

    
    function recoverSigner(
        GroupMarket.MarketData memory marketData,
        bytes calldata signature,
        Scheme scheme
    ) public view returns (address owner){
        bytes32 digest = GroupMarket.hash(marketData, domainSeparator);
        if (scheme == Scheme.Eip712) {
            owner = recoverEip712Signer(digest, signature);
        } else if (scheme == Scheme.EthSign) {
            owner = recoverEthsignSigner(digest, signature);
        } else if (scheme == Scheme.Eip1271) {
            owner = recoverEip1271Signer(digest, signature);
        }
    }

    function ecdsaRecover(bytes32 message, bytes calldata encodedSignature)
        internal
        pure
        returns (address signer)
    {
        require(
            encodedSignature.length == ECDSA_SIGNATURE_LENGTH,
            "Malformed ecdsa signature"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // r = uint256(encodedSignature[0:32])
            r := calldataload(encodedSignature.offset)
            // s = uint256(encodedSignature[32:64])
            s := calldataload(add(encodedSignature.offset, 32))
            // v = uint8(encodedSignature[64])
            v := shr(248, calldataload(add(encodedSignature.offset, 64)))
        }

        signer = ecrecover(message, v, r, s);
        require(signer != address(0), "GPv2: invalid ecdsa signature");
    }

    function recoverEip712Signer(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal pure returns (address owner) {
        owner = ecdsaRecover(orderDigest, encodedSignature);
    }

    function recoverEthsignSigner(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal pure returns (address owner) {
        // The signed message is encoded as:
        // `"\x19Ethereum Signed Message:\n" || length || data`, where
        // the length is a constant (32 bytes) and the data is defined as:
        // `orderDigest`.
        bytes32 ethsignDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", orderDigest)
        );

        owner = ecdsaRecover(ethsignDigest, encodedSignature);
    }

    function recoverEip1271Signer(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal view returns (address owner) {
        assembly {
            // owner = address(encodedSignature[0:20])
            owner := shr(96, calldataload(encodedSignature.offset))
        }

        bytes calldata signature = encodedSignature[20:];

        require(
            IEIP1271Verifier(owner).isValidSignature(orderDigest, signature) ==
                GroupEIP1271.MAGICVALUE,
            "GPv2: invalid eip1271 signature"
        );
    }
}