const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("NFTManager contract...", function () {
  let depolyedManManager;
  let owner
  let alice
  let bob
  let guildId1 = 1
  let guildId2 = 2
  let guildId3 = 3

  const erc1155proxyJson = require('../artifacts/contracts/ERC1155Proxy.sol/ERC1155Proxy.json');

  before(async function () {
    [owner, alice, bob] = await ethers.getSigners()

    const testContract = await ethers.getContractFactory("NFTManager");
    depolyedManManager = await upgrades.deployProxy(testContract, []);

    expect(depolyedManManager.address).to.not.be.null;
  });

  beforeEach(async function () {

  })

  it("should be able to create a new Proxy", async function () {
    //创建一个新的1155代理
    await depolyedManManager.createProxy();
    let proxyAddress = await depolyedManManager.ownerToProxies(owner.address, 0);
    expect(proxyAddress.length).to.be.equal(42);
    //设置并获取1155代理的公会ID
    await depolyedManManager.setGuildId(guildId1, proxyAddress);
    let proxyAddress2 = await depolyedManManager.guildIdToProxies(guildId1, 0)
    let gid = await depolyedManManager.proxyToGuildId(proxyAddress)
    expect(proxyAddress).to.be.equal(proxyAddress2);
    expect(guildId1).to.be.equal(gid);
    //getProxiesByGuildId
    //expect((await depolyedManManager.getProxiesByGuildId(guildId1)).length).to.be.equal(1);

    //alice创建一个新的1155代理
    await depolyedManManager.connect(alice).createProxy();
    proxyAddress = await depolyedManManager.ownerToProxies(alice.address, 0);
    expect(proxyAddress.length).to.be.equal(42);

    //设置并获取1155代理的公会ID
    await expect(
      depolyedManManager.setGuildId(guildId2, proxyAddress)
    ).to.be.revertedWith('NFTManager: Caller is not the owner');

    await depolyedManManager.connect(alice).setGuildId(guildId2, proxyAddress)
    proxyAddress2 = await depolyedManManager.guildIdToProxies(guildId2, 0);
    gid = await depolyedManManager.proxyToGuildId(proxyAddress)
    expect(proxyAddress).to.be.equal(proxyAddress2);
    expect(guildId2).to.be.equal(gid);
  })

  it("mintNewNFT...", async function () {
    let proxy = await depolyedManManager.ownerToProxies(alice.address, 0);
    await expect(
      depolyedManManager.mintNewNFT(proxy, 'ipfs://aaaa', [alice.address, bob.address])
    ).to.be.revertedWith('NFTManager: Caller is not the owner');

    await depolyedManManager.connect(bob).createProxy();
    proxy = await depolyedManManager.ownerToProxies(bob.address, 0);
    await depolyedManManager.connect(bob).mintNewNFT(proxy, 'ipfs://bbbb', [alice.address, bob.address]);


    const aliceIds = await depolyedManManager.getUserIds(alice.address)
    const bobIds = await depolyedManManager.getUserIds(bob.address)
    const ownerIds = await depolyedManManager.getUserIds(owner.address)

    expect(await depolyedManManager.proxyToId(proxy)).to.equal(1)
    expect(aliceIds.length).to.equal(1)
    expect(bobIds.length).to.equal(1)
    expect(ownerIds.length).to.equal(0)
  })

  it("setURI", async function () {
    let proxy = await depolyedManManager.ownerToProxies(bob.address, 0);

    const erc1155proxyJson = await require('../artifacts/contracts/ERC1155Proxy.sol/ERC1155Proxy.json');
    let proxy_ = await new ethers.Contract(proxy, erc1155proxyJson.abi, bob);

    await depolyedManManager.setURI(proxy, 11, "ipfs://test")
    //expect(await depolyedManManager.getURI(proxy, 11)).to.equal("ipfs://test")
    expect(await proxy_.uri(11)).to.equal("ipfs://test")

    await depolyedManManager.setURI(proxy, 2000002, "ipfs://test2")
    expect(await proxy_.uri(2000002)).to.equal("ipfs://test2")

    expect(await proxy_.uri(3000002)).to.equal("")
  })

  it("tokenTotalSupply", async function () {
    var proxy = await depolyedManManager.ownerToProxies(owner.address, 0)
    //console.log("owner proxy address:", proxy)
    var proxy_ = await new ethers.Contract(proxy, erc1155proxyJson.abi, owner);
    expect(await proxy_.tokenTotalSupply(1000002)).to.equal(0)
    expect(await depolyedManManager.tokenTotalSupply(proxy, 1000002)).to.equal(0)

    proxy = await depolyedManManager.ownerToProxies(alice.address, 0)
    //console.log("alice proxy address:", proxy)
    proxy_ = await new ethers.Contract(proxy, erc1155proxyJson.abi, alice);
    expect(await proxy_.tokenTotalSupply(1000002)).to.equal(0)
    expect(await depolyedManManager.tokenTotalSupply(proxy, 1000002)).to.equal(0)


    proxy = await depolyedManManager.ownerToProxies(bob.address, 0)
    //console.log("bob proxy address:", proxy)
    proxy_ = await new ethers.Contract(proxy, erc1155proxyJson.abi, bob);
    expect(await proxy_.tokenTotalSupply(1)).to.equal(2)
    expect(await depolyedManManager.tokenTotalSupply(proxy, 1)).to.equal(2)
  })
  it("tokenTotalSupplyBatch", async function () {
    let proxy = await depolyedManManager.ownerToProxies(bob.address, 0)

    await depolyedManManager.connect(bob).mintNewNFT(proxy, 'ipfs://22222', [alice.address, bob.address]);
    await depolyedManManager.connect(bob).mintNewNFT(proxy, 'ipfs://33333', [alice.address, bob.address, owner.address]);

    const tokenTotalSupplyBatch = await depolyedManManager.tokenTotalSupplyBatch(proxy, [1, 2, 3])
    expect(tokenTotalSupplyBatch.length).to.equal(3)
    expect(tokenTotalSupplyBatch[0]).to.equal(2)

  })

  it("mintExistingNFT...", async function () {
    let proxy = await depolyedManManager.ownerToProxies(bob.address, 0)

    await depolyedManManager.connect(bob).mintExistingNFT(proxy, 'ipfs://test3', [alice.address, bob.address]);

    const proxy_ = await new ethers.Contract(proxy, erc1155proxyJson.abi, bob);

    expect((await proxy_.uri(3))).to.equal('ipfs://test3')
    expect((await depolyedManManager.getUserIds(alice.address)).length).to.equal(4)
    expect((await depolyedManManager.getUserIds(bob.address)).length).to.equal(4)
    expect((await depolyedManManager.getUserIds(owner.address)).length).to.equal(1)
  })
  it("create a new Proxy-2", async function () {
    await depolyedManManager.createProxy();
    let proxy = await depolyedManManager.ownerToProxies(owner.address, 1);
    expect(proxy.length).to.be.equal(42);

    await depolyedManManager.createProxy();
    proxy = await depolyedManManager.ownerToProxies(owner.address, 2);
    expect(proxy.length).to.be.equal(42);

    await depolyedManManager.connect(alice).createProxy();
    proxy = await depolyedManManager.ownerToProxies(alice.address, 1);

    expect(proxy.length).to.be.equal(42);
  })
})

