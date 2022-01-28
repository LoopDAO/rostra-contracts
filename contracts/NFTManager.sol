// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./ERC1155Proxy.sol";
import "./interface/INFTManager.sol";

/// @title NFTManager
/// @author Rostra Dev
/// @notice NFT manages the entry master contract
contract NFTManager is INFTManager, OwnableUpgradeable, ReentrancyGuardUpgradeable {
	using AddressUpgradeable for address;
	using StringsUpgradeable for uint256;

	// proxy to id
	mapping(address => uint256[]) public ownerToIds;
	mapping(address => uint256) public proxyToId;

	// owner to proxy
	mapping(address => address[]) public ownerToProxies;
	mapping(address => address) public proxyToOwner;

	// guildId to proxy
	mapping(address => uint256) public proxyToGuildId;
	mapping(uint256 => address[]) public guildIdToProxies;

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

	function createProxy() external override nonReentrant {
		ERC1155Proxy proxy = new ERC1155Proxy{ salt: keccak256(abi.encode(msg.sender, ownerToProxies[msg.sender].length)) }();
        proxy.initialize('');
		proxy.setController(address(this));

		ownerToProxies[msg.sender].push(address(proxy));
		proxyToOwner[address(proxy)] = msg.sender;

		emit CreateProxy(address(proxy));
	}

	// set guild id to proxy
	function setGuildId(uint256 _guildId, address _erc1155Proxy) external override onlyProxyOwner(IERC1155Proxy(_erc1155Proxy)) nonReentrant {
		proxyToGuildId[_erc1155Proxy] = _guildId;
		guildIdToProxies[_guildId].push(_erc1155Proxy);
	}

	function mintNewNFT(
		IERC1155Proxy _erc1155Proxy,
		string memory _uri,
		address[] memory _addresses
	) external override onlyProxyOwner(_erc1155Proxy) nonReentrant {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		require(_addresses.length > 0, "Must supply at least one address");

        uint256 id = proxyToId[address(_erc1155Proxy)] + 1;
		_erc1155Proxy.mintAddresses(_addresses, id, 1, "");
		_erc1155Proxy.setURI(id, _uri);
		for (uint256 i = 0; i < _addresses.length; i++) {
			ownerToIds[_addresses[i]].push(id);
		}

		proxyToId[address(_erc1155Proxy)] = id;

		emit MintNewNFT(address(_erc1155Proxy), _uri, _addresses.length);
	}

	function mintExistingNFT(
		IERC1155Proxy _erc1155Proxy,
		string memory _uri,
		address[] memory _addresses
	) external override onlyProxyOwner(_erc1155Proxy) nonReentrant {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid Proxy address");
		require(_addresses.length > 0, "Must supply at least one address");

		uint256 _nftId = proxyToId[address(_erc1155Proxy)];
		require(_nftId != 0, "Must supply a valid NFT address");

		_erc1155Proxy.mintAddresses(_addresses, _nftId, 1, "");
		_erc1155Proxy.setURI(_nftId, _uri);
		for (uint256 i = 0; i < _addresses.length; i++) {
			ownerToIds[_addresses[i]].push(_nftId);
		}

		emit MintExistingNFT(address(_erc1155Proxy), _uri, _addresses.length);
	}

	function setURI(
		IERC1155Proxy _erc1155Proxy,
		uint256 _tokenId,
		string calldata _uri
	) external override nonReentrant {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		require(proxyToOwner[address(_erc1155Proxy)] == msg.sender, "Must the owner of proxy");
		_erc1155Proxy.setURI(_tokenId, _uri);

		emit SetURI(address(_erc1155Proxy), _tokenId, _uri);
	}

	function getUserIds(address _user) external override view returns (uint256[] memory) {
		return ownerToIds[_user];
	}

	function getGuildIdProxies(uint256 _guildId) external override view returns (address[] memory) {
		return guildIdToProxies[_guildId];
	}

	function getOwnerIds(address _owner) external override view returns (uint256[] memory) {
		return ownerToIds[_owner];
	}

	function getURI(IERC1155Proxy _erc1155Proxy, uint256 _tokenId) external override view returns (string memory) {
		return _erc1155Proxy.uri(_tokenId);
	}

	function tokenTotalSupply(IERC1155Proxy _erc1155Proxy, uint256 _id) external override view returns (uint256 amount) {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		amount = _erc1155Proxy.tokenTotalSupply(_id);
	}

	function tokenTotalSupplyBatch(IERC1155Proxy _erc1155Proxy, uint256[] calldata _ids) external override view returns (uint256[] memory ids) {
        require(address(_erc1155Proxy) != address(0), "Must supply a valid NFT address");
		ids = _erc1155Proxy.tokenTotalSupplyBatch(_ids);
	}
}
