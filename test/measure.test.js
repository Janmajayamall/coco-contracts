const { ethers } = require('hardhat')
const { compress } = require('zerocompress')

async function deploy() {
  const Decompress = await ethers.getContractFactory('Decompress')
  const decompress = await Decompress.deploy()
  await decompress.deployed()

  const MarketRouter = await ethers.getContractFactory('MarketRouter')
  const marketRouter = await MarketRouter.deploy(decompress.address)
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

    const calldata = marketRouter.interface.encodeFunctionData('createFundBetOnMarket', [
      eventId2,
      oracle.address,
      1000,
      1000,
      1
    ])

    const [func, data] = compress(calldata)
    await marketRouter.connect(user1)[func](data).then(t => t.wait())

    await marketRouter.connect(user1).createFundBetOnMarket(
      eventId1,
      oracle.address,
      1000,
      1000,
      1
    ).then(t => t.wait())

  })
})
