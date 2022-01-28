// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC1155Proxy.sol";
import "./IERC1155Proxy.sol";

import "hardhat/console.sol";

contract NFTManager is Initializable {
	using AddressUpgradeable for address;
	using StringsUpgradeable for uint256;

	//proxy to id
	mapping(address => uint256[]) public userToIds;
	mapping(address => uint256) public proxyToId;

	//owner to proxy
	mapping(address => address[]) public ownerToProxies;
	mapping(address => address) public proxyToOwner;

	//guildId to proxy
	mapping(address => uint256) public proxyToGuildId;
	mapping(uint256 => address[]) public guildIdToProxies;

	modifier onlyOwner(address _erc1155Proxy) {
		require(proxyToOwner[address(_erc1155Proxy)] == msg.sender, "NFTManager: Caller is not the owner");

		_;
	}

	function createProxy() public returns (address) {
		ERC1155Proxy proxy = new ERC1155Proxy{ salt: keccak256(abi.encode(msg.sender, ownerToProxies[msg.sender].length)) }();
		proxy.initialize("");
		proxy.setController(address(this));

		ownerToProxies[msg.sender].push(address(proxy));
		proxyToOwner[address(proxy)] = msg.sender;

		return address(proxy);
	}

	// set guild id to proxy
	function setGuildId(uint256 guildId, address _erc1155Proxy) public {
		require(proxyToOwner[_erc1155Proxy] == msg.sender, "NFTManager: Caller is not the owner");

		proxyToGuildId[_erc1155Proxy] = guildId;
		guildIdToProxies[guildId].push(_erc1155Proxy);
	}

	function getProxiesByGuildId(uint256 guildId) public returns (address[] memory) {
		require(guildId != 0, "NFTManager: GuildId is 0");
		return guildIdToProxies[guildId];
	}

	function mintNewNFT(
		address _erc1155Proxy,
		string memory _uri,
		address[] memory _addresses
	) public onlyOwner(_erc1155Proxy) {
		require(_addresses.length > 0, "Must supply at least one address");

		IERC1155Proxy proxy = IERC1155Proxy(_erc1155Proxy);
		require(address(proxy) != address(0), "Must supply a valid NFT address");

		uint256 id = proxyToId[address(proxy)] + 1;
		proxy.mintAddresses(_addresses, id, 1, "");
		proxy.setURI(id, _uri);
		for (uint256 i = 0; i < _addresses.length; i++) {
			userToIds[_addresses[i]].push(id);
		}

		proxyToId[address(proxy)] = id;
	}

	function mintExistingNFT(
		address _erc1155Proxy,
		string memory _uri,
		address[] memory _addresses
	) external onlyOwner(_erc1155Proxy) {
		require(_addresses.length > 0, "Must supply at least one address");
		require(_erc1155Proxy != address(0), "Must supply a valid Proxy address");

		IERC1155Proxy proxy = IERC1155Proxy(_erc1155Proxy);
		require(address(proxy) != address(0), "Must supply a valid NFT address");

		uint256 _nftId = proxyToId[_erc1155Proxy];
		require(_nftId != 0, "Must supply a valid NFT address");

		proxy.mintAddresses(_addresses, _nftId, 1, "");
		proxy.setURI(_nftId, _uri);
		for (uint256 i = 0; i < _addresses.length; i++) {
			userToIds[_addresses[i]].push(_nftId);
		}
	}

	function getUserIds(address _user) public view returns (uint256[] memory) {
		return userToIds[_user];
	}

	function setURI(
		address _erc1155Proxy,
		uint256 _tokenId,
		string memory _uri
	) external {
		IERC1155Proxy proxy = IERC1155Proxy(_erc1155Proxy);
		require(address(proxy) != address(0), "Must supply a valid NFT address");

		proxy.setURI(_tokenId, _uri);
	}

	function getURI(address _erc1155Proxy, uint256 _tokenId) external returns (string memory) {
		IERC1155Proxy proxy = IERC1155Proxy(_erc1155Proxy);
		require(address(proxy) != address(0), "Must supply a valid NFT address");

		string memory _uri = proxy.uri(_tokenId);
		return _uri;
	}

	function tokenTotalSupply(address _erc1155Proxy, uint256 id) external view returns (uint256) {
		IERC1155Proxy proxy = IERC1155Proxy(_erc1155Proxy);
		require(address(proxy) != address(0), "Must supply a valid NFT address");

		return proxy.tokenTotalSupply(id);
	}

	function tokenTotalSupplyBatch(address _erc1155Proxy, uint256[] memory ids) external view returns (uint256[] memory) {
		IERC1155Proxy proxy = IERC1155Proxy(_erc1155Proxy);
		require(address(proxy) != address(0), "Must supply a valid NFT address");

		return proxy.tokenTotalSupplyBatch(ids);
	}
}
