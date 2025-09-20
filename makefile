-include .env
.EXPORT_ALL_VARIABLES:

anvil:
	anvil --chain-id 1337 --fork-url ${MAINNET_RPC_URL} --code-size-limit 65000

deploy-local-genev:
	forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key ${PRIVATE_KEY}

setup-balance:
	./script/setup-balance.sh

deploy-local-metamorpho:
	forge script script/DeployMetaMorpho.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key ${PRIVATE_KEY}

deploy-local:
	forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key ${PRIVATE_KEY} && \
	./script/setup-balance.sh && \
	forge script script/DeployMetaMorpho.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key ${PRIVATE_KEY}

deploy-mainnet-genev:
	forge script script/Deploy.s.sol --rpc-url ${MAINNET_RPC_URL} --broadcast --private-key ${PRIVATE_KEY}

deploy-mainnet-metamorpho:
	forge script script/DeployMetaMorpho.s.sol --rpc-url ${MAINNET_RPC_URL} --broadcast --private-key ${PRIVATE_KEY} --gas-limit 100000

verify:
	./script/verify.sh

test-lens:
	forge test --fork-url ${MAINNET_RPC_URL} test/forge/ReadVaults.t.sol -vvv