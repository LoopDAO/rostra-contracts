// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC1155Proxy.sol";
import "./IERC1155Proxy.sol";

import "hardhat/console.sol";

contract NFTManager is Initializable {
	using AddressUpgradeable for address;
	using StringsUpgradeable for uint256;

	IERC1155Proxy public erc1155Proxy;
	address public controller;
	uint256 public currentId;

	mapping(address => uint256[]) public userToIds;
	mapping(address => address[]) public userToProxies;
	mapping(address => uint256) public proxyToId;
	mapping(address => address) private proxyToOwner;

	function initialize(address _controller) public virtual initializer {
		controller = _controller;
		currentId = 1000001;
	}

	modifier onlyOwner() {
		require(proxyToOwner[address(erc1155Proxy)] == msg.sender, "NFTManager: Caller is not the owner");

		_;
	}

	function createNFT(uint256 index) public returns (address) {
		ERC1155Proxy nft = new ERC1155Proxy{ salt: keccak256(abi.encode(msg.sender, index)) }(address(this));

		userToProxies[msg.sender].push(address(nft));
		userToIds[msg.sender].push(index);

		proxyToOwner[address(nft)] = msg.sender;

		erc1155Proxy = nft;
		return address(nft);
	}

	function mintNewNFT(string memory _uri, address[] memory _addresses) public onlyOwner {
		require(_addresses.length > 0, "Must supply at least one address");

		uint256 id = currentId + 1;

		erc1155Proxy.mintAddresses(_addresses, id, 1, "");

		erc1155Proxy.setURI(id, _uri);
		for (uint256 i = 0; i < _addresses.length; i++) {
			userToIds[_addresses[i]].push(id);
		}
		proxyToId[address(erc1155Proxy)] = id;
        currentId = id;
	}

	function mintExistingNFT(
		address _nftAddress,
		string memory _uri,
		address[] memory _addresses
	) external {
		require(_addresses.length > 0, "Must supply at least one address");
		require(_nftAddress != address(0), "Must supply a valid NFT address");

		erc1155Proxy = IERC1155Proxy(_nftAddress);
		require(address(erc1155Proxy) != address(0), "Must supply a valid NFT address");

		uint256 _nftId = proxyToId[_nftAddress];
        require(_nftId != 0, "Must supply a valid NFT address");

		erc1155Proxy.mintAddresses(_addresses, _nftId, 1, "");
		erc1155Proxy.setURI(_nftId, _uri);
		for (uint256 i = 0; i < _addresses.length; i++) {
			userToIds[_addresses[i]].push(_nftId);
		}
	}

	function getUserIds(address _user) public view returns (uint256[] memory) {
		return userToIds[_user];
	}

	function setURI(uint256 _tokenId, string memory _uri) external {
		erc1155Proxy.setURI(_tokenId, _uri);
	}

	function getURI(uint256 _tokenId) external returns (string memory) {
		string memory _uri = erc1155Proxy.uri(_tokenId);
		return _uri;
	}

	function tokenTotalSupply(uint256 id) external view returns (uint256) {
		return erc1155Proxy.tokenTotalSupply(id);
	}

	function tokenTotalSupplyBatch(uint256[] memory ids) external view returns (uint256[] memory) {
        
		return erc1155Proxy.tokenTotalSupplyBatch(ids);
	}

	function setERC1155Proxy(IERC1155Proxy _erc1155Proxy) public {
		require(address(_erc1155Proxy) != address(0), "Must supply a valid ERC1155Proxy address");
		erc1155Proxy = _erc1155Proxy;
	}
}
