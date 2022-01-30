// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./ERC1155Proxy.sol";
import "./interface/INFTManager.sol";

/// @title NFTManager
/// @author Rostra Dev
/// @notice NFT manages the entry master contract
contract NFTManager is
    INFTManager,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // proxy to id
    mapping(address => uint256[]) public ownerToIds;
    mapping(address => uint256) public proxyToId;

    // owner to proxy
    mapping(address => address[]) public ownerToProxies;
    mapping(address => address) public proxyToOwner;

    // guildId to proxy
    mapping(address => bytes32) public proxyToGuildId;
    mapping(bytes32 => address) public guildIdToProxy;

    // guildName to GuildId
    mapping(string => bytes32) public guildNameToGuildId;

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
    event MintExistingNFT(
        address erc1155Proxy,
        string uri,
        uint256 addressAmount
    );

    //-------------------------------
    //------- Modifier --------------
    //-------------------------------

    modifier onlyProxyOwner(address _erc1155Proxy) {
        require(
            proxyToOwner[address(_erc1155Proxy)] == msg.sender,
            "NFTManager: Caller is not the owner"
        );
        _;
    }

    //-------------------------------
    //------- Internal Functions ----
    //-------------------------------

    function createProxy() internal returns (address) {
        ERC1155Proxy proxy = new ERC1155Proxy{
            salt: keccak256(
                abi.encode(msg.sender, ownerToProxies[msg.sender].length)
            )
        }();
        proxy.initialize("");
        proxy.setController(address(this));

        ownerToProxies[msg.sender].push(address(proxy));
        proxyToOwner[address(proxy)] = msg.sender;

        emit CreateProxy(address(proxy));
        return address(proxy);
    }

    //-------------------------------
    //------- Users Functions -------
    //-------------------------------

    function createGuild(
        string calldata _guildName,
        string calldata _uri,
        address[] calldata _addresses
    ) external override nonReentrant {
        require(
            guildNameToGuildId[_guildName] == bytes32(""),
            "NFTManager::createGuild: GuildName already exists"
        );
        bytes32 guildId = keccak256(abi.encodePacked(_guildName));
        guildNameToGuildId[_guildName] = guildId;
        address erc1155proxy = createProxy();
        setGuildId(guildId, erc1155proxy);
        setNFTName(_guildName, erc1155proxy);
        if (_addresses.length > 0) {
            mintNewNFT(guildId, _uri, _addresses);
        }
    }

    // set guild id to proxy
    function setGuildId(bytes32 _guildId, address _erc1155Proxy)
        public
        override
        onlyProxyOwner(_erc1155Proxy)
    {
        proxyToGuildId[_erc1155Proxy] = _guildId;
        guildIdToProxy[_guildId] = _erc1155Proxy;
    }

    // set nft name
    function setNFTName(string memory _guildName, address _erc1155Proxy)
        public
		override
        onlyProxyOwner(_erc1155Proxy)
    {
        IERC1155Proxy(_erc1155Proxy).setName(_guildName);
    }

    function mintNewNFT(
        bytes32 _guildId,
        string memory _uri,
        address[] memory _addresses
    ) public override onlyProxyOwner(guildIdToProxy[_guildId]) {
        address _erc1155Proxy = guildIdToProxy[_guildId];
        require(
            _erc1155Proxy != address(0),
            "NFTManager: Must supply a valid NFT address"
        );
        require(
            _addresses.length > 0,
            "NFTManager: Must supply at least one address"
        );

        uint256 id = proxyToId[address(_erc1155Proxy)] + 1;
        IERC1155Proxy(_erc1155Proxy).mintAddresses(_addresses, id, 1, "");
        IERC1155Proxy(_erc1155Proxy).setURI(id, _uri);
        for (uint256 i = 0; i < _addresses.length; i++) {
            ownerToIds[_addresses[i]].push(id);
        }

        proxyToId[address(_erc1155Proxy)] = id;

        emit MintNewNFT(address(_erc1155Proxy), _uri, _addresses.length);
    }

    function mintExistingNFT(
        bytes32 _guildId,
        string memory _uri,
        address[] memory _addresses
    ) external override nonReentrant onlyProxyOwner(guildIdToProxy[_guildId]) {
        address _erc1155Proxy = guildIdToProxy[_guildId];
        require(
            address(_erc1155Proxy) != address(0),
            "NFTManager: Must supply a valid Proxy address"
        );
        require(
            _addresses.length > 0,
            "NFTManager: Must supply at least one address"
        );

        uint256 _nftId = proxyToId[address(_erc1155Proxy)];
        require(_nftId != 0, "NFTManager: Must supply a valid NFT address");

        IERC1155Proxy(_erc1155Proxy).mintAddresses(_addresses, _nftId, 1, "");
        IERC1155Proxy(_erc1155Proxy).setURI(_nftId, _uri);
        for (uint256 i = 0; i < _addresses.length; i++) {
            ownerToIds[_addresses[i]].push(_nftId);
        }

        emit MintExistingNFT(address(_erc1155Proxy), _uri, _addresses.length);
    }

    function setURI(
        bytes32 _guildId,
        uint256 _tokenId,
        string calldata _uri
    ) external override nonReentrant {
        address _erc1155Proxy = guildIdToProxy[_guildId];
        require(
            _erc1155Proxy != address(0),
            "NFTManager: Must supply a valid NFT address"
        );
        require(
            proxyToOwner[address(_erc1155Proxy)] == msg.sender,
            "NFTManager: Must the owner of proxy"
        );
        IERC1155Proxy(_erc1155Proxy).setURI(_tokenId, _uri);

        emit SetURI(address(_erc1155Proxy), _tokenId, _uri);
    }

    function getUserIds(address _user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return ownerToIds[_user];
    }

    function getOwnerIds(address _owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        return ownerToIds[_owner];
    }

    function getURI(bytes32 _guildId, uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        address _erc1155Proxy = guildIdToProxy[_guildId];
        require(
            _erc1155Proxy != address(0),
            "NFTManager: Must supply a valid NFT address"
        );
        return IERC1155Proxy(_erc1155Proxy).uri(_tokenId);
    }

    function tokenTotalSupply(bytes32 _guildId, uint256 _id)
        external
        view
        override
        returns (uint256 amount)
    {
        address _erc1155Proxy = guildIdToProxy[_guildId];
        require(
            _erc1155Proxy != address(0),
            "NFTManager: Must supply a valid NFT address"
        );
        amount = IERC1155Proxy(_erc1155Proxy).tokenTotalSupply(_id);
    }

    function tokenTotalSupplyBatch(bytes32 _guildId, uint256[] calldata _ids)
        external
        view
        override
        returns (uint256[] memory ids)
    {
        address _erc1155Proxy = guildIdToProxy[_guildId];
        require(
            _erc1155Proxy != address(0),
            "NFTManager: Must supply a valid NFT address"
        );
        ids = IERC1155Proxy(_erc1155Proxy).tokenTotalSupplyBatch(_ids);
    }

    function stringToBytes32(string calldata _str)
        external
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_str));
    }
}
