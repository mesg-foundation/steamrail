```
mesg-core start
mesg-core service dev \
  --env PROVIDER_ENDPOINT=https://ropsten.infura.io/v3/xxx \
  --env BLOCK_CONFIRMATIONS=2 \
  --env CONTRACT_ADDRESS=0x77a9de37aB5F4E7e9C9074928ca4A95aBF8e381d \
  --env CONTRACT_ABI="$(cat ./abi.json | jq .abi)" \
  https://github.com/mesg-foundation/service-ethereum-contract

echo "export PRIVATE_KEY=0xPRIVATE_KEY" >> .envrc
source .envrc
```

## Emittor
```
./emittor 0 taskX "{\"a\": 42}" 0x 0x,0x,0x
```

## Executor
```
./executor 0 taskX
```

## Validator
```
./validator 0 taskX
```