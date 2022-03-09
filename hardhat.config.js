require('@nomiclabs/hardhat-waffle')
// require('solidity-coverage')
// require('@atixlabs/hardhat-time-n-mine')

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  paths: {
    sources: './src'
  },
  solidity: {
    version: '0.8.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 99999,
      },
    },
  },
  networks: {
    optimism: {
      url: 'https://kovan.optimism.io',
      accounts: [
        // 0xeb465b6C56758a1CCff6Fa56aAee190646A597A0
        '0x18ef552014cb0717769838c7536bc1d3b1c800fe351aa2c38ac093fa4d4eb7d6',
      ],
    },
  },
  mocha: {
    timeout: 300000,
  },
}
