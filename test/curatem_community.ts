const { expect } = require("chai");
import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import * as hre from 'hardhat'
import { ethers } from "ethers";
const { utils, BigNumber } = ethers


import { resolveContracts } from '../scripts/resolver'

const IFixedProductMarketMakerJSON = require('../abis/IFixedProductMarketMaker.json')

function toWei(amount: string) {
  return utils.parseUnits(amount, 'ether')
}

describe("CuratemCommunity", function() {
  let provider: ethers.providers.JsonRpcProvider, signer: ethers.providers.JsonRpcSigner
  let user1
  let resolvedContracts

  let weth

  before(async() => {
    provider = new ethers.providers.JsonRpcProvider()
    signer = provider.getSigner()
    resolvedContracts = await resolveContracts(provider)

    user1 = await signer.getAddress()

    weth = await hre.ethers.getContractAt('WETH9', resolvedContracts['WETH9'])
    await weth.deposit({ 
      value: utils.parseUnits('5', 'ether'), 
      from: user1 
    })

    // TODO: I don't know why this doesn't work.
    // Error is HardhatError: HH700: Artifact for contract "IFixedPriceMarketMaker" not found.
    // const FPMM = await hre.ethers.getContractAt("IFixedPriceMarketMaker", '0x')
  })

  describe("createMarket", function() {
    
    before(async () => {

    })

    it('emits the event', async () => {
      const CuratemCommunity = await hre.ethers.getContractFactory("CuratemCommunity");
      const moderator = signer._address
      const curatemCommunity = await CuratemCommunity.deploy(
        resolvedContracts['Realitio'],
        resolvedContracts['RealitioProxy'],
        resolvedContracts['ConditionalTokens'],
        resolvedContracts['FPMMDeterministicFactory'],
        resolvedContracts['WETH9'],
        resolvedContracts['RealitioProxy'],
        moderator
      );
      
      await curatemCommunity.deployed();


      const createMarketTx = await curatemCommunity.createMarket("http://example.com")
      const receipt = await createMarketTx.wait()
      const event = receipt.events.find(log => log.event === 'MarketCreated');

      await expect(createMarketTx)
        .to.emit(curatemCommunity, 'MarketCreated')
      

      // Now let's trade with the AMM.
      // const FPMM = await hre.ethers.getContractFactory("interfaces/IFixedPriceMarketMaker.sol")
      // const fpmm = FPMM.attach(event.args.fixedProductMarketMaker)
      const fpmm = new ethers.Contract(event.args.fixedProductMarketMaker, IFixedProductMarketMakerJSON, provider).connect(signer)
      await weth.approve(fpmm.address, ethers.constants.MaxUint256, { from: user1 })
      const distributionHint = [50,50]
      const addFundingTx = await fpmm.addFunding(toWei('1'), distributionHint, { from: user1 });
      console.log(
        (await createMarketTx.wait()).events
      )
      // convert those shares into erc20's? 
      // chuck em in a balancer pool? 


      const buyAmount1 = await fpmm.calcBuyAmount(toWei('1'), 0);
      const buyAmount2 = await fpmm.calcBuyAmount(toWei('1'), 1);
      // await fpmm.buy(investmentAmount, 0, buyAmount, { from: trader });
      console.log(utils.formatEther(buyAmount1), utils.formatEther(buyAmount2))
    })
  })
})
