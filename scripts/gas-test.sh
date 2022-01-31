#!/usr/bin/env bash

set -eo pipefail

# OracleFactory=0xa7db16a8b638607272eAdc1868A8fB28636e1Db2
# MarketRouter=0xcFf9230502Bbf9B99b2513112F5734f6feC735E9
# DEPLOYER=0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6
# Oracle=0xc45c26f522f80fc78eef6fd70f8a076e0df8dd0c

# testnet
OracleFactory=0x856D7C8d6eF7438690B99F05EDdcA67F35ca139E
MarketRouter=0x42F7C9c294d9058a2264937C25a1B2a5538eEE92
DEPLOYER=0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6
# Oracle1=
TokenDistributor=0x96BDc3F593F82fa355DE1174E140DCEf99Fe102D


# mint max meme tokens to token distributor
# estimate=$(seth estimate $MemeToken "mint(address,uint256)" $TokenDistributor $(seth --max-uint 256))
# seth send $MemeToken mint(address,uint256)" $TokenDistributor $(seth --max-uint 256) --gas $estimate

# # give max allowance to market router for MemeToken
# estimate=$(seth estimate $MemeToken "approve(address,uint256)" $MarketRouter $(seth --max-uint 256))
# seth send $MemeToken "approve(address,uint256)" $MarketRouter $(seth --max-uint 256) --gas $estimate

# # outcome token approval to market router
# estimate=$(seth estimate 0xc99f3f1b51fb9e2d9e0ce9df5e238ee9fc15670e "setApprovalForAll(address,bool)" $MarketRouter true)
# seth send 0xc99f3f1b51fb9e2d9e0ce9df5e238ee9fc15670e "setApprovalForAll(address,bool)" $MarketRouter true --gas $estimate

# place bet
# estimate=$(seth estimate $MarketRouter "buyMinTokensForExactCTokens(uint256,uint256,uint256,uint256,address,bytes32)" 2333333333333333332 0 1000000000000000000 1 $Oracle1 0x68ab41f4840f519085df46ea033c513f5e9bf271a134088d7a1590934328b863)

# # create a new oracle
# estimate=$(seth estimate $OracleFactory "createOracle(address,address,address,bool,uint32,uint32,uint16,uint32,uint32,uint32)" $DEPLOYER $DEPLOYER $MemeToken true 1 10 5 24 24 24)
# seth send $OracleFactory "createOracle(address,address,address,bool,uint32,uint32,uint16,uint32,uint32,uint32)" $DEPLOYER $DEPLOYER $MemeToken true 1 10 5 24 24 24 --gas $estimate

# # create a new market
# estimate=$(seth estimate $MarketRouter "createFundBetOnMarket(bytes32,address,uint256,uint256,uint256)" $(seth --to-bytes32 $(seth --to-hex '31020192')) $Oracle1 $(seth --to-wei 1 eth) 0 1)
# seth send $MarketRouter "createFundBetOnMarket(bytes32,address,uint256,uint256,uint256)" $(seth --to-bytes32 $(seth --to-hex '310192120192')) $Oracle1 $(seth --to-wei 1 eth) $(seth --to-wei 1 eth) 1 --gas $estimate

# # claim tokens
# estimate=$(seth estimate $TokenDistributor "claim(address,uint256)" $DEPLOYER $(seth --to-wei 1 eth))
# seth send $TokenDistributor "claim(address,uint256)" $DEPLOYER $(seth --to-wei 1 eth) --gas $estimate

# create new gnosis safe

ARB_RINKEBY_SAFE_PROXY_FACTORY=0xdab2a175778821840db4a839301ffc1693cf1792
ARB_RINKEBY_SAFE_SINGLETON=0xb28cBabDf7b55336C02a751b6AD3Ac342fD6eEec
# estimate=$(seth estimate $RINKEBY_SAFE_PROXY_FACTORY "createProxyWithNonce(address,bytes,uint256)" $RINKEBY_SAFE_SINGLETON "" 12)

# estimate 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2 "createProxyWithNonce(address,bytes,uint256)" 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552 "" 13

# send 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2 "createProxyWithNonce(address,bytes,uint256)" 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552 "" 12 --gas 250000 --private-key bff706dc5bb72ac228325d17223776d6474a8ad0c2f6dec26838840bac652b7b 
