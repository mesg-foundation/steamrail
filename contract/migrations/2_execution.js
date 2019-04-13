/* global artifacts */

const NodeProvider = artifacts.require('NodeProvider')
const NodeRegistry = artifacts.require('NodeRegistry')
const Executions = artifacts.require('Executions')

module.exports = async (deployer, network) => {
  await deployer.deploy(NodeRegistry)
  await deployer.deploy(NodeProvider, NodeRegistry.address)
  await deployer.deploy(Executions, NodeProvider.address)
}
