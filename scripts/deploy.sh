export ETH_RPC_URL=https://rinkeby.arbitrum.io/rpc
export RUST_BACKTRACE=full

DEPLOYER=0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6
GroupProxyFactory=0x76d36ed79eedfdb6b770b3a55b8e8dd43b226744
GroupSingleton=0x851454a874d9367d4537192ae2b46087140a67b1
GroupRouter=0x6a9b3c98cecb2ab2dfb14418950c5fe79aa94600
FakeWETH=0xc99ce855c5051fed2b9a84595f312ef3832e38c8
RedditGroup=0xd426ad04563974a6a3ed01b967a963fa2b6f7df0

privateKey=bff706dc5bb72ac228325d17223776d6474a8ad0c2f6dec26838840bac652b7b


groupConfigData=$(cast abi-encode "f(bool,uint64,uint64,uint64)" true 0 86400 18446744073709551615)

group=$(cast send $GroupProxyFactory "createGroupWithManager(address,address,address,uint256,bytes calldata)" $DEPLOYER $GroupSingleton $FakeWETH 100000000000000000000 $groupConfigData --legacy --private-key $privateKey) 
echo $group

# deploy Group Singleton
# out=$(forge create Group)
# echo $out

# deploy Group Proxy Factory


# deploy Group Routerfor