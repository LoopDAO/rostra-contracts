const { expect } = require("chai")
const { ethers } = require('hardhat')

describe("Project contract", function () {
  let projectContractFactory
  let projectContract
  let creator
  let donator1
  let donator2

  const ONE_DAY = 24 * 60 * 60
  const SEVEN_DAYS = 7 * 24 * 60 * 60

  const creatorName = "Alice"
  const title = "Research Uni V3"
  const description = "We will produce 3 videos"
  let timeToSubmitWork
  const workResult = {
    title: 'Uni V3 analysis video',
    description: 'Hope you enjoy our work',
    url: 'https://rostra.xyz/projects/0'
  }

  const nftInfo = {
    name: "Research Uni V3",
    symbol: "RUV3",
    uri: "https://rostra.xyz/api/nft-uri?id=",
    price: 10, // dai
    limit: 100,
    // reserved: 20 // reserved nft amount
  }
  beforeEach(async function () {
    [creator, donator1, donator2] = await ethers.getSigners()
    projectContractFactory = await ethers.getContractFactory("Project")

    const blockNum = await ethers.provider.getBlockNumber();
    const block = await ethers.provider.getBlock(blockNum);
    const now = block.timestamp;

    timeToSubmitWork = now + SEVEN_DAYS

    projectContract = await projectContractFactory.deploy()

    await projectContract.init(
      creatorName,
      creator.address,
      title,
      description,
      timeToSubmitWork,
      nftInfo.price,
      nftInfo.limit,
      // nftInfo.reserved,
      nftInfo.name,
      nftInfo.symbol,
      nftInfo.uri
    )

    expect(projectContract.address).to.not.be.null
  })

  it('Get project details', async function () {
    expect(await projectContract.creator()).to.equal(creator.address)
    expect(await projectContract.creatorName()).to.equal(creatorName)
    expect(await projectContract.title()).to.equal(title)
    expect(await projectContract.description()).to.equal(description)
    expect(await projectContract.timeToSubmitWork()).to.equal(timeToSubmitWork)
    expect(await projectContract.owner()).to.equal(creator.address)
  })

  it('Buy 10 NFTs', async function () {
    const nftTotalBefore = await projectContract.getNextNFTId()
    expect(nftTotalBefore).to.equal(0)

    const nftAmountToBuy = 10

    await projectContract.connect(donator1)
      .contribute(nftAmountToBuy, { value: 100 })

    expect(await projectContract.currentBalance()).to.equal(nftAmountToBuy * nftInfo.price) // 100

    const nftTotalAfter = await projectContract.getNextNFTId()
    expect(nftTotalAfter).to.equal(10)

    const balance = await projectContract.balanceOf(donator1.address)
    expect(balance).to.equal(10)

  })

  it('Creator can submit work', async function () {
    await projectContract.finishWork(workResult.title, workResult.description, workResult.url)

    expect(await projectContract.isWorkSubmitted()).to.equal(true)
  })

  it('Creator can withdraw money anytime', async function () {
    const nftAmountToBuy = 10

    await projectContract.connect(donator1)
      .contribute(nftAmountToBuy, { value: 100 })

    expect(await projectContract.currentBalance()).to.equal(100)

    await projectContract.withdraw()

    expect(await projectContract.currentBalance()).to.equal(0)

    await projectContract.connect(donator2)
      .contribute(nftAmountToBuy, { value: 100 })

    expect(await projectContract.currentBalance()).to.equal(100)

    await projectContract.withdraw()

    expect(await projectContract.currentBalance()).to.equal(0)
  })

  it('Investors will get nft immediately after contribute', async function () {
    const nftAmountToBuy = 10

    const nextNFTId = await projectContract.getNextNFTId()
    expect(nextNFTId).to.equal(0)

    await projectContract.connect(donator1)
      .contribute(nftAmountToBuy, { value: 100 })

    const nextNFTId1 = await projectContract.getNextNFTId()
    expect(nextNFTId1).to.equal(10)

    await projectContract.connect(donator2)
      .contribute(nftAmountToBuy, { value: 100 })

    const nextNFTId2 = await projectContract.getNextNFTId()
    expect(nextNFTId2).to.equal(20)

    expect(await projectContract.currentBalance()).to.equal(200)

    // creator withdraw remaining
    await projectContract.withdraw()
    expect(await projectContract.currentBalance()).to.equal(0)
  })
})

