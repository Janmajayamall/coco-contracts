// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IOracle.sol';
import './interfaces/IERC20.sol';


contract OracleHelper {
    function getLatestBlock() view external returns (uint){
        return block.number;
    }
}