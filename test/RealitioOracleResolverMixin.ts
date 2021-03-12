const { expect } = require("chai");
import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import * as hre from 'hardhat'
import { waffle } from 'hardhat'

import { ethers } from "ethers";
const { utils, BigNumber } = ethers
import { resolveContracts } from '../scripts/resolver'

import { SpamPredictionMarket, WETH9 } from "../typechain";
import { TestRealitioOracleResolverMixin } from "../typechain/TestRealitioOracleResolverMixin";
import { deployWaffleMock, deployWaffle } from './utils'


describe("RealitioOracleResolverMixin", function() {
  let provider: ethers.providers.JsonRpcProvider
  let signer: ethers.providers.JsonRpcSigner

  let weth: WETH9
  let realitioOracleResolverMixin: TestRealitioOracleResolverMixin
  let market: SpamPredictionMarket
  let realitio

  const QUESTION_ID = ethers.constants.HashZero

  const abiCoder = ethers.utils.defaultAbiCoder

  before(async() => {
    provider = waffle.provider
    signer = provider.getSigner()
    
    realitio = await deployWaffleMock<unknown>(signer, 'contracts/interfaces/IRealitio.sol')

    realitioOracleResolverMixin = await deployWaffle<TestRealitioOracleResolverMixin>(
      signer,
      'contracts/test/TestRealitioOracleResolverMixin.sol', 
      []
    )
    await realitioOracleResolverMixin["initialize(bytes32,address)"](
      QUESTION_ID,
      realitio.address
    )
  })

  describe("resolve", function() {
    it('all outcomes are redeemable when reported answer is invalid', async () => {
      const questionResult = ethers.utils.zeroPad(ethers.BigNumber.from(42).toHexString(), 32)

      await realitio.mock.resultFor
        .withArgs(QUESTION_ID)
        .returns(questionResult)

      await realitioOracleResolverMixin.resolve()

      const payouts = [
        await realitioOracleResolverMixin.payouts(0),
        await realitioOracleResolverMixin.payouts(1)
      ].map(num => num.toString())
      
      const expectedPayouts = ['1','1']

      expect(payouts).to.deep.equal(expectedPayouts)
    })

    it('sets correct payout for valid answer', async () => {
      const questionResult = ethers.utils.zeroPad(ethers.BigNumber.from(0).toHexString(), 32)

      await realitio.mock.resultFor
        .withArgs(QUESTION_ID)
        .returns(questionResult)

      await realitioOracleResolverMixin.resolve()

      // Waffle's calledOnContractWith is currently disabled in Hardhdat.
      // https://github.com/nomiclabs/hardhat/issues/1135
      // 
      // expect('reportPayouts').to.be.calledOnContractWith(
      //   realitioOracleResolverMixin, 
      //   ['1','0']
      // )
      // 
      // Instead we expose the return value as the `payouts` variable.
      // 
      
      const payouts = [
        await realitioOracleResolverMixin.payouts(0),
        await realitioOracleResolverMixin.payouts(1)
      ].map(num => num.toString())
      
      const expectedPayouts = ['1','0']

      expect(payouts).to.deep.equal(expectedPayouts)
    })
  })
})
