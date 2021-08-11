const { expect } = require("chai");

describe("CrowdFunding contract", function() {
    let crowdFundingContract;

    beforeEach(async function () {
        const [owner] = await ethers.getSigners();
        console.log(owner.address)
        const crowdFundingContractFactory = await ethers.getContractFactory("CrowdFunding");

        crowdFundingContract = await crowdFundingContractFactory.deploy();
        await crowdFundingContract.deployed();

        expect(crowdFundingContract.address).to.not.equal(null);
      });

    it("Whenever you can start a new crowdfunding project", async function () {
        await crowdFundingContract.startProject("Buy toys","Buy toys",1,100)
        let allProject = await crowdFundingContract.returnAllProjects()

        expect(allProject.length).to.equal(1);
    });

});

