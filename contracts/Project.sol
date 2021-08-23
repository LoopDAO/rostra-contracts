// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./SafeMath.sol";
import "./ERC721Base.sol";

contract Project is
    ERC721Base,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public nftIdCounter;

    uint256 public gracePeriod = 1 days;

    address payable public creator;
    string public title;
    string public description;
    uint256 public timeToSubmitWork;

    string public workTitle;
    string public workDescription;
    string public workUrl;

    uint256 public currentBalance;
    bool public isWorkSubmitted = false;

    uint256 public nftSoldAmount;

    uint256 public nftPrice;
    uint256 public nftLimit;
    // uint256 public nftReserved;

    mapping (address => uint256) public contributions;
    mapping (address => uint256) public nftAmounts;
    mapping (address => bool) public nftClaims;
    mapping (address => bool) public refunds;

    constructor(
        address payable _creator,
        string memory _title,
        string memory _description,
        uint256 _timeToSubmitWork,
        uint256 _price,
        uint256 _limit
        // uint256 _reserved
    ) {
        creator = _creator;
        title = _title;
        description = _description;
        timeToSubmitWork = _timeToSubmitWork;
        nftPrice = _price;
        nftLimit = _limit;
        // nftReserved = _reserved;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) public override initializer {
        super.initialize(_name, _symbol, _baseTokenURI);
        super.__ReentrancyGuard_init();
    }

    function contribute(uint256 _nftAmountToBuy) external payable returns (bool) {
        require(msg.sender != creator, "You can't contribute to your own project");
        require(nftSoldAmount.add(_nftAmountToBuy) <= nftLimit, "Sold out");
        require(!refunds[msg.sender], "You have already refunded");

        uint256 _contributionAmount = _nftAmountToBuy * nftPrice;
        require(_contributionAmount == msg.value, "Token amount incorrect");

        currentBalance = currentBalance.add(msg.value);
        nftSoldAmount = nftSoldAmount.add(_nftAmountToBuy);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        nftAmounts[msg.sender] = nftAmounts[msg.sender].add(_nftAmountToBuy);

        emit Contributed(msg.sender, _nftAmountToBuy, msg.value);
        return true;
    }

    function claimNFT() external payable returns (bool) {
        require(block.timestamp >= timeToSubmitWork, "Project is not complete");
        require(!refunds[msg.sender], "You have already refunded");
        require(!nftClaims[msg.sender], "You have already claimed NFT");

        nftClaims[msg.sender] = true;

        for (uint256 i = 0; i < nftAmounts[msg.sender]; i++) {
            _safeMint(msg.sender, nftIdCounter.current());
            nftIdCounter.increment();
        }

        return true;
    }

    function withdraw() external returns (bool) {
        require(msg.sender == creator, "You must be the project creator to withdraw");
        // require(isWorkSubmitted, "You must submit work before you can withdraw");
        require(
            isWorkSubmitted && block.timestamp >= timeToSubmitWork.add(gracePeriod),
            "Project is not complete"
        );
        payable(msg.sender).transfer(currentBalance);
        currentBalance = 0;
        return true;
    }

    function finishWork(string memory _title, string memory _description, string memory _url)
        external returns (bool)
    {
        require(msg.sender == creator, "Only creator");
        require(!isWorkSubmitted && block.timestamp < timeToSubmitWork, "Too late");
        isWorkSubmitted = true;
        workTitle = _title;
        workDescription = _description;
        workUrl = _url;
        return true;
    }

    function refund() external nonReentrant returns (bool) {
        require(block.timestamp >= timeToSubmitWork, "Project is not complete");
        // require(!isWorkSubmitted, "Can not refund due to creator already submitted the work");
        require(!refunds[msg.sender], "You have already refunded");
        require(!nftClaims[msg.sender], "You have already claimed NFT");

        uint256 refundAmount = contributions[msg.sender];
        if (isWorkSubmitted) {
            refundAmount = contributions[msg.sender].div(2);
        }
        refunds[msg.sender] = true;
        currentBalance = currentBalance.sub(refundAmount);
        contributions[msg.sender] = contributions[msg.sender].sub(refundAmount);
        nftAmounts[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
        emit Refunded(msg.sender, refundAmount);
        return true;
    }

    function setGracePeriod(uint _gracePeriod) onlyOwner external {
        gracePeriod = _gracePeriod;
    }

    function getNextNFTId() external view returns(uint256) {
        return nftIdCounter.current();
    }

    event Contributed(address indexed _contributor, uint256 _nftAmount, uint256 _tokenAmount);
    event Refunded(address indexed _contributor, uint256 _tokenAmount);
}