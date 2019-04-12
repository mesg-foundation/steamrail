const { asciiToHex, hexToAscii } = require('web3-utils')

const mesg = require('mesg-js').application({
  endpoint: process.env.MESG_CLIENT_ADDRESS
})

const serviceID = 'com.mesg.ethereum'
const abi = require('./abi.json').abi

const execute = async (service, servicetask, callback) => {
  mesg.listenEvent({
    serviceID,
    eventFilter: 'log'
  }).on('data', async data => {
    const event = JSON.parse(data.eventData)
    if (event.address.toLowerCase() !== service.toLowerCase()) { return }

    const decode = await mesg.executeTaskAndWaitResult({
      serviceID,
      taskKey: 'decodeLog',
      inputData: JSON.stringify({
        ...event,
        abi: abi.filter(x => x.name === 'Created')[0]
      })
    })

    if (decode.outputKey === 'error') { throw new Error('error when decode logs') }
    const result = JSON.parse(decode.outputData)
    const { executionId, inputs } = result.decodedData

    try {
      const outputs = await callback(JSON.parse(hexToAscii(inputs)))

      const tx = await mesg.executeTaskAndWaitResult({
        serviceID,
        taskKey: 'executeSmartContractMethod',
        inputData: JSON.stringify({
          contractAddress: service,
          methodAbi: abi.filter(x => x.name === 'submit')[0],
          privateKey: process.env.PRIVATE_KEY,
          inputs: {
            executionId: executionId,
            outputs: asciiToHex(JSON.stringify(outputs))
          }
        })
      })
      console.log(tx)
      console.log(JSON.parse(tx.outputData).transactionHash)
    } catch (e) {
      throw e
    }
  })
}

const verify = async (service, servicetask, verify) => {
  mesg.listenEvent({
    serviceID,
    eventFilter: 'log'
  }).on('data', async data => {
    const event = JSON.parse(data.eventData)
    if (event.address.toLowerCase() !== service.toLowerCase()) { return }

    const decode = await mesg.executeTaskAndWaitResult({
      serviceID,
      taskKey: 'decodeLog',
      inputData: JSON.stringify({
        ...event,
        abi: abi.filter(x => x.name === 'Submitted')[0]
      })
    })

    if (decode.outputKey === 'error') { throw new Error('error when decode logs') }
    const result = JSON.parse(decode.outputData)
    const { executionId } = result.decodedData

    try {
      const valid = true

      const tx = await mesg.executeTaskAndWaitResult({
        serviceID,
        taskKey: 'executeSmartContractMethod',
        inputData: JSON.stringify({
          contractAddress: service,
          methodAbi: abi.filter(x => x.name === 'verify')[0],
          privateKey: process.env.PRIVATE_KEY,
          inputs: {
            executionId: executionId,
            valid: valid
          }
        })
      })
      console.log(tx)
      console.log(JSON.parse(tx.outputData).transactionHash)
    } catch (e) {
      throw e
    }
  })
}

module.exports = {
  execute,
  verify
}
