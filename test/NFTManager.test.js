const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("NFTManager contract...", function () {
  let nftManager;
  let owner
  let alice
  let bob
  let guildId1 = 1
  let guildId2 = 2
  let guildId3 = 3

  const erc1155proxyJson = require('../artifacts/contracts/ERC1155Proxy.sol/ERC1155Proxy.json');

  beforeEach(async function () {
    [owner, alice, bob] = await ethers.getSigners()

    const NFTManager = await ethers.getContractFactory("NFTManager");
    nftManager = await upgrades.deployProxy(NFTManager, []);

    expect(nftManager.address).to.not.be.null;
  });

  it("should be able to create guild repeat with revert", async () => {
    await expect(nftManager.createGuild("Guild", "", []))
    await expect(nftManager.createGuild("Guild", "", []))
      .to.be.revertedWith('NFTManager::createGuild: GuildName already exists');
  })

  it("should be able to create a new Guild", async function () {
    guildName = "Guild1";
    // 创建一个新的1155代理
    await nftManager.createGuild(guildName, "", []);
    let proxyAddress = await nftManager.ownerToProxies(owner.address, 0);
    expect(proxyAddress.length).to.be.equal(42);

    // // 设置并获取1155代理的公会ID
    let guildId = await nftManager.stringToBytes32(guildName);
    await nftManager.setGuildId(guildId, proxyAddress);

    proxyAddress2 = await nftManager.guildIdToProxy(guildId);
    let gid = await nftManager.proxyToGuildId(proxyAddress)
    expect(proxyAddress).to.be.equal(proxyAddress2);
    expect(guildId).to.be.equal(gid);

    // alice创建一个新的1155代理
    guildName2 = "Social Wiki";
    await nftManager.connect(alice).createGuild(guildName2, "", []);
    guildId2 = await nftManager.stringToBytes32(guildName2);
    proxyAddress = await nftManager.ownerToProxies(alice.address, 0);
    expect(proxyAddress.length).to.be.equal(42);
    let proxy_ = await new ethers.Contract(proxyAddress, erc1155proxyJson.abi, alice);
    const proxyName = await proxy_.name();
    expect(proxyName).to.be.equal(guildName2);

    // 设置并获取1155代理的公会ID
    await expect(
      nftManager.setGuildId(guildId2, proxyAddress)
    ).to.be.revertedWith('NFTManager: Caller is not the owner');

    await nftManager.connect(alice).setGuildId(guildId2, proxyAddress)
    proxyAddress2 = await nftManager.guildIdToProxy(guildId2);
    gid = await nftManager.proxyToGuildId(proxyAddress)
    expect(proxyAddress).to.be.equal(proxyAddress2);
    expect(guildId2).to.be.equal(gid);
  })

  it("mintNewNFT", async function () {
    guildName3 = "Guild3";
    await nftManager.connect(alice).createGuild(guildName3, "", []);
    guildId3 = await nftManager.stringToBytes32(guildName3);
    await expect(
      nftManager.mintNewNFT(guildId3, 'ipfs://aaaa', [alice.address, bob.address])
    ).to.be.revertedWith('NFTManager: Caller is not the owner');

    proxy = await nftManager.ownerToProxies(alice.address, 0);
    await nftManager.connect(alice).mintNewNFT(guildId3, 'ipfs://bbbb', [alice.address]);

    const aliceIds = await nftManager.getUserIds(alice.address)
    const bobIds = await nftManager.getUserIds(bob.address)
    const ownerIds = await nftManager.getUserIds(owner.address)

    expect(aliceIds.length).to.equal(1)
    expect(bobIds.length).to.equal(0)
    expect(ownerIds.length).to.equal(0)
  })

  it("setURI", async function () {
    guildName4 = "Guild4";
    await nftManager.connect(bob).createGuild(guildName4, "", []);
    guildId4 = await nftManager.stringToBytes32(guildName4);
    let proxy = await nftManager.ownerToProxies(bob.address, 0);
    let proxy_ = await new ethers.Contract(proxy, erc1155proxyJson.abi, bob);

    await nftManager.connect(bob).setURI(guildId4, 11, "ipfs://test")
    expect(await proxy_.uri(11)).to.equal("ipfs://test")

    await nftManager.connect(bob).setURI(guildId4, 2000002, "ipfs://test2")
    expect(await proxy_.uri(2000002)).to.equal("ipfs://test2")
    expect(await proxy_.uri(3000002)).to.equal("")
  })

  it("tokenTotalSupply", async function () {
    guildName5 = "Guild5";
    await nftManager.connect(owner).createGuild(guildName5, "ipfs://test", [alice.address, bob.address]);
    guildId5 = await nftManager.stringToBytes32(guildName5);

    proxy = await nftManager.ownerToProxies(owner.address, 0)
    proxy_ = await new ethers.Contract(proxy, erc1155proxyJson.abi, alice);
    expect(await proxy_.tokenTotalSupply(1000002)).to.equal(0)
    expect(await nftManager.tokenTotalSupply(guildId5, 1000002)).to.equal(0)
  })

  it("tokenTotalSupplyBatch", async function () {
    guildName5 = "Guild6";
    await nftManager.connect(bob).createGuild(guildName5, "ipfs://test", [alice.address, bob.address]);
    guildId5 = await nftManager.stringToBytes32(guildName5);

    let proxy = await nftManager.ownerToProxies(bob.address, 0);

    await nftManager.connect(bob).mintNewNFT(guildId5, 'ipfs://22222', [alice.address, bob.address]);
    await nftManager.connect(bob).mintNewNFT(guildId5, 'ipfs://33333', [alice.address, bob.address, owner.address]);

    const tokenTotalSupplyBatch = await nftManager.tokenTotalSupplyBatch(guildId5, [1, 2, 3])
    expect(tokenTotalSupplyBatch.length).to.equal(3)
    expect(tokenTotalSupplyBatch[0]).to.equal(2)
  })

  it("mintExistingNFT", async () => {
    guildName7 = "Guild7";
    await nftManager.connect(bob).createGuild(guildName7, "ipfs://test", [alice.address, bob.address]);
    guildId7 = await nftManager.stringToBytes32(guildName7);

    proxy = await nftManager.ownerToProxies(bob.address, 0);
    await nftManager.connect(bob).mintExistingNFT(guildId7, 'ipfs://test1', [alice.address]);

    expect((await nftManager.getUserIds(alice.address)).length).to.equal(2)
    expect((await nftManager.getUserIds(bob.address)).length).to.equal(1)
    expect((await nftManager.getUserIds(owner.address)).length).to.equal(0)
  })
})

