
const isSvg = require('is-svg')
const fs = require('fs')
const { expect } = require("chai")
const { ethers } = require('hardhat')


describe("NFTSvg contract", function () {
  let svgBase64
  let svgContractFactory
  let svgContract
  let creator
  let donator1
  let donator2

  let tokenId

  const creatorName = "Alice"
  const ownerName = "Bob"
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

  tokenId = 123
  //creatorAddress = `0x${'b'.repeat(40)}`
  creatorAddress = '0xabcdeabcdefabcdefabcdefabcdefabcdefabcdf'
  ownerAddress = '0x1234567890123456789123456789012345678901'

  beforeEach(async function () {
    [creator, donator1, donator2] = await ethers.getSigners()
    svgContractFactory = await ethers.getContractFactory("NFTSvgTest")
    svgContract = await svgContractFactory.deploy()
  })

  it('returns a valid SVG', async () => {
    const svg = await svgContract.generateSVGImage({
      name: nftInfo.name,
      tokenId: 123,
      creator: creatorAddress,
      owner: ownerAddress,
      creatorName: creatorName,
      ownerName: ownerName,
      title: title,
      description: description,
      price: nftInfo.price,
      limit: nftInfo.limit,
      symbol: nftInfo.symbol,
      baseTokenURI: nftInfo.uri,
      paperURL: paperURL
    })

    //expect(svg).toMatchSnapshot()
    //console.log("svg-----------", svg)
    expect(isSvg(svg)).to.eq(true)
    fs.writeFileSync('./NFT-RUV3.svg', svg)
  })

})

