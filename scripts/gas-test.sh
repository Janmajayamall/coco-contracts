#!/usr/bin/env bash

set -eo pipefail

# OracleFactory=0xa7db16a8b638607272eAdc1868A8fB28636e1Db2
# MemeToken=0xBfe0246EC0E26be71183E353a7abBf6a24327FA8
# MarketRouter=0xcFf9230502Bbf9B99b2513112F5734f6feC735E9
# DEPLOYER=0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6
# Oracle=0xc45c26f522f80fc78eef6fd70f8a076e0df8dd0c

# testnet
OracleFactory=0xd3831c6B11aCC11852B150c0d163A665DE07D461
MemeToken=0xAad1ec64896a2e4f74EE74C18aE6f64b02891C8c
MarketRouter=0x8E1c52251b71038AEcd1cd3182ec629285355AEc
DEPLOYER=0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6
Oracle1=0xb9181365C266cD4e361a455567B77a16bd8044a8


# # mint max meme tokens to user
# estimate=$(seth estimate $MemeToken "mint(address,uint256)" $DEPLOYER $(seth --max-uint 256))
# seth send $MemeToken "mint(address,uint256)" $DEPLOYER $(seth --max-uint 256) --gas $estimate

# # give max allowance to market router for MemeToken
# estimate=$(seth estimate $MemeToken "approve(address,uint256)" $MarketRouter $(seth --max-uint 256))
# seth send $MemeToken "approve(address,uint256)" $MarketRouter $(seth --max-uint 256) --gas $estimate

# # outcome token approval to market router
# estimate=$(seth estimate 0xc99f3f1b51fb9e2d9e0ce9df5e238ee9fc15670e "setApprovalForAll(address,bool)" $MarketRouter true)
# seth send 0xc99f3f1b51fb9e2d9e0ce9df5e238ee9fc15670e "setApprovalForAll(address,bool)" $MarketRouter true --gas $estimate

# place bet
# estimate=$(seth estimate $MarketRouter "buyMinTokensForExactCTokens(uint256,uint256,uint256,uint256,address,bytes32)" 2333333333333333332 0 1000000000000000000 1 $Oracle1 0x68ab41f4840f519085df46ea033c513f5e9bf271a134088d7a1590934328b863)


# create a new oracle
estimate=$(seth estimate $OracleFactory "createOracle(address,address,address,bool,uint32,uint32,uint16,uint32,uint32,uint32)" $DEPLOYER $DEPLOYER $MemeToken true 1 10 5 24 24 24)
seth send $OracleFactory "createOracle(address,address,address,bool,uint32,uint32,uint16,uint32,uint32,uint32)" $DEPLOYER $DEPLOYER $MemeToken true 1 10 5 24 24 24 --gas $estimate

# # create a new market
# estimate=$(seth estimate $MarketRouter "createFundBetOnMarket(bytes32,address,uint256,uint256,uint256)" $(seth --to-bytes32 $(seth --to-hex '31020192')) $Oracle1 $(seth --to-wei 1 eth) 0 1)
# seth send $MarketRouter "createFundBetOnMarket(bytes32,address,uint256,uint256,uint256)" $(seth --to-bytes32 $(seth --to-hex '310192120192')) $Oracle1 $(seth --to-wei 1 eth) $(seth --to-wei 1 eth) 1 --gas $estimate


# seth send 0xA9Eb99A58968aC261A5F74850691818Fd1C94175 "mint(address,uint256)" 0x93E3939a89769920a2b79C41e555118a2762cadA $(seth --max-uint 256)

# seth send --from 0x93E3939a89769920a2b79C41e555118a2762cadA --value 10 0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6

# 310192120192