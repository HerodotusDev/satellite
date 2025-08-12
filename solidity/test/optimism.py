from eth_abi import encode
from web3 import Web3

# Calculate startingOutputRoot

# Input values (replace as needed)
version_byte = "0x" + "00" * 32
state_root = "0x40655b0436dfae813e93a7ec12c004b9e13cee2ceae13a844b1cfb8cedd5a8df"
withdrawal_storage_root = "0xd1a78ebd597d711637f941bae14fd04357b5b57a82f64137e09bf484a25b3805"
latest_block_hash = "0xf9f0a4dc5a0186365a0c4404bcab4d73b38aa2a46484375716a2e4fdcc4eaa30"

# ABI-encode the 3 fields (bytes32, bytes32, bytes32)
payload = encode(
    ["bytes32", "bytes32", "bytes32"],
    [bytes.fromhex(state_root[2:]), bytes.fromhex(withdrawal_storage_root[2:]), bytes.fromhex(latest_block_hash[2:])]
)

# Concatenate version byte with payload
full_input = bytes.fromhex(version_byte[2:]) + payload

# Compute keccak256 hash
output_root = Web3.keccak(full_input).hex()

# Print output
print("Version Byte:         ", version_byte)
print("Payload (3 fields):   ", '0x' + payload.hex())
print("Full Input to Keccak: ", '0x' + full_input.hex())
print("Output Root:          ", output_root)


# Calculate rootClaim

# Input values (replace as needed)
version_byte = "0x" + "00" * 32
state_root = "0x9b6e4ad484ec7c79db5954a4d59a8d0bdd98eb33a3a0ba07f5bd401a4f7f5a2b"
withdrawal_storage_root = "0xb8b31ef2ac71ab2275dc158d5ba44aa8dd740daeb47d9fc9ea34e46cb405d38a"
latest_block_hash = "0xed391e70f841fe15006abb5d619572702269641cde267d5c9f035d1eed678adc"

# ABI-encode the 3 fields (bytes32, bytes32, bytes32)
payload = encode(
    ["bytes32", "bytes32", "bytes32"],
    [bytes.fromhex(state_root[2:]), bytes.fromhex(withdrawal_storage_root[2:]), bytes.fromhex(latest_block_hash[2:])]
)

# Concatenate version byte with payload
full_input = bytes.fromhex(version_byte[2:]) + payload

# Compute keccak256 hash
output_root = Web3.keccak(full_input).hex()

# Print output
print("Version Byte:         ", version_byte)
print("Payload (3 fields):   ", '0x' + payload.hex())
print("Full Input to Keccak: ", '0x' + full_input.hex())
print("Output Root:          ", output_root)


# ========================

# https://<l2-indexer-url>/output-root?network=optimism_mainnet&l2_block=121524816

version_byte = "0x" + "00" * 32
state_root = "0x8cd5c86564142d3020554cffa6b3591a6a8d2f7b8ec2d263863f29e0ab6de222"
withdrawal_storage_root = "0x8ebc68365e414b7382e25ceed949cd8cbdf68c69e760c84d2c38ffe009452f54"
latest_block_hash = "0xc72e9ee468bcf8d5832cb48eec27270e1675d25a32bd7e90b299bcffd730f3e2"

# ABI-encode the 3 fields (bytes32, bytes32, bytes32)
payload = encode(
    ["bytes32", "bytes32", "bytes32"],
    [bytes.fromhex(state_root[2:]), bytes.fromhex(withdrawal_storage_root[2:]), bytes.fromhex(latest_block_hash[2:])]
)

# Concatenate version byte with payload
full_input = bytes.fromhex(version_byte[2:]) + payload

# Compute keccak256 hash
output_root = Web3.keccak(full_input).hex()

# Print output
print("Version Byte:         ", version_byte)
print("Payload (3 fields):   ", '0x' + payload.hex())
print("Full Input to Keccak: ", '0x' + full_input.hex())
print("Output Root:          ", '0x' + output_root)