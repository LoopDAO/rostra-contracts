// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./SafeMath.sol";
import "./ERC721Base.sol";

contract Project is ERC721Base {
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public nftIdCounter;

    address payable public creator;
    string public title;
    string public description;
    uint256 public timeToSubmitWork;

    uint256 nftPrice;
    uint256 nftLimit;
    // uint256 nftReserved;


    constructor(
        address payable _creator,
        string memory _title,
        string memory _description,
        uint256 _timeToSubmitWork
    ) {
        creator = _creator;
        title = _title;
        description = _description;
        timeToSubmitWork = _timeToSubmitWork;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) public override initializer {
        super.initialize(_name, _symbol, _baseTokenURI);
    }

    function setNFTInfo(
        uint256 _price,
        uint256 _limit
        // uint256 _reserved
    ) public {
        nftPrice = _price;
        nftLimit = _limit;
        // nftReserved = _reserved;
    }

    function contribute(uint256 _nftAmountToBuy) external payable returns (bool) {
        require(msg.sender != creator);
        require(nftIdCounter.current() < nftLimit, "Sold out");

        uint256 _contributionAmount = _nftAmountToBuy * nftPrice;
        require(_contributionAmount == msg.value, "Token amount incorrect");

        nftIdCounter.increment();
        _safeMint(msg.sender, nftIdCounter.current());

        // todo: event

        return true;
    }

    function getNFTAddress() external view returns(address) {
        return address(this);
    }

    function getCurrentNFTId() external view returns(uint256) {
        return nftIdCounter.current();
    }

}