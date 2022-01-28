// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./ERC721Base.sol";

contract Project is
    ERC721Base,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public nftIdCounter;

    address public creator;
    string public creatorName;
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

    function initialize(
        string memory _creatorName,
        address _creator,
        string memory _title,
        string memory _description,
        uint256 _timeToSubmitWork,
        uint256 _price,
        uint256 _limit,
        // uint256 _reserved,
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) public initializer {
        creator = _creator;
        creatorName = _creatorName;
        title = _title;
        description = _description;
        timeToSubmitWork = _timeToSubmitWork;
        nftPrice = _price;
        nftLimit = _limit;
        // nftReserved = _reserved;

        super.initialize(_name, _symbol, _baseTokenURI);
        super.__ReentrancyGuard_init();
    }

    function init(
        string memory _creatorName,
        address _creator,
        string memory _title,
        string memory _description,
        uint256 _timeToSubmitWork,
        uint256 _price,
        uint256 _limit,
        // uint256 _reserved,
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) public initializer {
        initialize(
            _creatorName,
            _creator,
            _title,
            _description,
            _timeToSubmitWork,
            _price,
            _limit,
            _name,
            _symbol,
            _baseTokenURI
        );
    }

    function contribute(uint256 _nftAmountToBuy) external payable {
        require(msg.sender != creator, "You can't contribute to your own project");
        require(nftSoldAmount.add(_nftAmountToBuy) <= nftLimit, "Sold out");

        uint256 _contributionAmount = _nftAmountToBuy * nftPrice;
        require(_contributionAmount == msg.value, "Token amount incorrect");

        currentBalance = currentBalance.add(msg.value);
        nftSoldAmount = nftSoldAmount.add(_nftAmountToBuy);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);

        _claimNFT(msg.sender, _nftAmountToBuy);

        emit Contributed(msg.sender, _nftAmountToBuy, msg.value);
    }

    function _claimNFT(address _to, uint256 _nftAmountToBuy) internal {
        for (uint256 i = 0; i < _nftAmountToBuy; i++) {
            _safeMint(_to, nftIdCounter.current());
            nftIdCounter.increment();
        }
    }

    function withdraw() external {
        require(msg.sender == creator, "You must be the project creator to withdraw");

        uint256 withdrawalAmount = address(this).balance;

        payable(msg.sender).transfer(withdrawalAmount);
        currentBalance = 0;
        emit Withdrawn(msg.sender, withdrawalAmount);
    }

    function finishWork(string memory _title, string memory _description, string memory _url)
        external returns (bool)
    {
        require(msg.sender == creator, "Only creator");

        isWorkSubmitted = true;
        workTitle = _title;
        workDescription = _description;
        workUrl = _url;
        return true;
    }

    function getNextNFTId() external view returns(uint256) {
        return nftIdCounter.current();
    }

    event Contributed(address indexed _contributor, uint256 _nftAmount, uint256 _tokenAmount);
    event Withdrawn(address indexed withdrawer, uint256 withdrawalAmount);
}