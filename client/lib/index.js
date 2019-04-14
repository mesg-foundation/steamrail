const { stringToHex, hexToString } = require('web3-utils')
const { Wallet } = require('ethers/wallet')

const mesg = require('mesg-js').application({
  endpoint: process.env.MESG_CLIENT_ADDRESS
})

const EVM_CONTRACT = 'evm-contract'
const EXEC_CREATED = 'Created'
const EXEC_EXECUTED = 'Executed'
const EXEC_SUBMIT_OUTPUTS = 'submitOutputs'
const EXEC_SUBMIT_VERIFICATION = 'submitVerification'

module.exports = (privateKey) => {
  const pubKey = new Wallet(privateKey).address
  console.log(`Starting Streamrail with address: ${pubKey}`)

  const listenEvent = (serviceId, serviceTask, eventName, callback) => mesg
    .listenEvent({ serviceID: EVM_CONTRACT, eventFilter: 'event' })
    .on('error', e => { throw e })
    .on('end', () => process.exit(0))
    .on('data', async ({ eventData }) => {
      const { name, data } = JSON.parse(eventData)
      if (name !== eventName) { return }
      if (data.serviceId !== serviceId) { return }
      if (hexToString(data.task) !== serviceTask) { return }
      console.log(`Receive event ${name}`)
      try {
        const id = await callback(data)
        if (!id) {
          console.log(`Event ${name} processed with ${id}`)
        }
      } catch (e) {
        console.error(e)
      }
    })

  const executeMethod = async (method, inputs) => {
    const tx = await mesg.executeTaskAndWaitResult({
      serviceID: EVM_CONTRACT,
      taskKey: 'execute',
      inputData: JSON.stringify({
        method,
        privateKey,
        inputs
      })
    })
    return JSON.parse(tx.outputData).transactionHash
  }

  const execute = async (serviceId, serviceTask, callback) => listenEvent(
    serviceId,
    serviceTask,
    EXEC_CREATED,
    async ({ executionId, inputs, submitter }) => {
      if (submitter.toLowerCase() !== pubKey.toLowerCase()) { return null } // The client is not the selected executor
      const inputData = JSON.parse(hexToString(inputs))
      const outputs = await callback(inputData)
      return executeMethod(EXEC_SUBMIT_OUTPUTS, [ executionId, stringToHex(JSON.stringify(outputs)) ])
    })

  const verify = async (serviceId, serviceTask, verificationCallback) => listenEvent(
    serviceId,
    serviceTask,
    EXEC_EXECUTED,
    async ({ executionId, inputs, outputs, verifiers }) => {
      if (verifiers.map(x => x.toLowerCase()).indexOf(pubKey.toLowerCase()) < 0) { return null } // The client is not part of the selected validators
      const inputData = JSON.parse(hexToString(inputs))
      const outputData = JSON.parse(hexToString(outputs))
      const verification = await verificationCallback(inputData, outputData)
      return executeMethod(EXEC_SUBMIT_VERIFICATION, [ executionId, verification ])
    })

  return {
    execute,
    verify,
    executeMethod
  }
}
