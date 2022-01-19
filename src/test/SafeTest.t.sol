// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/SafeTestHelpers.sol";
import "./utils/OracleTestHelpers.sol";
import "./../proxies/OracleProxy.sol";
import "./../../lib/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "./../Oracle.sol";
import "./../../lib/safe-contracts/contracts/GnosisSafe.sol";
import "./../../lib/safe-contracts/contracts/common/Enum.sol";
contract SafeTest is OracleTestHelpers, SafeTestHelpers {

    address oracle;
    address gnosisSafe;
    address tokenC;

    uint constant testPvKey = 0xc5e1fdc2e99778a9e2ba50a393838fd3d0f71e0d0826ff2ab7d0ba55ac0dc37c;

    function setUp() public {
        address _oracleSingleton = address(deploySingleton());
        address _oracle = address(new OracleProxy(address(deploySingleton())));
        address _gnosisSafe = address(new GnosisSafeProxy(address(deploySafeSingleton())));
        tokenC = deloyAndPrepTokenC(address(this));

        // setup safe
        address[] memory owners = new address[](1);
        owners[0] = hevm.addr(testPvKey);
        bytes memory safeSetupCall = abi.encodeWithSelector(
            0xb63e800d, 
            owners,
            1,
            address(0),
            0,
            0,
            0,
            0,
            0
        );
        assembly {
            if eq(call(gas(), _gnosisSafe, 0, add(safeSetupCall, 0x20), mload(safeSetupCall), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // setup oracle
        bytes memory updateMarketConfigCall = abi.encodeWithSelector(
            0x94eb6f2f,
            true,
            1,
            10,
            5,
            10,
            10,
            10
        );
        assembly {
            if eq(call(gas(), _oracle, 0, add(updateMarketConfigCall, 0x20), mload(updateMarketConfigCall), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update collateral token
        // 0x29d06108 = Oracle.updateCollateralToken.selector
        bytes memory updateCollateralToken = abi.encodeWithSelector(0x29d06108, tokenC);
        assembly {
            if eq(call(gas(), _oracle, 0, add(updateCollateralToken, 0x20), mload(updateCollateralToken), 0, 0), 0) {
                revert(0, 0)
            }
        }

        // update manager
        // 0x58aba00f = Oracle.updateManager.selector
        bytes memory updateManagerCall = abi.encodeWithSelector(0x58aba00f,  _gnosisSafe);
        assembly {
            if eq(call(gas(), _oracle, 0, add(updateManagerCall, 0x20), mload(updateManagerCall), 0, 0), 0) {
                revert(0, 0)
            }
        }

        oracle = _oracle;
        gnosisSafe = _gnosisSafe;

    }

    // test authorised functions
    function test_updateManager() public {
        address payable _gnosisSafe = payable(gnosisSafe);
        address _oracle = oracle;

        // send tx
        bytes memory _calldata = abi.encodeWithSelector(Oracle.updateManager.selector, address(10));
        bool success = safeExecuteTx(_calldata, _oracle, _gnosisSafe);

        assertTrue(success);

        // check manager address = address(10)
        assertEq(Oracle(_oracle).manager(), address(10));
    }

    function getDigestSignature(bytes32 digest) internal returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(testPvKey, digest);
        signature = abi.encodePacked(r, s, v);
    }

    function safeExecuteTx(bytes memory _calldata, address _to, address payable _safe) internal returns (bool success) {
        bytes memory encodedData = GnosisSafe(_safe).encodeTransactionData(
            _to, 
            0,
            _calldata, 
            Enum.Operation(0), 
            0, 
            0, 
            0, 
            address(0), 
            payable(address(0)), 
            GnosisSafe(_safe).nonce()
        );
        bytes32 encodedDataHash = keccak256(encodedData);
        bytes memory signature = getDigestSignature(encodedDataHash);
        (success) = GnosisSafe(_safe).execTransaction(
            _to, 
            0,
            _calldata, 
            Enum.Operation(0), 
            0, 
            0, 
            0, 
            address(0), 
            payable(address(0)), 
            signature
        );
    }
}