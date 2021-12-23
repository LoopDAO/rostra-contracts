const { expect } = require("chai")
const { ethers } = require('hardhat')

describe("Paper contract", function () {
  let crowdFundingContract;
  let paperContractFactory
  let paperContract
  let creator
  let donator1
  let donator2

  const creatorName = "Alice"
  const title = "Research Uni V3"
  const description = "We will produce 3 videos"
  const paperURL = "ipfs://my-paper-url"

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
    const crowdFundingContractFactory = await ethers.getContractFactory("CrowdFunding");
    crowdFundingContract = await crowdFundingContractFactory.deploy();

    paperContractFactory = await ethers.getContractFactory("Paper")

    await crowdFundingContract.startPaperMining(
      creatorName,
      title,
      description,
      nftInfo.price,
      nftInfo.limit,
      nftInfo.name,
      nftInfo.symbol,
      nftInfo.uri,
      paperURL
      // nftInfo.reserved
    )
    const papers = await crowdFundingContract.returnAllPapers()

    expect(papers.length).to.equal(1);

    paperContract = await ethers.getContractAt("Paper", papers[0])

  })

  it('Get project details', async function () {
    expect(await paperContract.creator()).to.equal(creator.address)
    expect(await paperContract.creatorName()).to.equal(creatorName)
    expect(await paperContract.title()).to.equal(title)
    expect(await paperContract.description()).to.equal(description)
    expect(await paperContract.owner()).to.equal(crowdFundingContract.address)
  })

  it('Buy 10 NFTs', async function () {
    const nftTotalBefore = await paperContract.getNextNFTId()
    expect(nftTotalBefore).to.equal(0)

    const nftAmountToBuy = 10

    await paperContract.connect(donator1)
      .contribute(nftAmountToBuy, { value: 100 })

    expect(await paperContract.currentBalance()).to.equal(nftAmountToBuy * nftInfo.price) // 100

    const nftTotalAfter = await paperContract.getNextNFTId()
    expect(nftTotalAfter).to.equal(10)

    const balance = await paperContract.balanceOf(donator1.address)
    expect(balance).to.equal(10)

  })

  it('Creator can withdraw money anytime', async function () {
    const nftAmountToBuy = 10

    await paperContract.connect(donator1)
      .contribute(nftAmountToBuy, { value: 100 })

    expect(await paperContract.currentBalance()).to.equal(100)

    await paperContract.withdraw()

    expect(await paperContract.currentBalance()).to.equal(0)

    await paperContract.connect(donator2)
      .contribute(nftAmountToBuy, { value: 100 })

    expect(await paperContract.currentBalance()).to.equal(100)

    await paperContract.withdraw()

    expect(await paperContract.currentBalance()).to.equal(0)
  })

  it('Investors will get nft immediately after contribute', async function () {
    const nftAmountToBuy = 10

    const nextNFTId = await paperContract.getNextNFTId()
    expect(nextNFTId).to.equal(0)

    await paperContract.connect(donator1)
      .contribute(nftAmountToBuy, { value: 100 })

    const nextNFTId1 = await paperContract.getNextNFTId()
    expect(nextNFTId1).to.equal(10)

    await paperContract.connect(donator2)
      .contribute(nftAmountToBuy, { value: 100 })

    const nextNFTId2 = await paperContract.getNextNFTId()
    expect(nextNFTId2).to.equal(20)

    expect(await paperContract.currentBalance()).to.equal(200)

    // creator withdraw remaining
    await paperContract.withdraw()
    expect(await paperContract.currentBalance()).to.equal(0)
  })
})

