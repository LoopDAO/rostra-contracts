const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("NFTManager contract...", function () {
  let depolyedManManager;
  let owner
  let alice
  let bob

  before(async function () {
    [owner, alice, bob] = await ethers.getSigners()

    const ERC1155ProxyContract = await ethers.getContractFactory("ERC1155Proxy");
    ERC1155Proxy = await upgrades.deployProxy(ERC1155ProxyContract,
      [owner.address]);

    const testContract = await ethers.getContractFactory("NFTManager");
    depolyedManManager = await upgrades.deployProxy(testContract,
      [owner.address]);

    await ERC1155Proxy.setController(depolyedManManager.address);
    await ERC1155Proxy.transferOwnership(depolyedManManager.address);
    await depolyedManManager.setERC1155Proxy(ERC1155Proxy.address);

    expect(depolyedManManager.address).to.not.be.null;
  });

  beforeEach(async function () {

  })



  it("mintNewNFT...", async function () {

    await depolyedManManager.mintNewNFT('ipfs://12323', [alice.address, bob.address]);

    const nftId = await depolyedManManager.currentId()
    const aliceIds = await depolyedManManager.getUserIds(alice.address)
    const bobIds = await depolyedManManager.getUserIds(bob.address)
    const ownerIds = await depolyedManManager.getUserIds(owner.address)
    const uri = await ERC1155Proxy.uri(1000002)

    expect(uri).to.equal('ipfs://12323')
    expect(nftId).to.equal(1000002)
    expect(aliceIds.length).to.equal(1)
    expect(bobIds.length).to.equal(1)
    expect(ownerIds.length).to.equal(0)
  })

  it("setURI", async function () {
    await depolyedManManager.setURI(11, "ipfs://test")
    var uri = await ERC1155Proxy.uri(11)
    expect(uri).to.equal("ipfs://test")

    await depolyedManManager.setURI(1000002, "ipfs://test")
    uri = await ERC1155Proxy.uri(1000002)
    expect(uri).to.equal("ipfs://test")

    uri = await depolyedManManager.getURI(1000002)
    expect(uri.hash).to.not.equal("")

  })

  it("tokenTotalSupply", async function () {
    //const tokenTotalSupply = await depolyedManManager.tokenTotalSupply(1000002)
    expect(await depolyedManManager.tokenTotalSupply(1000002)).to.equal(2)

  })
  it("tokenTotalSupplyBatch", async function () {
    await depolyedManManager.mintNewNFT('ipfs://22222', [alice.address, bob.address]);
    await depolyedManManager.mintNewNFT('ipfs://33333', [alice.address, bob.address]);

    const tokenTotalSupplyBatch = await depolyedManManager.tokenTotalSupplyBatch([1000002, 1000003, 1000004])
    expect(tokenTotalSupplyBatch.length).to.equal(3)
    expect(tokenTotalSupplyBatch[0]).to.equal(2)

  })

  it("mintExistingNFT...", async function () {
    await depolyedManManager.mintExistingNFT(ERC1155Proxy.address, 'ipfs://test2', [alice.address, bob.address]);

    expect((await ERC1155Proxy.uri(1000002))).to.equal('ipfs://test')
    expect((await depolyedManManager.getUserIds(alice.address)).length).to.equal(4)
    expect((await depolyedManManager.getUserIds(bob.address)).length).to.equal(4)
    expect((await depolyedManManager.getUserIds(owner.address)).length).to.equal(0)
  })

})

