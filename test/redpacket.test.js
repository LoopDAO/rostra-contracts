const { expect } = require("chai");
const { ethers } = require('hardhat')

describe("Redpacket contract", function () {

  beforeEach(async () => {
    [owner, alice, bob, charles] = await ethers.getSigners();

    TestToken721 = await ethers.getContractFactory("TestToken_721");
    test_token_721 = await TestToken721.deploy(10);

    owner_address = alice.address;

    RedPacket_ERC721 = await ethers.getContractFactory("RedPacket_ERC1155");
    redpacket_721 = await RedPacket_ERC721.deploy();
    await redpacket_721.initialize();

    const input_token_ids = [0, 1, 2]
    creationParams = {
      owner_address,
      duration: 1000,
      seed: ethers.utils.solidityKeccak256(['string'],["asdasdasdasd"]),
      message: 'Hello',
      name: 'Alice',
      token_addr: test_token_721.address,
      erc721_token_ids: input_token_ids,
    }
    
    await test_token_721.setApprovalForAll(redpacket_721.address, true)
  });

  it("create redpacket", async () => {
    await redpacket_721.createRedPacket(
      ...Object.values(creationParams)
    );
    redPacketInfo = await getRedPacketInfo();
    // console.log(redPacketInfo.id);

    const claimParams = await createClaimParams(redPacketInfo.id, alice.address, alice)
    await redpacket_721.connect(alice).claim(...Object.values(claimParams));
  });

  async function createClaimParams(id, recipient, caller) {
    // const message = await redpacket_721.connect(alice).toEthSignMessage();
    // const e = ethers.utils.solidityKeccak256(['address'], [recipient]);
    // const message = ethers.utils.solidityKeccak256(
    //   ['bytes'],
    //   [
    //     ethers.utils.solidityPack(
    //       ['string', 'bytes32'],
    //       ["\x19Ethereum Signed Message:\n32", e]
    //     )
    //   ]
    // );
    const message = "hello"
    signedMsg = await caller.signMessage(message)
    // console.log(signedMsg)
    return {
      id,
      signedMsg,
      recipient,
    }
  }

  async function getRedPacketInfo() {
    const Redpacket = await ethers.getContractFactory("RedPacket_ERC1155");
    const redpacket = await Redpacket.attach(redpacket_721.address);
    const logs = await redpacket.filters.CreationSuccess();
    const _logs = await redpacket.queryFilter(logs, 0);
    return _logs[0].args;
  }
});
