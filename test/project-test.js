const { expect } = require("chai")
const { ethers } = require('hardhat')

describe("Project contract", function () {
    let projectContractFactory
    let projectContract
    let creator
    let donator1
    let donator2

    const SEVEN_DAYS = 7 * 24 * 60 * 60

    const title = "Research Uni V3"
    const description = "We will produce 3 videos"
    const timeToSubmitWork = parseInt(new Date().getTime()/1000) + SEVEN_DAYS

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


        projectContract = await projectContractFactory.deploy(
            creator.address,
            title,
            description,
            timeToSubmitWork
        )

        expect(projectContract.address).to.not.be.null

        await projectContract.initialize(
            nftInfo.name,
            nftInfo.symbol,
            nftInfo.uri
        )

        await projectContract.setNFTInfo(
            nftInfo.price,
            nftInfo.limit,
            // nftInfo.reserved
        )
    })

    it('Get project details', async function () {
        expect(await projectContract.creator()).to.equal(creator.address)
        expect(await projectContract.title()).to.equal(title)
        expect(await projectContract.description()).to.equal(description)
        expect(await projectContract.timeToSubmitWork()).to.equal(timeToSubmitWork)
    })

    it('Buy 10 NFTs', async function () {
        const nftContractAddress = await projectContract.getNFTAddress()
        expect(nftContractAddress).is.not.null;

        const nftTotalBefore = await projectContract.getNextNFTId()
        expect(nftTotalBefore).to.equal(0)

        const nftAmountToBuy = 10

        await projectContract.connect(donator1)
            .contribute(nftAmountToBuy, { value: 100 })

        expect(await projectContract.currentBalance()).to.equal(nftAmountToBuy * nftInfo.price) // 100

        // const nftTotalAfter = await projectContract.getNextNFTId()
        // expect(nftTotalAfter).to.equal(10)

    })

    it('Creator does not submit work, investors get 100% refund', async function () {
        const nftAmountToBuy = 10

        await projectContract.connect(donator1)
            .contribute(nftAmountToBuy, { value: 100 })
        await projectContract.connect(donator2)
            .contribute(nftAmountToBuy, { value: 100 })

        expect(await projectContract.currentBalance()).to.equal(200)

        await expect(projectContract.withdraw())
            .to.be.revertedWith('Project is not complete')

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        await expect(projectContract.withdraw())
            .to.be.revertedWith('Project is not complete')

        await projectContract.connect(donator1).refund() // donator1 get refund 100%(100)
        expect(await projectContract.currentBalance()).to.equal(100)

        await projectContract.connect(donator2).refund() // donator2 get refund 100%(100)
        expect(await projectContract.currentBalance()).to.equal(0)
    })

    it('Creator submitted work: Creator can get money after 7 days', async function () {
        const nftAmountToBuy = 10

        await projectContract.connect(donator1)
            .contribute(nftAmountToBuy, { value: 100 })
        await projectContract.connect(donator2)
            .contribute(nftAmountToBuy, { value: 100 })

        await projectContract.finishWork(workResult.title, workResult.description, workResult.url)

        expect(await projectContract.isWorkSubmitted()).to.equal(true)

        await expect(projectContract.withdraw())
            .to.be.revertedWith('Project is not complete')

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        expect(await projectContract.currentBalance()).to.equal(200)
        
        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        await projectContract.withdraw()

        expect(await projectContract.currentBalance()).to.equal(0)
    })

    it('Creator submitted work: investors can get 50% refund', async function () {
        const nftAmountToBuy = 10

        await projectContract.connect(donator1)
            .contribute(nftAmountToBuy, { value: 100 })
        await projectContract.connect(donator2)
            .contribute(nftAmountToBuy, { value: 100 })

        expect(await projectContract.currentBalance()).to.equal(200)

        await projectContract.finishWork(workResult.title, workResult.description, workResult.url)

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        await expect(projectContract.withdraw())
            .to.be.revertedWith('Need to wait for 7 days in case any refund')

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        await projectContract.connect(donator1).refund() // donator1 get refund 50%(50)
        expect(await projectContract.currentBalance()).to.equal(150)

        await projectContract.connect(donator2).refund() // donator2 get refund 50%(50)
        expect(await projectContract.currentBalance()).to.equal(100)

        // creator withdraw remaining
        await projectContract.withdraw()
        expect(await projectContract.currentBalance()).to.equal(0)
    })

    it('Creator submitted work: investors can claim nft after 1 week', async function () {
        const nftAmountToBuy = 10

        await projectContract.connect(donator1)
            .contribute(nftAmountToBuy, { value: 100 })
        await projectContract.connect(donator2)
            .contribute(nftAmountToBuy, { value: 100 })

        await projectContract.finishWork(workResult.title, workResult.description, workResult.url)

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        await expect(projectContract.withdraw())
            .to.be.revertedWith('Need to wait for 7 days in case any refund')

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS + 1])
        await ethers.provider.send('evm_mine')

        const nextNFTId = await projectContract.getNextNFTId()
        expect(nextNFTId).to.equal(0)

        await projectContract.connect(donator1).claimNFT() // got 10 nft
        const nextNFTId1 = await projectContract.getNextNFTId()
        expect(nextNFTId1).to.equal(10)

        await projectContract.connect(donator2).claimNFT() // got 10 nft
        const nextNFTId2 = await projectContract.getNextNFTId()
        expect(nextNFTId2).to.equal(20)

        expect(await projectContract.currentBalance()).to.equal(200)

        // creator withdraw remaining
        await projectContract.withdraw()
        expect(await projectContract.currentBalance()).to.equal(0)
    })

    it('Creator submitted work: investors can not claim nft if refunded', async function () {
        const nftAmountToBuy = 10

        await projectContract.connect(donator1)
            .contribute(nftAmountToBuy, { value: 100 })
        await projectContract.connect(donator2)
            .contribute(nftAmountToBuy, { value: 100 })

        await projectContract.finishWork(workResult.title, workResult.description, workResult.url)

        await ethers.provider.send('evm_increaseTime', [SEVEN_DAYS])
        await ethers.provider.send('evm_mine')

        await expect(projectContract.withdraw())
            .to.be.revertedWith('Need to wait for 7 days in case any refund')

        const nextNFTId = await projectContract.getNextNFTId()
        expect(nextNFTId).to.equal(0)

        await projectContract.connect(donator1).claimNFT() // got 10 nft
        await expect(projectContract.connect(donator1).claimNFT())
            .to.be.revertedWith('You have already claimed NFT')
        await expect(projectContract.connect(donator1).refund())
            .to.be.revertedWith('You have already claimed NFT')

        const nextNFTId1 = await projectContract.getNextNFTId()
        expect(nextNFTId1).to.equal(10)

        await projectContract.connect(donator2).refund() // donator2 get refund 50%(50)

        await expect(projectContract.connect(donator1).claimNFT())
            .to.be.revertedWith('You have already refunded')
        await expect(projectContract.connect(donator1).refund())
            .to.be.revertedWith('You have already refunded')

        const nextNFTId2 = await projectContract.getNextNFTId()
        expect(nextNFTId2).to.equal(10)

        expect(await projectContract.currentBalance()).to.equal(150)

        // creator withdraw remaining
        await projectContract.withdraw()
        expect(await projectContract.currentBalance()).to.equal(0)
    })
})

