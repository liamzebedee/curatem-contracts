const { expect } = require("chai");
import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import * as hre from 'hardhat'

describe("Curatem", function() {
  describe("createMarket", function() {
    it('emits the event', async () => {
      const Curatem = await hre.ethers.getContractFactory("Curatem");
      const curatem = await Curatem.deploy();
      
      await curatem.deployed();

      const multihash = '0x' + '11'.repeat(32) + '22'.repeat(2)
      console.log(multihash)
      await expect(curatem.createMarket(multihash))
        .to.emit(curatem, 'MarketCreated')
        .withArgs('0x1111111111111111111111111111111111111111111111111111111111111111', '0x2222000000000000000000000000000000000000000000000000000000000000')
    })
  })
})
