// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat"
import contracts from "../constants/contracts"

async function main() {
  const [deployer] = await ethers.getSigners();
  const { NFTManager } = contracts
  console.log("NFTManager:", NFTManager);

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const NFTManagerContract = await ethers.getContractFactory("NFTManager");
  await upgrades.upgradeProxy(NFTManager, NFTManagerContract);

  console.log("Upgrade finished");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

