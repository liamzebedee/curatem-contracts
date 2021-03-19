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

    console.log('Deploy: CuratemHelpersV1')
    const CuratemHelpers = await hre.ethers.getContractFactory("CuratemHelpersV1")
    const curatemHelpers = await CuratemHelpers.deploy()
    await saveDeployment('CuratemHelpersV1', curatemHelpers)

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
