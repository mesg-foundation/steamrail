/* eslint-env mocha */
/* global contract, artifacts */

const assert = require('chai').assert
const NodeRegistry = artifacts.require('NodeRegistry')
const NodeProvider = artifacts.require('NodeProvider')
const truffleAssert = require('truffle-assertions')

contract('NodeProvider', async (accounts) => {
  let contract = null
  const owner = accounts[0]
  const other = accounts[1]
  const nodes = accounts.slice(2, 12)
  console.log('nodes', nodes)
  const sid = 0

  before(async () => {
    const nodeRegistry = await NodeRegistry.new({ from: owner })
    for (let i = 0; i < nodes.length; i++) {
      await nodeRegistry.register(sid, { from: nodes[i] })
    }
    contract = await NodeProvider.new(nodeRegistry.address, { from: owner })
  })

  describe('pickNodes', async () => {
    it('should pick unique nodes', async () => {
      const nodes = await contract.pickNodes(sid, 5)
      console.log('nodes', nodes)
      assert.equal(nodes.length, 5)
      assert.equal(nodes.length, nodes.filter((v, i, a) => a.indexOf(v) === i).length)
    })
  })
})
