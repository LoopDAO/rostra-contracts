const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("ERC1155Proxy contract", function () {
  let ERC1155Proxy;
  let owner
  let alice
  let bob

  beforeEach(async function () {
    [owner, alice, bob] = await ethers.getSigners()
    const ERC1155ProxyContract = await ethers.getContractFactory("ERC1155Proxy");

    ERC1155Proxy = await upgrades.deployProxy(ERC1155ProxyContract, ['']);
    await ERC1155Proxy.setController(owner.address);
  })

  it("get initial state", async function () {
    const uri0 = await ERC1155Proxy.uri(0)
    const uri1 = await ERC1155Proxy.uri(1)

    expect(uri0).to.equal("")
    expect(uri1).to.equal("")
  })

  it("mint for same id", async function () {
    await ERC1155Proxy.mint(alice.address, 1, 10, [])
    await ERC1155Proxy.mint(bob.address, 1, 20, [])

    const aliceBalance = await ERC1155Proxy.balanceOf(alice.address, 1)
    const bobBalance = await ERC1155Proxy.balanceOf(bob.address, 1)

    expect(aliceBalance).to.equal(10)
    expect(bobBalance).to.equal(20)
  })

  it("mint for different id", async function () {
    await ERC1155Proxy.mint(alice.address, 1, 10, [])
    await ERC1155Proxy.mint(bob.address, 2, 20, [])

    const aliceBalance = await ERC1155Proxy.balanceOf(alice.address, 1)
    const bobBalance = await ERC1155Proxy.balanceOf(bob.address, 2)

    expect(aliceBalance).to.equal(10)
    expect(bobBalance).to.equal(20)
  })

  it("mintBatch", async function () {
    await ERC1155Proxy.mintBatch(alice.address, [1, 2], [10, 20], [])
    await ERC1155Proxy.mintBatch(bob.address, [3,4], [30, 40], [])

    const aliceBalance1 = await ERC1155Proxy.balanceOf(alice.address, 1)
    const aliceBalance2 = await ERC1155Proxy.balanceOf(alice.address, 2)
    const bobBalance1 = await ERC1155Proxy.balanceOf(bob.address, 3)
    const bobBalance2 = await ERC1155Proxy.balanceOf(bob.address, 4)

    expect(aliceBalance1).to.equal(10)
    expect(aliceBalance2).to.equal(20)
    expect(bobBalance1).to.equal(30)
    expect(bobBalance2).to.equal(40)
  })

  it("setURI", async function () {
    await ERC1155Proxy.setURI(1, "ipfs://test")
    const uri = await ERC1155Proxy.uri(1)
    expect(uri).to.equal("ipfs://test")
  })

  it("mintBatchAddresses", async function () {
    await ERC1155Proxy.mintBatchAddresses([alice.address, bob.address], [1, 2], [10, 20], [])

    const aliceBalance1 = await ERC1155Proxy.balanceOf(alice.address, 1)
    const aliceBalance2 = await ERC1155Proxy.balanceOf(alice.address, 2)
    const bobBalance1 = await ERC1155Proxy.balanceOf(bob.address, 1)
    const bobBalance2 = await ERC1155Proxy.balanceOf(bob.address, 2)

    expect(aliceBalance1).to.equal(10)
    expect(aliceBalance2).to.equal(0)
    expect(bobBalance1).to.equal(0)
    expect(bobBalance2).to.equal(20)
  })

  it("burn", async function () {
    await ERC1155Proxy.mintBatch(alice.address, [1, 2], [10, 20], [])

    const aliceBalance1 = await ERC1155Proxy.balanceOf(alice.address, 1)
    const aliceBalance2 = await ERC1155Proxy.balanceOf(alice.address, 2)

    expect(aliceBalance1).to.equal(10)
    expect(aliceBalance2).to.equal(20)

    await ERC1155Proxy.connect(alice).burn(alice.address, 1, 5)
    await ERC1155Proxy.connect(alice).burn(alice.address, 2, 20)

    const aliceBalance1After = await ERC1155Proxy.balanceOf(alice.address, 1)
    const aliceBalance2After = await ERC1155Proxy.balanceOf(alice.address, 2)
    expect(aliceBalance1After).to.equal(5)
    expect(aliceBalance2After).to.equal(0)
  })

  it("burnBatch", async function () {
    await ERC1155Proxy.mintBatch(alice.address, [1, 2], [10, 20], [])

    const aliceBalance1 = await ERC1155Proxy.balanceOf(alice.address, 1)
    const aliceBalance2 = await ERC1155Proxy.balanceOf(alice.address, 2)

    expect(aliceBalance1).to.equal(10)
    expect(aliceBalance2).to.equal(20)

    await ERC1155Proxy.connect(alice).burnBatch(alice.address, [1, 2], [5, 10])

    const aliceBalance1After = await ERC1155Proxy.balanceOf(alice.address, 1)
    const aliceBalance2After = await ERC1155Proxy.balanceOf(alice.address, 2)

    expect(aliceBalance1After).to.equal(5)
    expect(aliceBalance2After).to.equal(10)

    await ERC1155Proxy.connect(alice).burnBatch(alice.address, [1, 2], [5, 10])

    expect(await ERC1155Proxy.balanceOf(alice.address, 1)).to.equal(0)
    expect(await ERC1155Proxy.balanceOf(alice.address, 2)).to.equal(0)

  })

  it("transferOwnership", async function () {
    await ERC1155Proxy.transferOwnership(alice.address)
    await expect(ERC1155Proxy.transferOwnership(alice.address)).to.be.revertedWith("ERC1155Proxy: Caller is not the owner")
  })

  it("tokenTotalSupply", async function () {
    await ERC1155Proxy.mintBatchAddresses([alice.address, bob.address], [1, 2], [10, 20], [])
    await ERC1155Proxy.mintBatchAddresses([alice.address, bob.address], [2, 3], [20, 30], [])
    expect(await ERC1155Proxy.tokenTotalSupply(1)).to.equal(10)
    expect(await ERC1155Proxy.tokenTotalSupply(2)).to.equal(40)
    expect(await ERC1155Proxy.tokenTotalSupply(3)).to.equal(30)
  })

  it("tokenTotalSupplyBatch", async function () {
    await ERC1155Proxy.mintBatchAddresses([alice.address, bob.address], [1, 2], [10, 20], [])
    await ERC1155Proxy.mintBatchAddresses([alice.address, bob.address], [2, 3], [20, 30], [])
    const result = await ERC1155Proxy.tokenTotalSupplyBatch([1, 2, 3])
    expect(result[0]).to.equal(10)
    expect(result[1]).to.equal(40)
    expect(result[2]).to.equal(30)
  })
})

