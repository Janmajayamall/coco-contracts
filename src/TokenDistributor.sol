// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IERC20.sol';

contract TokenDistributor {
    address public owner;
    IERC20 token;
    mapping(address=>uint256) public claims;
    uint256 public claimLimit = 1000*10**18; // 1000 TOKENS

    constructor(IERC20 _token){
        token  = _token;
        owner = msg.sender;
    }

    modifier _isOwner(){
        require(owner == msg.sender, "Access: Invalid!");
        _;
    }

    function claim(address to, uint256 amount) external {
        uint256 currentClaim = claims[to];
        require(currentClaim+amount<=claimLimit, "CLAIM LIMIT EXCEEDED");
        token.transfer(to, amount);
        claims[to]=currentClaim+amount;
    }

    function updateClaimLimit(uint256 to) external _isOwner {
        require(to > claimLimit);
        claimLimit = to;
    }

    function transferAll() external _isOwner { 
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function transferOwnership(address to) external _isOwner {
        owner = to;
    }
}