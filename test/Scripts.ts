const { expect } = require("chai");
import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import * as hre from 'hardhat'
import { resolveContracts } from "../scripts/resolver";
import { ethers } from "ethers";

import { ChainId, Token, TokenAmount, Pair, Fetcher } from '@uniswap/sdk'

const { waffle } = hre
const provider = waffle.provider;

function toWei(amount: string) {
  return ethers.utils.parseUnits(amount, 'ether')
}



// TODO: update this test.
// It's not that far from the original, just need to update to work
// with the odds distribution of buyOutcomeElseProvideLiquidity.
describe.skip("Scripts", function() {
  this.timeout(50000)

  let scripts
  let market
  let collateralToken
  let UniswapV2Router02

  describe("buyOutcomeElseProvideLiquidity", function() {
    
    before(async () => {
      const SpamPredictionMarket = await hre.ethers.getContractFactory("SpamPredictionMarket");
      const Scripts = await hre.ethers.getContractFactory("Scripts")

      // ----------------------------------
      // Deployments.
      // ----------------------------------

      // Fetch vendored (Kovan) contracts.
      const vendoredContracts = await resolveContracts(provider)
      const {
        WETH9,
        UniswapV2Factory
      } = vendoredContracts
      UniswapV2Router02 = vendoredContracts.UniswapV2Router02
      const weth = await hre.ethers.getContractAt('WETH9', WETH9)
      
      // Deploy Factory.
      const Factory = await hre.ethers.getContractFactory(
        "Factory"
      );
      const factory = await Factory.deploy()
      await factory.initialize()

      // Deploy SpamPredictionMarket.
      const oracle = '0x0000000000000000000000000000000000000000'
      collateralToken = weth.address
      
      market = await SpamPredictionMarket.deploy()
      await market.initialize(
        oracle,
        collateralToken,
        UniswapV2Factory,
        factory.address
      )
      
      // Deploy Scripts.
      scripts = await Scripts.deploy()

      // ----------------------------------
      // Setup.
      // ----------------------------------
      
      // Mint WETH.
      await weth.approve(scripts.address, ethers.constants.MaxUint256)
      await weth.deposit({ 
        value: toWei('2')
      })
    })

    it('provides liquidity if pool has no reserves', async () => {
      await scripts.buyOutcomeElseProvideLiquidity(
        market.address,
        '0',
        toWei('1'),
        '9',
        '10',
        UniswapV2Router02,
        '10000',
        '10000'
      )

      // There should be a REP-SPAM pool with reserves:
      // (0.1 REP, 0.9 SPAM)
      let [notSpamToken, spamToken] = await market.getOutcomeTokens()
      const spam = new Token(ChainId.KOVAN, spamToken, 18)
      const rep = new Token(ChainId.KOVAN, collateralToken, 18)

      const pair = await Fetcher.fetchPairData(spam, rep, provider)
      expect(pair.reserveOf(spam).toFixed(5)).to.eq('0.90000')
      expect(pair.reserveOf(rep).toFixed(5)).to.eq('0.10000')
    })

    it('provides liquidity if price is cheaper than buying from pool', async () => {
      await scripts.buyOutcomeElseProvideLiquidity(
        market.address,
        '0',
        toWei('1'),
        '9',
        '10',
        UniswapV2Router02,
        '10000',
        '10000'
      )

      let [notSpamToken, spamToken] = await market.getOutcomeTokens()
      const spam = new Token(ChainId.KOVAN, spamToken, 18)
      const rep = new Token(ChainId.KOVAN, collateralToken, 18)

      const pair = await Fetcher.fetchPairData(spam, rep, provider)
      expect(pair.reserveOf(spam).toFixed(5)).to.eq('1.80000')
      expect(pair.reserveOf(rep).toFixed(5)).to.eq('0.20000')
    })

    it('buys from pool if it is cheaper', async () => {
      const buyAmount = toWei('0.5')
      const outcome = '1' // spam

      let [notSpamToken, spamToken] = await market.getOutcomeTokens()
      const spam = new Token(ChainId.KOVAN, spamToken, 18)
      const rep = new Token(ChainId.KOVAN, collateralToken, 18)
      let pair = await Fetcher.fetchPairData(spam, rep, provider)
      const [amount, ] = pair.getInputAmount(new TokenAmount(spam, buyAmount.toString()))
      expect(amount.toFixed(18)).to.eq('0.077154540544711057')

      // price of 0.5 SPAM is 0.07 REP.
      // The PM sells at 1:1 exchange rate of REP:SPAM,
      // 0.07 < 0.5, and we should go through the AMM for this trade.

      await scripts.buyOutcomeElseProvideLiquidity(
        market.address,
        outcome,
        buyAmount,
        '9',  
        '10',
        UniswapV2Router02,
        '10000',
        '10000'
      )

      pair = await Fetcher.fetchPairData(spam, rep, provider)
      expect(pair.reserveOf(spam).toFixed(5)).to.eq('1.29999')
      expect(pair.reserveOf(rep).toFixed(5)).to.eq('0.27715')
    })

    it('checks if buy amount is larger than reserves', async () => {
      const buyAmount = toWei('1')
      const OUTCOME_NOTSPAM = '0'
      const OUTCOME_SPAM = '1'

      let [notSpamToken, spamToken] = await market.getOutcomeTokens()
      const spam = new Token(ChainId.KOVAN, spamToken, 18)
      const notSpam = new Token(ChainId.KOVAN, notSpamToken, 18)
      const rep = new Token(ChainId.KOVAN, collateralToken, 18)
      
      // First buy some NOTSPAM.
      // This creates the SPAM-REP pool.
      await scripts.buyOutcomeElseProvideLiquidity(
        market.address,
        OUTCOME_NOTSPAM,
        buyAmount,
        '9',  
        '10',
        UniswapV2Router02,
        '10000',
        '10000'
      )

      // Log reserves of each pool.
      let pairSpam = await Fetcher.fetchPairData(spam, rep, provider)
      let pairNotSpam = await Fetcher.fetchPairData(notSpam, rep, provider)
      console.log(
        [pairSpam.reserve0, pairSpam.reserve1].map(x => x.toFixed(5))
      )
      console.log(
        [pairNotSpam.reserve0, pairNotSpam.reserve1].map(x => x.toFixed(5))
      )

      // Now buy some SPAM.
      // This will try to go through the newly-created SPAM pool,
      // but buyAmount will be larger than the reserves of 0.1 SPAM.
      await scripts.buyOutcomeElseProvideLiquidity(
        market.address,
        OUTCOME_SPAM,
        buyAmount,
        '9',  
        '10',
        UniswapV2Router02,
        '10000',
        '10000'
      )
    })
  })
})
