const hre = require("hardhat")

const {
    REALITYIO_ADDRESS
} = process.env

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile 
    // manually to make sure everything is compiled
    // await hre.run('compile');
  
    // Deploy contracts.
    const ModeratorArbitrator = await hre.ethers.getContractFactory("ModeratorArbitrator");
    // TODO
    const metadata = {
        tos: "https://twitter.com/liamzebedee",
        template_hashes: []
    }
    const moderatorArbitrator = await ModeratorArbitrator.deploy(REALITYIO_ADDRESS, JSON.stringify(metadata));
    const MODERATOR_MULTISIG_ADDRESS = moderatorArbitrator.address
    console.log(MODERATOR_MULTISIG_ADDRESS)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
