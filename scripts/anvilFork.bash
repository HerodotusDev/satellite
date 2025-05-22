if [ -z "$1" ]; then
    echo "Error: Chain ID argument is required."
    echo "Usage: bun anvil:fork <chain_id>"
    exit 1
fi

anvil --fork-url $(CHAIN_ID=$1 bun hardhat run scripts/getRpcUrl.ts)
