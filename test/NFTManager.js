const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("NFTManager contract...", function () {
  let depolyedManManager;
  let owner
  let alice
  let bob

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
    const nftAddress = depolyedManManager.userToProxies(alice.address, 0);

    const ERC1155ProxyContract = await ethers.getContractFactory("ERC1155Proxy");
    const ERC1155Proxy = await ERC1155ProxyContract.deploy(9);
    const ss = await ERC1155Proxy.deploy();
    const nft = new ethers.Contract(nftAddress, ss.abi, alice);
    console.log("nft", nft)
    // await depolyedManManager.setURI(11, "ipfs://test")
    // var uri = await nft.uri(11)
    // expect(uri).to.equal("ipfs://test")

    // await depolyedManManager.setURI(1000002, "ipfs://test")
    // uri = await ERC1155Proxy.uri(1000002)
    // expect(uri).to.equal("ipfs://test")

    // uri = await depolyedManManager.getURI(1000002)
    // expect(uri.hash).to.not.equal("")

  })

  // it("tokenTotalSupply", async function () {
  //   //const tokenTotalSupply = await depolyedManManager.tokenTotalSupply(1000002)
  //   expect(await depolyedManManager.tokenTotalSupply(1000002)).to.equal(2)

  // })
  // it("tokenTotalSupplyBatch", async function () {
  //   await depolyedManManager.mintNewNFT('ipfs://22222', [alice.address, bob.address]);
  //   await depolyedManManager.mintNewNFT('ipfs://33333', [alice.address, bob.address]);

  //   const tokenTotalSupplyBatch = await depolyedManManager.tokenTotalSupplyBatch([1000002, 1000003, 1000004])
  //   expect(tokenTotalSupplyBatch.length).to.equal(3)
  //   expect(tokenTotalSupplyBatch[0]).to.equal(2)

  // })

  // it("mintExistingNFT...", async function () {
  //   await depolyedManManager.mintExistingNFT(ERC1155Proxy.address, 'ipfs://test2', [alice.address, bob.address]);

  //   expect((await ERC1155Proxy.uri(1000002))).to.equal('ipfs://test')
  //   expect((await depolyedManManager.getUserIds(alice.address)).length).to.equal(4)
  //   expect((await depolyedManManager.getUserIds(bob.address)).length).to.equal(4)
  //   expect((await depolyedManManager.getUserIds(owner.address)).length).to.equal(0)
  // })

})

