// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./SafeMath.sol";
import "./ERC721Base.sol";

contract Project is ERC721Base {
    using SafeMath for uint256;

    address payable public creator;
    string public title;
    string public description;
    uint256 public timeToSubmitWork;

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
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 price,
        uint256 limit,
        uint256 reserved

    ) public view returns (uint256) {
        return 1;
    }


}