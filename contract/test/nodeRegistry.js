/* eslint-env mocha */
/* global contract, artifacts */

const assert = require('chai').assert
const NodeRegistry = artifacts.require('NodeRegistry')
const truffleAssert = require('truffle-assertions')

contract('NodeRegistry', async (accounts) => {
  let nodeRegistry = null
  const owner = accounts[0]
  const other = accounts[1]
  const node1 = accounts[2]
  const node2 = accounts[3]
  const sid = '0xfd667a171da5c0d38ef89c6b45950fe3d89d57ee8ef89c6b45950fe3d89d57ee'

  before(async () => {
    nodeRegistry = await NodeRegistry.new({ from: owner })
  })

  describe('register', async () => {
    it('register one node with no stake', async () => {
      await nodeRegistry.register(sid, { from: node1 })
      assert.isTrue(await nodeRegistry.isRegistered(sid, node1))
    })
    it('register another node with a stake', async () => {
      await nodeRegistry.register(sid, { from: node2, value: 100 })
      assert.isTrue(await nodeRegistry.isRegistered(sid, node2))
      assert.equal((await nodeRegistry.stake(sid, node2)).toNumber(), 100)
    })
  })

  describe('cancel', async () => {
    it('cancel one node', async () => {
      await nodeRegistry.cancel(sid, { from: node1 })
      assert.isFalse(await nodeRegistry.isRegistered(sid, node1))
    })
    it('should one node with stake', async () => {
      await nodeRegistry.cancel(sid, { from: node2 })
      assert.isFalse(await nodeRegistry.isRegistered(sid, node2))
      // TODO: check that stake is send back.
    })
  })
})
