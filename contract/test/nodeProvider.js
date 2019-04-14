/* eslint-env mocha */
/* global contract, artifacts */

const assert = require('chai').assert
const NodeRegistry = artifacts.require('NodeRegistry')
const NodeProvider = artifacts.require('NodeProvider')
const truffleAssert = require('truffle-assertions')

contract('NodeProvider', async (accounts) => {
  let nodeProvider = null
  const owner = accounts[0]
  const other = accounts[1]
  const nodes = accounts.slice(2, 12)
  console.log('nodes', nodes)
  const sid = '0xfd667a171da5c0d38ef89c6b45950fe3d89d57ee8ef89c6b45950fe3d89d57ee'

  before(async () => {
    const nodeRegistry = await NodeRegistry.new({ from: owner })
    for (let i = 0; i < nodes.length; i++) {
      await nodeRegistry.register(sid, { from: nodes[i] })
    }
    nodeProvider = await NodeProvider.new(nodeRegistry.address, { from: owner })
  })

  describe('pickNodes', async () => {
    it('should pick unique nodes', async () => {
      const nodes = await nodeProvider.pickNodes(sid, 5)
      console.log('nodes', nodes)
      assert.equal(nodes.length, 5)
      assert.equal(nodes.length, nodes.filter((v, i, a) => a.indexOf(v) === i).length)
    })
  })

  describe('verifyNodes', async () => {
    it('should return true', async () => {
      assert.isTrue(await nodeProvider.verifyNodes(sid, nodes))
    })
    it('should return false', async () => {
      assert.isFalse(await nodeProvider.verifyNodes(sid, [other]))
    })
  })
})
