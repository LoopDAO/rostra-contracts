const { expect } = require("chai");

describe("CrowdFunding contract", function() {
    let crowdFundingContract;

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
        const crowdFundingContractFactory = await ethers.getContractFactory("CrowdFunding");
        const blockNum = await ethers.provider.getBlockNumber();
        const block = await ethers.provider.getBlock(blockNum);
        const now = block.timestamp;

        timeToSubmitWork = now + SEVEN_DAYS

        crowdFundingContract = await crowdFundingContractFactory.deploy();

        expect(crowdFundingContract.address).to.not.be.null;
      });

    it("Whenever you can start a new crowdfunding project", async function () {
        await crowdFundingContract.startProject(
            creatorName,
            title,
            description,
            timeToSubmitWork,
            nftInfo.price,
            nftInfo.limit,
            nftInfo.name,
            nftInfo.symbol,
            nftInfo.uri
            // nftInfo.reserved
        )
        let allProject = await crowdFundingContract.returnAllProjects()

        expect(allProject.length).to.equal(1);
    });
});

