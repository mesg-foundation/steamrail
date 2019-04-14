/* eslint-env mocha */
/* global contract, artifacts */

const assert = require('chai').assert
const NodeRegistry = artifacts.require('NodeRegistry')
const NodeProvider = artifacts.require('NodeProvider')
const Executions = artifacts.require('Executions')
const truffleAssert = require('truffle-assertions')
const { stringToHex, soliditySha3, toBN, hexToString } = require('web3-utils')

contract('Executions', async (accounts) => {
  let executionSC = null
  const owner = accounts[0]
  const other = accounts[1]
  const nodes = accounts.slice(2, 12)

  const sid = '0xfd667a171da5c0d38ef89c6b45950fe3d89d57ee8ef89c6b45950fe3d89d57ee'
  const task = 'nameOfTask'
  const inputs = JSON.stringify({ a: 2, b: 4 })
  const outputs = JSON.stringify(6)

  before(async () => {
    const nodeRegistry = await NodeRegistry.new({ from: owner })
    for (let i = 0; i < nodes.length; i++) {
      await nodeRegistry.register(sid, { from: nodes[i] })
    }
    const nodeProvider = await NodeProvider.new(nodeRegistry.address, { from: owner })
    executionSC = await Executions.new(nodeProvider.address, { from: owner })
  })

  describe('execution with three verifiers', async () => {
    let executionId, submitter, verifiers
    it('should create an execution', async () => {
      const tx = await executionSC.create(sid, stringToHex(task), stringToHex(inputs), 3, { from: other })
      truffleAssert.eventEmitted(tx, 'Created')
      const event = tx.logs[0].args
      assert.equal(event.serviceId, sid)
      executionId = event.executionId
      submitter = event.submitter
    })
    it('should submit output', async () => {
      const tx = await executionSC.submitOutputs(executionId, stringToHex(outputs), { from: submitter })
      truffleAssert.eventEmitted(tx, 'Executed')
      const event = tx.logs[0].args
      verifiers = event.verifiers
    })
    it('should submit verification from verifier 1', async () => {
      const tx = await executionSC.submitVerification(executionId, true, { from: verifiers[0] })
      truffleAssert.eventEmitted(tx, 'Verified')
    })
    it('should submit verification from verifier 2', async () => {
      const tx = await executionSC.submitVerification(executionId, true, { from: verifiers[1] })
      truffleAssert.eventEmitted(tx, 'Verified')
    })
    it('should submit verification from verifier 3', async () => {
      const tx = await executionSC.submitVerification(executionId, true, { from: verifiers[2] })
      truffleAssert.eventEmitted(tx, 'Verified')
      truffleAssert.eventEmitted(tx, 'Validated')
    })
  })

  describe('execution with validation failed', async () => {
    let executionId, submitter, verifiers
    it('should create an execution', async () => {
      const tx = await executionSC.create(sid, stringToHex(task), stringToHex(inputs), 1, { from: other })
      truffleAssert.eventEmitted(tx, 'Created')
      const event = tx.logs[0].args
      assert.equal(event.serviceId, sid)
      executionId = event.executionId
      submitter = event.submitter
    })
    it('should submit output', async () => {
      const tx = await executionSC.submitOutputs(executionId, stringToHex(outputs), { from: submitter })
      truffleAssert.eventEmitted(tx, 'Executed')
      const event = tx.logs[0].args
      verifiers = event.verifiers
    })
    it('should submit verification', async () => {
      const tx = await executionSC.submitVerification(executionId, false, { from: verifiers[0] })
      truffleAssert.eventEmitted(tx, 'Verified')
      truffleAssert.eventEmitted(tx, 'ValidationFailed')
    })
  })
})
