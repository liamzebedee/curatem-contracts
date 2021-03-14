const { expect } = require("chai");
import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import * as hre from 'hardhat'
import { waffle } from 'hardhat'

import { ethers } from "ethers";
const { utils, BigNumber } = ethers
import { resolveContracts } from '../scripts/resolver'

import { SpamPredictionMarket, OutcomeToken, Factory } from "../typechain";

import { deployWaffleMock, deployWaffle, toWei, fromWei } from './utils'
import { createSnapshot, restoreSnapshot } from "./utils/snapshot";


async function deployNewERC20(name: string, symbol: string, owner: string): Promise<OutcomeToken> {
	const OutcomeToken = await hre.ethers.getContractFactory("OutcomeToken")
	const outcomeToken = await OutcomeToken.deploy() as unknown as OutcomeToken
	await outcomeToken.initialize(name, symbol, owner)
	return outcomeToken
}

describe("SpamPredictionMarket", function () {
	let provider: ethers.providers.JsonRpcProvider
	let signer: ethers.providers.JsonRpcSigner
	let account: string

	// let weth: WETH9
	// let realitioOracleResolverMixin: TestRealitioOracleResolverMixin
	let market: SpamPredictionMarket
	let tokens
	let realitio
	let collateral: OutcomeToken

	const QUESTION_ID = ethers.constants.HashZero

	const abiCoder = ethers.utils.defaultAbiCoder

	before(async () => {
		provider = waffle.provider
		signer = provider.getSigner()
		account = await signer.getAddress()

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
		collateral = await deployNewERC20("Collateral", "REP", account)
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


		const outcomeTokens = await market.getOutcomeTokens()
		tokens = [collateral]	
		for(let t of outcomeTokens) {
			const token = await hre.ethers.getContractAt("OutcomeToken", t)
			tokens.push(token)
		}
		
		// Deploy a SpamPredictionMarket
		// Mock:
		// - Uniswap pool
		// - Collateral token
		// - Factory
		// Null:
		// - Question ID
	})

	describe("reportPayouts", function () {
		before(() => createSnapshot(provider))
		after(() => restoreSnapshot(provider))
		beforeEach(() => createSnapshot(provider))
		afterEach(() => restoreSnapshot(provider))

		it('reverts for null payouts array', async () => {
			const payouts = ['0', '0']
			await expect(market.reportPayouts(payouts)).to.be.revertedWith(
				"at least one payout must be made"
			)
		})

		it('can only be reported once', async () => {
			const payouts = ['0', '1']
			await market.reportPayouts(payouts)
			await expect(market.reportPayouts(payouts)).to.be.revertedWith(
				"Market is not in OPEN state."
			)
		})

		it('suceeds for 1 outcome', async () => {
			const payouts = ['0', '1']
			await market.reportPayouts(payouts)
		})

		it('suceeds for >1 outcomes', async () => {
			const payouts = ['1', '1']
			await market.reportPayouts(payouts)
		})
	})

	describe("redeem", () => {
		let amount = toWei('20')

		before(() => createSnapshot(provider))
		after(() => restoreSnapshot(provider))

		before(async () => {
			await collateral.mint(account, amount)
			await collateral.approve(market.address, amount)
			await market.buy(amount)
			
			for(let token of tokens.slice(1)) {
				await token.approve(market.address, amount)
			}
		})

		beforeEach(() => createSnapshot(provider))
		afterEach(() => restoreSnapshot(provider))

		it('redeems for payouts of 1 outcome', async () => {
			const payouts = ['0', '1']
			await market.reportPayouts(payouts)
			await market.redeem(amount)

			const balances = await Promise.all(tokens.map(token => token.balanceOf(account)))
			expect(balances.map(x => x.toString())).to.deep.equal(
				[amount.toString(), amount.toString(), '0']
			)
		})

		it('redeems for payouts of >1 outcomes', async () => {
			const payouts = ['1', '1']
			await market.reportPayouts(payouts)
			await market.redeem(amount)

			const balances = await Promise.all(tokens.map(token => token.balanceOf(account)))
			expect(balances.map(x => x.toString())).to.deep.equal(
				[amount.toString(), '0', '0']
			)
		})
	})

	describe("sell", async () => {
		let amount = toWei('20')

		before(() => createSnapshot(provider))
		after(() => restoreSnapshot(provider))

		before(async () => {
			await collateral.mint(account, amount)
			await collateral.approve(market.address, amount)
			await market.buy(amount)
			
			for(let token of tokens.slice(1)) {
				await token.approve(market.address, amount)
			}
		})

		beforeEach(() => createSnapshot(provider))
		afterEach(() => restoreSnapshot(provider))

		it('works', async () => {
			let balances = await Promise.all(tokens.map(token => token.balanceOf(account)))
			expect(balances.map(x => x.toString())).to.deep.equal(
				['0', amount.toString(), amount.toString()]
			)

			await market.sell(amount)

			balances = await Promise.all(tokens.map(token => token.balanceOf(account)))
			expect(balances.map(x => x.toString())).to.deep.equal(
				[amount.toString(), '0', '0']
			)
		})
	})

	describe("buy", async () => {
		let amount = toWei('20')

		before(() => createSnapshot(provider))
		after(() => restoreSnapshot(provider))
		
		before(async () => {
			await collateral.mint(account, amount)
			await collateral.approve(market.address, amount)
			
			for(let token of tokens.slice(1)) {
				await token.approve(market.address, amount)
			}
		})

		beforeEach(() => createSnapshot(provider))
		afterEach(() => restoreSnapshot(provider))

		it('works', async () => {
			let balances = await Promise.all(tokens.map(token => token.balanceOf(account)))
			expect(balances.map(x => x.toString())).to.deep.equal(
				[amount.toString(), '0', '0']
			)

			await market.buy(amount)

			balances = await Promise.all(tokens.map(token => token.balanceOf(account)))
			expect(balances.map(x => x.toString())).to.deep.equal(
				['0', amount.toString(), amount.toString()]
			)
		})
	})
})

// const outcomeToken1 = await deployNewERC20("Collateral", "REP", account)
// const outcomeToken2 = await deployNewERC20("Collateral", "REP", account)
		