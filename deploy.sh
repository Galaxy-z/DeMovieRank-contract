source .env

# 构建合约
forge build

# 部署合约
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast -vvvvv

# 同步 ABI 和地址到前端
node scripts/export-abi.mjs 31337