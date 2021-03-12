const { expect } = require("chai");
import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import * as hre from 'hardhat'
import { waffle } from 'hardhat'

import { ethers } from "ethers";
const { utils, BigNumber } = ethers
import { resolveContracts } from '../scripts/resolver'

import { SpamPredictionMarket, OutcomeToken, Factory } from "../typechain";

import { deployWaffleMock, deployWaffle } from './utils'


async function deployNewERC20(name: string, symbol: string, owner: string) {
	const OutcomeToken = await hre.ethers.getContractFactory("OutcomeToken")
	const outcomeToken = await OutcomeToken.deploy() as unknown as OutcomeToken
	await outcomeToken.initialize(name, symbol, owner)
	return outcomeToken
}

describe("SpamPredictionMarket", function () {
	let provider: ethers.providers.JsonRpcProvider
	let signer: ethers.providers.JsonRpcSigner

	// let weth: WETH9
	// let realitioOracleResolverMixin: TestRealitioOracleResolverMixin
	let market: SpamPredictionMarket
	let realitio

	const QUESTION_ID = ethers.constants.HashZero

	const abiCoder = ethers.utils.defaultAbiCoder

	before(async () => {
		provider = waffle.provider
		signer = provider.getSigner()
		const account = await signer.getAddress()

		// Oracle
		const oracle = account

		// Uniswap Factory
		const uniswapFactory = await deployWaffleMock(signer, '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol')
		uniswapFactory.mock.createPair.returns(ethers.constants.AddressZero)

		// Factory
		const Factory = await hre.ethers.getContractFactory("Factory")
		const factory = await Factory.deploy() as unknown as Factory
		await factory.initialize()

		// Etc
		const collateral = await deployNewERC20("Collateral", "REP", account)
		const questionId = ethers.constants.HashZero
		
		// SpamPredictionMarket
		const SpamPredictionMarket = await hre.ethers.getContractFactory("SpamPredictionMarket")
		market = await SpamPredictionMarket.deploy() as unknown as SpamPredictionMarket
		await market["initialize(address,address,address,address,bytes32)"](
			oracle,
			collateral.address,
			uniswapFactory.address,
			factory.address,
			questionId
		)

		// Deploy a SpamPredictionMarket
		// Mock:
		// - Uniswap pool
		// - Collateral token
		// - Factory
		// Null:
		// - Question ID
	})

	describe("reportPayouts", function () {
		it('null payouts array reverts', async () => {
			const payouts = ['0', '0']
			expect(market.reportPayouts(payouts)).to.be.revertedWith(
				"payouts must resolve to one and only one final outcome"
			)
		})

		it('works', async () => {
			const payouts = ['0', '1']
			await market.reportPayouts(payouts)
		})
	})

	describe('redeem', () => {
		it()
	})

})

// const outcomeToken1 = await deployNewERC20("Collateral", "REP", account)
// const outcomeToken2 = await deployNewERC20("Collateral", "REP", account)
		