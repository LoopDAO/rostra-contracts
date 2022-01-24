// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC1155Proxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/presets/ERC1155PresetMinterPauserUpgradeable.sol";

/// @title ERC1155Proxy
/// @notice A contract for encapsulating all logic
/// @notice This contract can be paused/unpaused by the admin
/// @dev The controller is the only contract that can mint and burn tokens
contract ERC1155Proxy is IERC1155Proxy, ERC1155PresetMinterPauserUpgradeable {
    /// @dev The address of the Controller contract which will be allowed to call
    /// the mint* and burn* functions
    address internal controller;

    /// @notice ERC1155 doesn't have the concept of totalSupply onchain
    /// so we must store that ourselves
    mapping(uint256 => uint256) public tokenTotalSupplies;

    mapping(uint256 => string) private _uris;

    /// @notice Perform inherited contracts' initializations
    function initialize(string memory _uri)
        public
        virtual
        override
        initializer
    {
        __ERC1155PresetMinterPauser_init(_uri);

        emit ERC1155ProxyInitialized(_uri);
    }

    ///////////////////// MODIFIER FUNCTIONS /////////////////////

    /// @notice Check if the _msgSender() is the privileged Controller contract address
    modifier onlyController() {
        require(
            _msgSender() == controller,
            "ERC1155Proxy: Sender must be the Controller"
        );

        _;
    }

    /// @notice Check if the _msgSender() is the privileged DEFAULT_ADMIN_ROLE holder
    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC1155Proxy: Caller is not the owner"
        );

        _;
    }

    ///////////////////// MUTATING FUNCTIONS /////////////////////

    /// @notice mint the specified amount of ERC1155 token and send to the given to address
    /// @dev This function is overriden only in order to enforce the `onlyController` modifer
    /// and add a total supply variable for each token
    /// @param to the address which will receive the minted token
    /// @param id the ERC1155 token to mint
    /// @param amount the amount of token to mint
    /// @param data unspecified data, for now this should not be used
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        override(ERC1155PresetMinterPauserUpgradeable, IERC1155Proxy)
        onlyController
    {
        // user ERC1155PresetMinterPauserUpgradeable's mint
        super.mint(to, id, amount, data);

        // ERC1155PresetMinterPauserUpgradeable doesn't have the concept of
        // totalSupply onchain so we must store and increment that ourselves
        tokenTotalSupplies[id] += amount;
    }

    /// @notice mint the specified amounts of ERC1155 tokens and sends them to the given address
    /// @dev This function is overriden only in order to enforce the `onlyController` modifer
    /// and add a total supply variable for each token
    /// @param to the address which will receive the minted token
    /// @param ids the ERC1155 tokens to mint
    /// @param amounts the amounts of token to mint
    /// @param data unspecified data, for now this should not be used
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        override(ERC1155PresetMinterPauserUpgradeable, IERC1155Proxy)
        onlyController
    {
        // user ERC1155PresetMinterPauserUpgradeable's mintBatch
        super.mintBatch(to, ids, amounts, data);

        // ERC1155PresetMinterPauserUpgradeable doesn't have the concept of
        // totalSupply onchain so we must store and increment that ourselves
        for (uint256 i = 0; i < ids.length; i++) {
            tokenTotalSupplies[ids[i]] += amounts[i];
        }
    }

    /// @notice mint the specified amounts of ERC1155 tokens and sends them to the given addresses
    /// @dev This function is overriden only in order to enforce the `onlyController` modifer
    /// and add a total supply variable for each token
    /// @param tos the addresses which will receive the minted token
    /// @param ids the ERC1155 tokens to mint
    /// @param amounts the amounts of token to mint
    /// @param data unspecified data, for now this should not be used
    function mintBatchAddresses(
        address[] memory tos,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyController {
        // ERC1155PresetMinterPauserUpgradeable doesn't have the concept of
        // totalSupply onchain so we must store and increment that ourselves
        for (uint256 i = 0; i < ids.length; i++) {
            tokenTotalSupplies[ids[i]] += amounts[i];
            // user ERC1155PresetMinterPauserUpgradeable's mint
            super.mint(tos[i], ids[i], amounts[i], data);
        }
    }

    /// @notice burn the specified amount of ERC1155 token
    /// @dev This function is overriden only in order to enforce the `onlyController` modifer
    /// and add a total supply variable for each token
    /// @param account the address for which to burn tokens
    /// @param id the ERC1155 token to burn
    /// @param amount the amount of token to burn
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public override(ERC1155BurnableUpgradeable, IERC1155Proxy) {
        // user ERC1155PresetMinterPauserUpgradeable's mint
        super.burn(account, id, amount);

        // ERC1155PresetMinterPauserUpgradeable doesn't have the concept of
        // totalSupply onchain so we must store and decrement that ourselves
        tokenTotalSupplies[id] -= amount;
    }

    /// @notice burn the specified amounts of ERC1155 tokens
    /// @param account the address for which to burn tokens
    /// @param ids the ERC1155 tokens to burn
    /// @param amounts the amounts of token to burn
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public override(ERC1155BurnableUpgradeable, IERC1155Proxy) {
        // user ERC1155PresetMinterPauserUpgradeable's burnBatch
        super.burnBatch(account, ids, amounts);

        // ERC1155PresetMinterPauserUpgradeable doesn't have the concept of
        // totalSupply onchain so we must store and decrement that ourselves
        for (uint256 i = 0; i < ids.length; i++) {
            tokenTotalSupplies[ids[i]] -= amounts[i];
        }
    }

    /// @notice transfer the MINTER_ROLE, DEFAULT_ADMIN_ROLE and PAUSER_ROLE from the _msgSender() to a new address
    /// @param _newAdmin the address of the new DEFAULT_ADMIN_ROLE and PAUSER_ROLE holder
    /// @dev only the admin address may call this function
    function transferOwnership(address _newAdmin) external onlyOwner {
        require(
            _newAdmin != _msgSender(),
            "ERC1155Proxy: cannot transfer ownership to existing owner"
        );

        grantRole(PAUSER_ROLE, _newAdmin);
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);

        renounceRole(PAUSER_ROLE, _msgSender());
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Sets `_tokenURI` as the tokenURI of `tokenId`.
    /// @param _id The ERC1155 ID
    /// @param _uri The ERC1155 _uri
    function setURI(uint256 _id, string memory _uri) public onlyOwner {
        _uris[_id] = _uri;
        emit URI(_uri, _id);
    }

    function setController(address _controller) public onlyOwner {
        require(controller != _controller, "ERC1155Proxy: This controller is already set");

        revokeRole(MINTER_ROLE, controller);
        grantRole(MINTER_ROLE, _controller);

        controller = _controller;
        emit ControllerChanged(_controller);
    }

    ///////////////////// VIEW/PURE FUNCTIONS /////////////////////

    /// @notice Returns the uri for the given ERC1155 ID
    /// @param id The ERC1155 ID
    /// @return The uri for the given ERC1155 ID
    function uri(uint256 id) public view override returns (string memory) {
        return (_uris[id]);
    }

    /// @notice Returns the total supply for the given ERC1155 ID
    /// @param id The ERC1155 ID
    /// @return The total supply
    function tokenTotalSupply(uint256 id)
        external
        view
        override
        returns (uint256)
    {
        return tokenTotalSupplies[id];
    }

    /// @notice Returns the total supply for multiple ERC1155 ID
    /// @param ids The ERC1155 IDs
    /// @return The total supplys for each ID
    function tokenTotalSupplyBatch(uint256[] memory ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory totalSupplies = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            totalSupplies[i] = tokenTotalSupplies[ids[i]];
        }
        return totalSupplies;
    }

    ///////////////////// EVENS /////////////////////

    /// @notice Emitted when the ERC1155Proxy is initialized
    event ERC1155ProxyInitialized(string uri);
    event NameChanged(string name);
    event ControllerChanged(address controller);

    uint256[50] private __gap;
}
