// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./../Oracle.sol";
import "ds-test/test.sol";

interface Caller {
    function data() external view returns(address,address);
}

contract Useless1 {

    address d;
    address f;
    
    constructor() {
        (d, f) = Caller(msg.sender).data();
    }
}


contract Useless2 {

    address d;
    address f;
    
    constructor(address _d, address _f) {
        d = _d;
        f = _f;
    }
}

contract Normal is DSTest {

    struct Data {
        address a;
        address b;
    }


    Data public data;

    function setUp() public {

    }

    function test_create1() public {
        address _a = address(1);
        address _b = address(2);
        data = Data({
            a: _a,
            b: _b
        });
        address d = address(new Useless1{salt:keccak256(abi.encodePacked(_a,_b))}());
        delete data;
    }

    function test_create2() public {
        address a = address(1);
        address b = address(2);
        address d = address(new Useless2{salt:keccak256(abi.encodePacked(a,b))}(a, b));
    }
}