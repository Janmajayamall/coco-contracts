// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Math {
    function getAmountCToBuyTokens(uint a0, uint a1, uint r0, uint r1) internal pure returns (uint a){
        uint b;
        uint rootVal;
        uint s;
        assembly {
            // safe in total adds around 100
            function safeAdd(v1,v2) -> r {
                r := add(v1,v2)
                if or(lt(r,v1),lt(r,v2)) {revert(0,0)}
            }
            function safeMul(v1,v2) -> r {
                {
                    switch or(iszero(v1), iszero(v2))
                    case 1 {
                        r := 0
                    }
                    case 0 {
                        r := mul(v1,v2) 
                        if iszero(eq(v1, div(r,v2))) {revert(0,0)}
                    }
                }
            }
            {
                let r0Pr1 := safeAdd(r0,r1)
                let a0Pa1 := safeAdd(a0,a1)
                switch lt(r0Pr1, a0Pa1)
                case 1 {
                    s := 0
                    b := sub(a0Pa1,r0Pr1)
                }
                case 0 {
                    s := 1
                    b := sub(r0Pr1,a0Pa1)
                }
            }
            let g := safeMul(b,b)
            rootVal := sub(safeAdd(safeMul(b,b), safeMul(4, safeAdd(safeMul(r0,a1), safeMul(r1,a0)))), safeMul(4, safeMul(a0,a1)))
        }
        rootVal = sqrt(rootVal);
        assembly {
            function safeAdd(v1,v2) -> r {
                r := add(v1,v2)
                if or(lt(r,v1),lt(r,v2)) {revert(0,0)}
            }
            function safeSub(v1,v2) -> r {
                if lt(v1,v2) {revert(0,0)}
                r := sub(v1,v2)
            }
            {  
                switch s 
                case 0 {
                    a := div(safeAdd(b,rootVal), 2)
                    if or(lt(safeAdd(r0,a),a0), lt(safeAdd(r1,a),a1)){
                        a := div(safeSub(b,rootVal),2)
                    }
                }
                case 1 {
                    a := div(safeSub(rootVal,b),2)
                }
            }
            a := add(a,1)
        }

        // uint b;
        // uint sign;
        // if ((r0 + r1) >= (a0 + a1)){
        //     b = (r0 + r1) - (a0 + a1);
        //     sign = 1;
        // }
        // else {
        //     b = (a0 + a1) - (r0 + r1);
        //     sign = 0;
        // }
        // uint b2 = b**2;
        // uint rootVal = b2 + (4 * r0 * a1) + (4 * r1 * a0) - (4 * a0 * a1);
        // rootVal = sqrt(rootVal);
        // if (sign == 0){
        //     a = ((b + rootVal) / 2);
        //     if ((r0+a)<a0||(r1+a)<a1){
        //         require(b >= rootVal, 'ERR rootVal>b sign=0');
        //         a = ((b - rootVal)/2);
        //     }
        // }else {
        //     require(rootVal >= b, 'ERR b>rootVal sign=1');
        //     a = ((rootVal - b)/2);
        // }
        // a += 1;
    }

    function getTokenAmountToBuyWithAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint r0, uint r1, uint a) internal pure returns (uint tokenAmount){
        assembly {
            function safeAdd(v1,v2) -> r {
                r := add(v1,v2)
                if or(lt(r,v1),lt(r,v2)) {revert(0,0)}
            }
            function safeMul(v1,v2) -> r {
                {
                    switch or(iszero(v1), iszero(v2))
                    case 1 {
                        r := 0
                    }
                    case 0 {
                        r := mul(v1,v2) 
                        if iszero(eq(v1, div(r,v2))) {revert(0,0)}
                    }
                }
            }
            function safeSub(v1,v2) -> r {
                if lt(v1,v2) {revert(0,0)}
                r := sub(v1,v2)
            }

            if gt(fixedTokenIndex, 1) {revert(0,0)}
            let x
            let y
            {
                switch fixedTokenIndex
                case 0 { 
                    let denom := safeSub(safeAdd(r0,a),fixedTokenAmount)
                    if iszero(denom) {revert(0,0)}
                    x := safeAdd(r1,a)
                    y := div(safeMul(r1,r0),denom)
                }
                case 1 {
                    let denom := safeSub(safeAdd(r1,a),fixedTokenAmount)
                    if iszero(denom) {revert(0,0)}
                    x := safeAdd(r0,a)
                    y := div(safeMul(r0,r1),denom)
                }
            }
            if eq(x,y) {tokenAmount := 0}
            if iszero(eq(x,y)) {tokenAmount := safeSub(safeSub(x,y),1)}
        }
        // require(fixedTokenIndex < 2);
        // uint x;
        // uint y;
        // if(fixedTokenIndex == 0){
        //     // find a1
        //     x = r1 + a;
        //     require(r0 + a >= fixedTokenAmount, "INVALID");
        //     y = (r0 * r1)/(r0 + a - fixedTokenAmount);
        // }else{
        //     x = r0 + a;
        //     require(r1 + a >= fixedTokenAmount, "INVALID");
        //     y = (r0 * r1)/(r1 + a - fixedTokenAmount);
        // }

        // y += 1;
        // require(x > y, "INVALID INPUTS");
        // tokenAmount = x - y;
        // tokenAmount -= 1;
    }


    function getAmountCBySellTokens(uint a0, uint a1, uint r0, uint r1) internal pure returns (uint a) {
        uint nveB;
        uint rV;
        assembly {   
            function safeAdd(v1,v2) -> r {
                r := add(v1,v2)
                if or(lt(r,v1),lt(r,v2)) {revert(0,0)}
            }
            function safeMul(v1,v2) -> r {
                {
                    switch or(iszero(v1), iszero(v2))
                    case 1 {
                        r := 0
                    }
                    case 0 {
                        r := mul(v1,v2) 
                        if iszero(eq(v1, div(r,v2))) {revert(0,0)}
                    }
                }
            }
            function safeSub(v1,v2) -> r {
                if lt(v1,v2) {revert(0,0)}
                r := sub(v1,v2)
            }

            nveB := safeAdd(r0,safeAdd(a0, safeAdd(r1,a1)))
            rV := safeSub(safeMul(nveB, nveB), safeMul(4, safeAdd(safeMul(r0,a1), safeAdd(safeMul(r1,a0), safeMul(a0,a1))))) 
        }
        rV = sqrt(rV);
        assembly {
            function safeAdd(v1,v2) -> r {
                r := add(v1,v2)
                if or(lt(r,v1),lt(r,v2)) {revert(0,0)}
            }
            function safeMul(v1,v2) -> r {
                {
                    switch or(iszero(v1), iszero(v2))
                    case 1 {
                        r := 0
                    }
                    case 0 {
                        r := mul(v1,v2) 
                        if iszero(eq(v1, div(r,v2))) {revert(0,0)}
                    }
                }
            }
            function safeSub(v1,v2) -> r {
                if lt(v1,v2) {revert(0,0)}
                r := sub(v1,v2)
            }
            a := div(safeAdd(nveB, rV), 2)
            if or(lt(safeAdd(r0,a0), a),lt(safeAdd(r1,a1), a)) {
                a := div(safeSub(nveB, rV),2)
            }
            if iszero(eq(a, 0)) {a := safeSub(a,1)}
        }
        // uint nveB = r0 + a0 + r1 + a1;
        // uint c = (r0*a1) + (r1*a0) + (a0*a1);
        // uint rootVal = ((nveB**2) - (4 * c));
        // rootVal = sqrt(rootVal);
        // a = (nveB + rootVal)/2;
        // if ((r0+a0)<a || (r1+a1)<a){
        //     require(nveB > rootVal, 'ERR');
        //     a = (nveB - rootVal)/2;
        // }
        // a -= 1;
    }

    function getTokenAmountToSellForAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint r0, uint r1, uint a) internal pure returns (uint tokenAmount){
        assembly {
            function safeAdd(v1,v2) -> r {
                r := add(v1,v2)
                if or(lt(r,v1),lt(r,v2)) {revert(0,0)}
            }
            function safeMul(v1,v2) -> r {
                {
                    switch or(iszero(v1), iszero(v2))
                    case 1 {
                        r := 0
                    }
                    case 0 {
                        r := mul(v1,v2) 
                        if iszero(eq(v1, div(r,v2))) {revert(0,0)}
                    }
                }
            }
            function safeSub(v1,v2) -> r {
                if lt(v1,v2) {revert(0,0)}
                r := sub(v1,v2)
            }

            if gt(fixedTokenIndex, 1) {revert(0,0)}
            let x
            let y
            {
                switch fixedTokenIndex 
                case 0 {
                    let denom := safeSub(safeAdd(r0,fixedTokenAmount), a)
                    if iszero(denom) {revert(0,0)}
                    x := r1
                    y := div(mul(r0,r1),denom)
                }
                case 1 {
                    let denom := safeSub(safeAdd(r1,fixedTokenAmount), a)
                    if iszero(denom) {revert(0,0)}
                    x := r0
                    y := div(mul(r0,r1),denom)
                }
            }
            y := safeAdd(y,a)
            tokenAmount := safeAdd(safeSub(y,x),1)
        }
        // require(fixedTokenIndex < 2);
        // uint x;
        // uint y;
        // if(fixedTokenIndex == 0){
        //     x = r1;
        //     require(r0 + fixedTokenAmount > a, "INVALID");
        //     y = ((r0 * r1)/(r0 + fixedTokenAmount - a)) + a;
        // }else{
        //     x = r0;
        //     require(r1 + fixedTokenAmount > a, "INVALID");
        //     y = ((r0 * r1)/(r1 + fixedTokenAmount - a)) + a;
        // }

        // require(y >= x, "INVALID INPUTS");
        // tokenAmount = y - x;
        // tokenAmount += 1;
    }


    function sqrt(uint256 x) internal pure returns (uint256 n) {
        assembly {
            if iszero(x) {revert(0,0)}
            let xx := x
            let r := 1
            if gt(xx, 0x100000000000000000000000000000000) {
                xx := shr(128,xx)
                r := shl(64,r)
            }
            if gt(xx, 0x10000000000000000) {
                xx := shr(64,xx)
                r := shl(32,r)
            }
            if gt(xx, 0x100000000) {
                xx := shr(32,xx)
                r := shl(16,r)
            }
            if gt(xx, 0x10000) {
                xx := shr(16,xx)
                r := shl(8,r)
            }
            if gt(xx, 0x100) {
                xx := shr(8,xx)
                r := shl(4,r)
            }
            if gt(xx, 0x10) {
                xx := shr(4,xx)
                r := shl(2,r)
            }
            if gt(xx, 0x8) {
                r := shl(1,r)
            }

            // for {let i:=0} lt(i,7) {i := add(i,1)}
            // {
            //     r := shr(div(add(r,x),r),1)
            // }
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r))) // Seven iterations should be enough

            {
                switch lt(r, div(x,r))
                case 1 {
                    n := r
                }
                case 0 {
                    n := div(x,r)
                }
            }
        }
    }
}