// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat"
import contracts from '../constants/contracts'

console.log( 'contracts: ', contracts)

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ERC1155Proxy = await ethers.getContractAt("ERC1155Proxy", contracts.ERC1155Proxy);

  const addresses = [
    "0x01AbECbEB70f67163a3aC8543E88d9C234A71Fa6",
    "0x496d56eadc895D6cBd46A97c729f0b89D91b58Cf",
    "0x54dBc5b60275f359C8db5A61c2aCEff2E5858d8d",
    "0xF36d01cd2E2Ee9D6e39801BD2C30233231319F40",
    "0xb39bebc396c0849d1f894efb9037b76640fff9ce"
  ]
  const tokenId = 1
  const uri = "https://bafyreifsejbymctnxfcs4lnax7lkipb2lbtpmqw2e7npvomycpodpe7gyq.ipfs.dweb.link/metadata.json"
  const ids = [1, 1, 1, 1, 1]
  // const ids = [2, 2, 2, 2, 2]

  const amounts = [1, 1, 1, 1, 1]

  const result = await ERC1155Proxy.setURI(tokenId, uri);
  await ERC1155Proxy.mintBatchAddresses(addresses, ids, amounts, [])

  const balance0 = await ERC1155Proxy.balanceOf(addresses[0], 1)
  const balance1 = await ERC1155Proxy.balanceOf(addresses[1], 1)
  const balance2 = await ERC1155Proxy.balanceOf(addresses[2], 1)
  const balance3 = await ERC1155Proxy.balanceOf(addresses[3], 1)
  const balance4 = await ERC1155Proxy.balanceOf(addresses[4], 1)

  console.log("balance0", balance0.toString());
  console.log("balance1", balance1.toString());
  console.log("balance2", balance2.toString());
  console.log("balance3", balance3.toString());
  console.log("balance4", balance3.toString());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

