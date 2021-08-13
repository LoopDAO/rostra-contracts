const { expect } = require("chai")
const { ethers } = require('hardhat')

describe("Project contract", function () {
    let projectContractFactory
    let projectContract
    let creator
    let donator1
    let donator2

    const SEVEN_DAYS = 7 * 24 * 60 * 60

    const name = "Research Uni V3"
    const description = "We will produce 3 videos"
    const timeToSubmitWork = parseInt(new Date().getTime()/1000) + SEVEN_DAYS

    const workResult = {
        name: 'Uni V3 analysis video',
        desc: 'Hope you enjoy our work',
        url: 'https://rostra.xyz/projects/0'
    }

    beforeEach(async function () {
        [creator, donator1, donator2] = await ethers.getSigners()
        projectContractFactory = await ethers.getContractFactory("Project")


        projectContract = await projectContractFactory.deploy(
            creator.address,
            name,
            description,
            timeToSubmitWork
        )

        expect(projectContract.address).to.not.be.null

        const nftInfo = {
            name: "Research Uni V3",
            symbol: "RUV3",
            uri: "https://rostra.xyz/api/nft-uri?id=",
            price: 10, // dai
            limit: 100,
            creator: 20 // creator nft amount
        }

        await projectContract.setNFTInfo(
            nftInfo.name,
            nftInfo.symbol,
            nftInfo.uri,
            nftInfo.price,
            nftInfo.limit,
            nftInfo.creator
        )
    })

    xit('Get project details', async function () {
        const projectDetail = await projectContract.getDetails()
        expect(projectDetail.creator).to.equal(creator.address)
        expect(projectDetail.description).to.equal(description)
        expect(projectDetail.timeToSubmitWork).to.equal(timeToSubmitWork)
    })

    xit('Buy 10 NFTs', async function () {
        const nftContractAddress = await projectContract.getNFTAddress()
        expect(nftContractAddress).to.notEmpty()

        const nftTotalBefore = nftContractAddress.totalSupply()
        expect(nftTotalBefore).to.equal(1)

        const nftAmountToBuy = 10

        await projectContract.connect(donator1).contribute(nftAmountToBuy)

        expect(await projectContract.currentBalance()).to.equal(nftAmountToBuy * nftInfo.price) // 100

        const nftTotalAfter = nftContractAddress.totalSupply()
        expect(nftTotalAfter).to.equal(10)

    })

    xit('Creator does not submit work, investors get 100% refund', async function () {
        const nftAmountToBuy = 10

        await projectContract.connect(donator1).contribute(nftAmountToBuy)
        await projectContract.connect(donator2).contribute(nftAmountToBuy)

        expect(await projectContract.currentBalance()).to.equal(200)

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        expect(await projectContract.withdraw())
            .revertedWithError(Error('Project is not complete'))

        await projectContract.connect(donator1).getRefund() // donator1 get refund 100%(100)
        expect(await projectContract.currentBalance()).to.equal(100)

        await projectContract.connect(donator2).getRefund() // donator2 get refund 100%(100)
        expect(await projectContract.currentBalance()).to.equal(0)
    })

    xit('Creator submitted work: Creator can get money after 7 days', async function () {
        const nftAmountToBuy = 10

        await projectContract.connect(donator1).contribute(nftAmountToBuy)
        await projectContract.connect(donator2).contribute(nftAmountToBuy)

        await projectContract.finishWork(workResult)

        expect(await projectContract.withdraw()).revertedWithError(Error('Project is not complete'))

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        expect(await projectContract.currentBalance()).to.equal(200)

        await projectContract.withdraw()

        expect(await projectContract.currentBalance()).to.equal(0)
    })

    xit('Creator submitted work: investors can get 50% refund', async function () {
        const nftAmountToBuy = 10

        await projectContract.connect(donator1).contribute(nftAmountToBuy)
        await projectContract.connect(donator2).contribute(nftAmountToBuy)

        expect(await projectContract.currentBalance()).to.equal(200)

        await projectContract.finishWork(workResult)

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        expect(await projectContract.withdraw())
            .revertedWithError(Error('Need to wait for 7 days in case any refund'))

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        await projectContract.connect(donator1).getRefund() // donator1 get refund 50%(50)
        expect(await projectContract.currentBalance()).to.equal(150)

        await projectContract.connect(donator2).getRefund() // donator2 get refund 50%(50)
        expect(await projectContract.currentBalance()).to.equal(100)

        // creator withdraw remaining
        await projectContract.withdraw()
        expect(await projectContract.currentBalance()).to.equal(0)
    })
})

