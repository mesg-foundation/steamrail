```
mesg-core start
mesg-core service deploy https://github.com/mesg-foundation/service-ethereum --env PROVIDER_ENDPOINT=https://ropsten.infura.io/v3/xxx
echo "export PRIVATE_KEY=0xPRIVATE_KEY" >> .envrc
source .envrc
mesg-core service start com.mesg.ethereum
```