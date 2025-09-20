RPC_URL=http://localhost:8545

WKAIA=0x19Aac5f612f524B754CA7e7c41cbFa2E981A4432
USDT=0xd077A400968890Eacc75cdc901F0356c943e4fDb

ACCOUNT_0=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
ACCOUNT_0_PRIV=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 # anvil default account 0. for dev only.

# Get WKAIA
cast send $WKAIA --from $ACCOUNT_0 "deposit()" --value 1000000000000000000000 --private-key $ACCOUNT_0_PRIV --rpc-url $RPC_URL # 1000 WKAIA

# Get USDT from whale
USDT_WHALE=0x74c4FA0a5d205b1E645c819F6dd5D436688aD3d5
cast rpc anvil_impersonateAccount $USDT_WHALE --rpc-url $RPC_URL
cast send $USDT --from $USDT_WHALE "transfer(address,uint256)(bool)" $ACCOUNT_0 1000000000000 --unlocked --rpc-url $RPC_URL



