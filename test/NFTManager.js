const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("NFTManager contract...", function () {
  let depolyedManManager;
  let owner
  let alice
  let bob
  let nftAddress

  const erc1155proxyJson = require('../artifacts/contracts/ERC1155Proxy.sol/ERC1155Proxy.json');

  before(async function () {
    [owner, alice, bob] = await ethers.getSigners()

    const testContract = await ethers.getContractFactory("NFTManager");
    depolyedManManager = await upgrades.deployProxy(testContract, [owner.address]);

    expect(depolyedManManager.address).to.not.be.null;
  });

  beforeEach(async function () {

  })

  it("should be able to create a new NFT", async function () {
    await depolyedManManager.createNFT(1);
    var ids = await depolyedManManager.getUserIds(owner.address);
    expect(ids.length).to.be.equal(1);
    expect(ids[0]).to.be.equal(1);

    await depolyedManManager.connect(alice).createNFT(2);
    ids = await depolyedManManager.getUserIds(alice.address);
    expect(ids.length).to.be.equal(1);
    expect(ids[0]).to.be.equal(2);
  })

  it("mintNewNFT...", async function () {
    await expect(
      depolyedManManager.mintNewNFT('ipfs://aaaa', [alice.address, bob.address])
    ).to.be.revertedWith('NFTManager: Caller is not the owner');

    await depolyedManManager.connect(bob).createNFT(3);
    await depolyedManManager.connect(bob).mintNewNFT('ipfs://bbbb', [alice.address, bob.address]);


    const aliceIds = await depolyedManManager.getUserIds(alice.address)
    const bobIds = await depolyedManManager.getUserIds(bob.address)
    const ownerIds = await depolyedManManager.getUserIds(owner.address)

    expect(await depolyedManManager.currentId()).to.equal(1000002)
    expect(aliceIds.length).to.equal(2)
    expect(bobIds.length).to.equal(2)
    expect(ownerIds.length).to.equal(1)
  })

  it("setURI", async function () {
    const nftAddress = await depolyedManManager.userToProxies(alice.address, 0);

    const erc1155proxyJson = await require('../artifacts/contracts/ERC1155Proxy.sol/ERC1155Proxy.json');
    const nft = await new ethers.Contract(nftAddress, erc1155proxyJson.abi, alice);

    await depolyedManManager.setERC1155Proxy(nftAddress)

    await depolyedManManager.setURI(11, "ipfs://test")
    expect(await nft.uri(11)).to.equal("ipfs://test")

    await depolyedManManager.setURI(2000002, "ipfs://test2")
    expect(await nft.uri(2000002)).to.equal("ipfs://test2")

    expect(await nft.uri(3000002)).to.equal("")
  })

  it("tokenTotalSupply", async function () {
    var nftAddress1 = await depolyedManManager.userToProxies(owner.address, 0)
    console.log("owner nftAddress", nftAddress1)
    var nft = await new ethers.Contract(nftAddress1, erc1155proxyJson.abi, owner);
    expect(await nft.tokenTotalSupply(1000002)).to.equal(0)

    nftAddress1 = await depolyedManManager.userToProxies(alice.address, 0)
    console.log("alice nftAddress", nftAddress1)
    nft = await new ethers.Contract(nftAddress1, erc1155proxyJson.abi, alice);
    expect(await nft.tokenTotalSupply(1000002)).to.equal(0)


    nftAddress1 = await depolyedManManager.userToProxies(bob.address, 0)
    console.log("bob nftAddress", nftAddress1)
    nft = await new ethers.Contract(nftAddress1, erc1155proxyJson.abi, bob);
    expect(await nft.tokenTotalSupply(1000002)).to.equal(2)

    await depolyedManManager.setERC1155Proxy(nftAddress1);
    expect(await depolyedManManager.tokenTotalSupply(1000002)).to.equal(2)

    nftAddress = nftAddress1;
  })
  it("tokenTotalSupplyBatch", async function () {
    await depolyedManManager.connect(bob).mintNewNFT('ipfs://22222', [alice.address, bob.address]);
    await depolyedManManager.connect(bob).mintNewNFT('ipfs://33333', [alice.address, bob.address, owner.address]);

    const tokenTotalSupplyBatch = await depolyedManManager.tokenTotalSupplyBatch([1000002, 1000003, 1000004])
    expect(tokenTotalSupplyBatch.length).to.equal(3)
    expect(tokenTotalSupplyBatch[0]).to.equal(2)

  })

  it("mintExistingNFT...", async function () {
    await depolyedManManager.connect(bob).mintExistingNFT(nftAddress, 'ipfs://test3', [alice.address, bob.address]);

    var nft = await new ethers.Contract(nftAddress, erc1155proxyJson.abi, bob);

    expect((await nft.uri(1000004))).to.equal('ipfs://test3')
    expect((await depolyedManManager.getUserIds(alice.address)).length).to.equal(5)
    expect((await depolyedManManager.getUserIds(bob.address)).length).to.equal(5)
    expect((await depolyedManManager.getUserIds(owner.address)).length).to.equal(2)
  })

})

