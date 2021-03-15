import * as hre from 'hardhat'
import '@nomiclabs/hardhat-ethers'

import { writeFileSync } from 'fs'
import { join } from 'path'
import { resolveContracts } from '../scripts/resolver'
import { utils, Contract, ethers } from 'ethers'

const DEPLOYMENTS_PATH = join(__dirname, '../deployments.json')

function fieldsToInline(obj) {
    return Object.entries(obj).map(([ k, v ]) => `${k}=${v}`).join(' ')
}

async function main() {
    const {
        METAMASK_DEV_ACCOUNT
    } = process.env
    if(!METAMASK_DEV_ACCOUNT) throw new Error("METAMASK_DEV_ACCOUNT not defined")
    
    let network = await hre.ethers.provider.getNetwork()
    let networkId = network.chainId
    console.log(`Deploying for network ID ${networkId}`)

    let provider = hre.ethers.provider
    const signer = provider.getSigner()
    const account = await signer.getAddress()

    let deployments = require(DEPLOYMENTS_PATH)
    let contracts: {
        [key: string]: Contract
    } = {}
    const libraries: {
        [key: string]: string
    } = {}

    //
    // Import vendor addresses.
    //

    const vendoredContracts = await resolveContracts(provider)
    const {
        Realitio,
        RealitioProxy,
        ConditionalTokens,
        FPMMDeterministicFactory,
        WETH9,
        UniswapV2Factory,
    } = vendoredContracts

    console.log(`Vendored addresses:`)
    Object.entries(vendoredContracts).map(([name, address]) => {
        console.log(`${name},${address}`)
    })
    console.log()

    // 
    // Test
    // 

    // const TestProxy = await hre.ethers.getContractFactory('TestProxy')
    // const testProxy = await TestProxy.deploy()

    // const TestImpl = await hre.ethers.getContractFactory('TestImpl')
    // const testImpl = await TestImpl.deploy(testProxy.address)
    
    // await testProxy.setTarget(testImpl.address)
    // const testInstance = await hre.ethers.getContractAt("TestImpl", testProxy.address)
    // await testInstance.test()
    
    // const TestWrapper2 = await hre.ethers.getContractFactory("TestWrapper2")
    // const testWrapper2 = await TestWrapper2.deploy()
    // await testWrapper2.test(testProxy.address)


    //
    // Deploy: ModeratorArbitrator.
    //

    const ModeratorArbitrator = await hre.ethers.getContractFactory('ModeratorArbitrator')
    const moderatorArbitrator = await ModeratorArbitrator.deploy()
    contracts['ModeratorArbitrator'] = moderatorArbitrator

    const ModeratorArbitratorV1 = await hre.ethers.getContractFactory('ModeratorArbitratorV1')
    // TODO
    const metadata = {
        tos: 'https://twitter.com/liamzebedee',
        template_hashes: [],
    }
    const moderatorArbitratorV1 = await ModeratorArbitratorV1.deploy(moderatorArbitrator.address)
    const moderatorMultisig = METAMASK_DEV_ACCOUNT
    await moderatorArbitratorV1.initialize(Realitio, JSON.stringify(metadata), moderatorMultisig)

    await moderatorArbitrator.setTarget(moderatorArbitratorV1.address)

    //
    // Deploy: Scripts, Factory.
    //

    const Scripts = await hre.ethers.getContractFactory('Scripts')
    const scripts = await Scripts.deploy()
    contracts['Scripts'] = scripts

    const CuratemCommunity = await hre.ethers.getContractFactory("CuratemCommunity")
    const curatemCommunity = await CuratemCommunity.deploy()
    const Factory = await hre.ethers.getContractFactory('Factory', { libraries })
    const factory = await Factory.deploy()
    await factory.initialize(curatemCommunity.address)
    contracts['Factory'] = factory

    //
    // Deploy: Curatem.
    //
    const Curatem = await hre.ethers.getContractFactory('Curatem')
    const curatem = await Curatem.deploy()
    const CuratemV1 = await hre.ethers.getContractFactory('CuratemV1', {
        libraries,
    })
    const curatemV1 = await CuratemV1.deploy(
        curatem.address,
        Realitio,
        UniswapV2Factory,
        factory.address
    )
    await curatem.setTarget(curatemV1.address)
    contracts['CuratemV1'] = curatemV1
    contracts['Curatem'] = curatem

    //
    // Deploy an example community.
    //

    const communities = [
        {
            id: 'RedditCommunity1',
            moderator: moderatorArbitrator.address,
            token: WETH9,
        },
    ]

    for (let community of communities) {
        const { token, moderator } = community
        console.log(`Deploying community "${community.id}", ${fieldsToInline({ token, moderator })}`)

        const salt = ethers.BigNumber.from(ethers.utils.randomBytes(32))

        const res = await curatemV1.createCommunity(
            community.token,
            community.moderator
        )
        const receipt = await res.wait()
        const event = receipt.events.find((log) => log.event === 'NewCommunity')

        contracts[community.id] = {
            deployTransaction: res,
            address: event.args.community,
        } as Contract // TODO: hack
    }

    //
    // Save deployments.
    //

    if (!deployments[networkId]) {
        deployments[networkId] = {}
    }

    for (let [contract, instance] of Object.entries(contracts)) {
        const { hash, blockHash, blockNumber } = instance.deployTransaction
        deployments[networkId][contract] = {
            address: instance.address,
            hash,
            blockHash,
            blockNumber,
        }
    }

    if (process.env.DRY_DEPLOY) {
        console.log(`DRY_DEPLOY is enabled. Deployments have not been saved.`)
        return
    }

    writeFileSync(DEPLOYMENTS_PATH, JSON.stringify(deployments, null, 4))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
