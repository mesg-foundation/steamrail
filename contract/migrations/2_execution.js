/* global artifacts */

const Executions = artifacts.require('Executions')

module.exports = async (deployer, network) => {
  await deployer.deploy(Executions)
}
