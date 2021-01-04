//const synLPToken = artifacts.require('synLPToken.sol')
const swapico = artifacts.require('Swapico.sol')

module.exports = async function(deployer) {

//  await deployer.deploy(synLPToken)
//  const synLPToken = await synLPToken.deployed()

  await deployer.deploy(swapico)
  const swapico = await swapico.deployed()
}