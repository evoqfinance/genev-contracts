OWNER=
METAMORPHO=
MORPHO=
ASSET=


forge verify-contract --chain kaia --watch $METAMORPHO MetaMorphoV1_1 \
    --constructor-args $(cast abi-encode "constructor(address,address,uint256,address,string,string)" \
    "$OWNER" \
    "$MORPHO" \
    "0" \
    "$ASSET" \
    "MetaMorpho Vault USDT" \
    "MMUSDT") \
    --show-standard-json-input