// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC1155Proxy.sol";

interface INFTManager {
    function createProxy() external;
    function setGuildId(uint256 _guildId, address _erc1155Proxy) external;
    function mintNewNFT(
		IERC1155Proxy _erc1155Proxy,
		string memory _uri,
		address[] memory _addresses
	) external;
    function mintExistingNFT(
		IERC1155Proxy _erc1155Proxy,
		string memory _uri,
		address[] memory _addresses
	) external;
    function setURI(
		IERC1155Proxy _erc1155Proxy,
		uint256 _tokenId,
		string calldata _uri
	) external;
    function getUserIds(address _user) external view returns (uint256[] memory);
    function getGuildIdProxies(uint256 _guildId) external view returns (address[] memory);
    function getOwnerIds(address _owner) external view returns (uint256[] memory);
    function getURI(IERC1155Proxy _erc1155Proxy, uint256 _tokenId) external view returns (string memory);
    function tokenTotalSupply(IERC1155Proxy _erc1155Proxy, uint256 _id) external view returns (uint256 amount);
    function tokenTotalSupplyBatch(IERC1155Proxy _erc1155Proxy, uint256[] calldata _ids) external view returns (uint256[] memory ids);
}
