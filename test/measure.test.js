const { ethers } = require('hardhat')
const { compressSingle } = require('zerocompress')

async function deploy() {
  const MarketRouter = await ethers.getContractFactory('MarketRouter')
  const marketRouter = await MarketRouter.deploy()
  await marketRouter.deployed()

  const Oracle = await ethers.getContractFactory('Oracle')
  const oracle = await Oracle.deploy()
  await oracle.deployed()

  const TestToken = await ethers.getContractFactory('TestToken')
  const testToken = await TestToken.deploy()
  await testToken.deployed()

  return { marketRouter, oracle, testToken }
}

describe('Deploy', () => {
  it('should run operations', async () => {
    const [ user1 ] = await ethers.getSigners()
    const { marketRouter, oracle, testToken } = await deploy()
    await oracle.updateCollateralToken(testToken.address).then(t => t.wait())
    await testToken.connect(user1).mint(user1.address, 100000).then(t => t.wait())
    await testToken.connect(user1).mint(oracle.address, 100000).then(t => t.wait())
    await testToken.connect(user1).approve(marketRouter.address, 100000000).then(t => t.wait())

    await oracle.updateMarketConfig(
      true,
      1,
      100,
      1,
      1,
      1,
      1
    ).then(t => t.wait())

    const eventId1 = `0x0${Array(63).fill().map(() => '0').join('')}`
    const eventId2 = `0x1${Array(63).fill().map(() => '0').join('')}`

    const data = compressSingle(0, 0, [
      eventId2,
      oracle.address,
      1000,
      1000,
      1
    ], ['bytes32', 'address', 'uint', 'uint', 'uint'])
    console.log(data)
    await marketRouter.connect(user1)[`decompress${data[0].length}`](
      ...data
    ).then(t => t.wait())

    await marketRouter.connect(user1).createFundBetOnMarket(
      eventId1,
      oracle.address,
      1000,
      1000,
      1
    ).then(t => t.wait())

  })
})
