export ETH_RPC_URL=https://testnet.redditspace.com/rpc
export RUST_BACKTRACE=full

privateKey=bff706dc5bb72ac228325d17223776d6474a8ad0c2f6dec26838840bac652b7b

# deploy necessary contracts first
# forge create GroupProxyFactory --private-key $privateKey --legacy
# forge create Group --private-key $privateKey --legacy
# forge create GroupRouter --private-key $privateKey --legacy

# this comes after first
DEPLOYER=0xed53fa304E7fcbab4E8aCB184F5FC6F69Ed54fF6
GroupProxyFactory=0x5ea3dfeef2e8450dcb131d318822f365821c1aa2
GroupSingleton=0x08c7eb16acdc59d14a1eb11ed8aa30992a66a44f
GroupRouter=0x492fda2ecf1a53117db525049d7078f988f13b1e
Token=0xeae79885EEeb85d6cbc8D6aF6C65ec40b2b0e38a


# 31536000 seconds = 365 days
# groupConfigData=$(cast abi-encode "f(bool,uint64,uint64,uint64)" true 0 86400 31536000)

# group=$(cast send $GroupProxyFactory "createGroupWithManager(address,address,address,uint256,bytes calldata)" $DEPLOYER $GroupSingleton $Token 100000000000000000000 $groupConfigData --legacy --private-key $privateKey)
# echo $group


# RedditGroup=0xd426ad04563974a6a3ed01b967a963fa2b6f7df0
