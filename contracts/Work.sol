// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./ERC721Base.sol";

contract Work is ERC721Base, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint8;
    using MathUpgradeable for uint8;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) public override initializer {
        super.initialize(_name, _symbol, _baseTokenURI);
        super.__ReentrancyGuard_init();
    }
}
