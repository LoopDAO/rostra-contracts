// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./ERC1155Proxy.sol";
import "./interface/IERC1155Proxy.sol";

import "hardhat/console.sol";

contract NFTManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
	using AddressUpgradeable for address;
	using StringsUpgradeable for uint256;

	//proxy to id
	mapping(address => uint256[]) public userToIds;
	mapping(address => uint256) public proxyToId;

	function initialize() public initializer {
		__Ownable_init();
		__ReentrancyGuard_init();
	}

	//-------------------------------
    //------- Events ----------------
    //-------------------------------

	event MintNewNFT(address proxy, string uri, uint256 addressAmount);
	event CreateProxy(address proxy);
	event SetURI(address proxy, uint256 tokenId, string uri);
	event MintExistingNFT(address _erc1155Proxy, string _uri, uint256 addressAmount);

    //-------------------------------
    //------- Modifier --------------
    //-------------------------------

	modifier onlyProxyOwner(IERC1155Proxy _erc1155Proxy) {
		require(proxyToOwner[address(_erc1155Proxy)] == msg.sender, "NFTManager: Caller is not the owner");
		_;
	}

    //-------------------------------
    //------- Users Functions -------
    //-------------------------------

	function createProxy() external {
		ERC1155Proxy proxy = new ERC1155Proxy{ salt: keccak256(abi.encode(msg.sender,userToProxies[msg.sender].length)) }();
        proxy.initialize('');
		proxy.setController(address(this));

		ownerToProxies[msg.sender].push(address(proxy));
		proxyToOwner[address(proxy)] = msg.sender;

		emit CreateProxy(address(proxy));
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
		IERC1155Proxy _erc1155Proxy,
		string memory _uri,
		address[] memory _addresses
	) external onlyProxyOwner(_erc1155Proxy) {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		require(_addresses.length > 0, "Must supply at least one address");

        uint256 id = proxyToId[address(_erc1155Proxy)] + 1;
		_erc1155Proxy.mintAddresses(_addresses, id, 1, "");
		_erc1155Proxy.setURI(id, _uri);
		for (uint256 i = 0; i < _addresses.length; i++) {
			userToIds[_addresses[i]].push(id);
		}

		proxyToId[address(_erc1155Proxy)] = id;

		emit MintNewNFT(address(_erc1155Proxy), _uri, _addresses.length);
	}

	function mintExistingNFT(
		IERC1155Proxy _erc1155Proxy,
		string memory _uri,
		address[] memory _addresses
	) external onlyProxyOwner(_erc1155Proxy) {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid Proxy address");
		require(_addresses.length > 0, "Must supply at least one address");

		uint256 _nftId = proxyToId[address(_erc1155Proxy)];
		require(_nftId != 0, "Must supply a valid NFT address");

		_erc1155Proxy.mintAddresses(_addresses, _nftId, 1, "");
		_erc1155Proxy.setURI(_nftId, _uri);
		for (uint256 i = 0; i < _addresses.length; i++) {
			userToIds[_addresses[i]].push(_nftId);
		}

		emit MintExistingNFT(address(_erc1155Proxy), _uri, _addresses.length);
	}

	function setURI(
		IERC1155Proxy _erc1155Proxy,
		uint256 _tokenId,
		string calldata _uri
	) external {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		require(proxyToOwner[address(_erc1155Proxy)] == msg.sender, "Must the owner of proxy");
		_erc1155Proxy.setURI(_tokenId, _uri);

		emit SetURI(address(_erc1155Proxy), _tokenId, _uri);
	}

	function getURI(IERC1155Proxy _erc1155Proxy, uint256 _tokenId) external returns (string memory uri) {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		uri = _erc1155Proxy.uri(_tokenId);
	}

	function tokenTotalSupply(IERC1155Proxy _erc1155Proxy, uint256 _id) external view returns (uint256 amount) {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		amount = _erc1155Proxy.tokenTotalSupply(_id);
	}

	function tokenTotalSupplyBatch(IERC1155Proxy _erc1155Proxy, uint256[] calldata _ids) external view returns (uint256[] memory ids) {
        require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		ids = _erc1155Proxy.tokenTotalSupplyBatch(_ids);
	}
}
