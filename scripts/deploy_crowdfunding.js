// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require("hardhat");
const { CrowdFunding } = require("../constants/deployedContracts");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
      "Deploying contracts with the account:",
      deployer.address
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  //deploy Crowdfunding
  const CrowdFundingContract = await ethers.getContractFactory("CrowdFunding");
  // const result = await upgrades.deployProxy(CrowdFundingContract);
  const result = await upgrades.upgradeProxy(CrowdFunding, CrowdFundingContract);

  console.log("CrowdFundingContract address:", result.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

