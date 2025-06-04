## Prerequisites

Add `snfoundry.toml` file with following content:

```
[sncast.default]
account = "*name of your account from ~/.starknet_accounts/starknet_open_zeppelin_accounts.json*"
url = "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/*your api key*"
```

## Deployment and upgrades

Before deploying or upgrading the contract, make sure you have the latest class hash:

```
sncast declare --contract-name StorageProofs
```

Then copy the class hash and update it in `deploy.toml:3` and `upgrade.toml:5`

## Deploying new contract

Make sure that in `deploy.toml`:

1. First 2 input arguments of deploy call (lines 5 and 6) represent chain ID of the chain you want to deploy to encoded as u256.
2. Third input (line 7) is Starknet address of the contract owner.
3. Argument to `setL1MessageSender` function invocation (line 16) is address of satellite deployed on L1.

Then run:

```
sncast multicall run --path deploy.toml --fee-token eth
```

## Upgrading contract

Make sure that in `upgrade.toml` the first and only input argument is the address of deployed contract on Starknet.

Then run:

```
sncast multicall run --path upgrade.toml --fee-token eth
```
