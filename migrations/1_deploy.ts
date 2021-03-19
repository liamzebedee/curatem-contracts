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

let contracts: {
    [key: string]: Contract
} = {}

async function saveDeployment(name: string, contract: ethers.Contract) {
    const receipt = await contract.deployTransaction.wait(1)
    contracts[name] = {
        deployTransaction: receipt,
        address: receipt.contractAddress,
    } as unknown as Contract
}

async function waitTx(call: Promise<ethers.providers.TransactionResponse>) {
    const pending: ethers.providers.TransactionResponse = await call
    const receipt = await pending.wait(1)
    return receipt
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
    console.log(`Account: ${account}`)
    let deployments = require(DEPLOYMENTS_PATH)
    
    const libraries: {
        [key: string]: string
    } = {}

    //
    // Import vendor addresses.
    //

    const vendoredContracts = await resolveContracts(provider)
    const {
        Realitio,
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

    console.log(`Deploy: ModeratorArbitrator`)
    const ModeratorArbitrator = await hre.ethers.getContractFactory('ModeratorArbitrator')
    const moderatorArbitrator = await ModeratorArbitrator.deploy()
    await saveDeployment('ModeratorArbitrator', moderatorArbitrator)

    const ModeratorArbitratorV1 = await hre.ethers.getContractFactory('ModeratorArbitratorV1')
    // TODO
    const metadata = {
        tos: 'https://twitter.com/liamzebedee',
        template_hashes: [],
    }
    const moderatorArbitratorV1 = await ModeratorArbitratorV1.deploy(moderatorArbitrator.address)
    await waitTx(
        moderatorArbitrator.proxy_setTarget(moderatorArbitratorV1.address)
    )

    const moderatorArbitratorBound = await hre.ethers.getContractAt('ModeratorArbitratorV1', moderatorArbitrator.address)
    const moderatorMultisig = METAMASK_DEV_ACCOUNT
    await waitTx(
        moderatorArbitratorBound.initialize(
            Realitio, 
            JSON.stringify(metadata), 
            moderatorMultisig
        )
    )

    //
    // Deploy: Scripts, Factory.
    //
    
    console.log(`Deploy: Scripts, Factory.`)
    const Scripts = await hre.ethers.getContractFactory('Scripts')
    const scripts = await Scripts.deploy()
    await saveDeployment('Scripts', scripts)

    const CuratemCommunity = await hre.ethers.getContractFactory("CuratemCommunity")
    const curatemCommunity = await CuratemCommunity.deploy()
    await curatemCommunity.deployTransaction.wait(1)
    await waitTx(
        curatemCommunity.initialize(
            Realitio,
            ethers.constants.AddressZero,
            ethers.constants.AddressZero,
            ethers.constants.AddressZero,
            ethers.constants.AddressZero,
            moderatorArbitrator.address,
        )
    )
    const Factory = await hre.ethers.getContractFactory('Factory', { libraries })
    const factory = await Factory.deploy()
    await factory.deployTransaction.wait(1)
    await waitTx(
        await factory.initialize(curatemCommunity.address)
    )
    await saveDeployment('Factory', factory)

    // 
    // Deploy: RealitioOracle
    // 
    console.log(`Deploy: RealitioOracle`)
    const RealitioOracle = await hre.ethers.getContractFactory('RealitioOracle')
    const realitioOracle = await RealitioOracle.deploy(Realitio)
    await saveDeployment('RealitioOracle', realitioOracle)
    
    //
    // Deploy: Curatem.
    //
    console.log(`Deploy: Curatem.`)
    const Curatem = await hre.ethers.getContractFactory('Curatem')
    const curatem = await Curatem.deploy()
    await saveDeployment('Curatem', curatem)
    const CuratemV1 = await hre.ethers.getContractFactory('CuratemV1', {
        libraries,
    })
    const curatemV1 = await CuratemV1.deploy(
        curatem.address,
        Realitio,
        realitioOracle.address,
        UniswapV2Factory,
        factory.address
    )
    await saveDeployment('CuratemV1', factory)
    await waitTx(
        curatem.setTarget(curatemV1.address)
    )


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

        const res = await curatemV1.createCommunity(
            community.token,
            community.moderator
        )
        const receipt = await res.wait()
        const event = receipt.events.find((log) => log.event === 'NewCommunity')

        contracts[community.id] = {
            deployTransaction: receipt,
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
