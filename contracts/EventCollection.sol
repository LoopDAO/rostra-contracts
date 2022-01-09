// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Openzep
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Abstracts
import "./AbstractERC1155Factory.sol";

contract EventCollection is AbstractERC1155Factory {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    event Purchased(uint256 indexed index, address indexed account, uint256 amount);

    struct Utility {
        string name;
        string ipfsMetadataHash;
        string typeOf;
        string functionality;
        uint128 mintPriceNative;
        uint128 mintPrice;
        uint64 id;
        uint64 maxPurchaseTx;
        uint64 maxSupply;
        bool mintable;
        bool purchaseWithAxion;
        uint48 _gap;
    }

    address constant dead = 0x000000000000000000000000000000000000dEaD;
    Counters.Counter private counter;
    IERC20 public axion;

    mapping(uint256 => Utility) public utilities;
    mapping(address => bool) internal externalCallers;

    modifier onlyExternalCaller() {
        require(externalCallers[msg.sender], "Caller is not allowed");
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _axion
    ) public initializer {
        __ERC1155_init("ipfs://");
        __Ownable_init();
        name_ = _name;
        symbol_ = _symbol;

        axion = IERC20(_axion);
    }

    /**
     * @notice adds a new utility
     */
    function addUtility(
        string memory _name,
        string memory _typeOf,
        string memory _functionality,
        string memory _ipfsMetadataHash,
        uint128 _mintPrice,
        uint128 _mintPriceNative,
        uint64 _maxPurchaseTx,
        uint64 _maxSupply
    ) public onlyOwner {
        Utility storage util = utilities[counter.current()];
        util.id = uint16(counter.current());
        util.name = _name;
        util.typeOf = _typeOf;
        util.functionality = _functionality;
        util.maxPurchaseTx = _maxPurchaseTx;
        util.ipfsMetadataHash = _ipfsMetadataHash;
        util.mintPrice = _mintPrice;
        util.mintPriceNative = _mintPriceNative;
        util.maxSupply = _maxSupply;
        util.mintable = false;
        util.purchaseWithAxion = false;

        counter.increment();
    }

    /**
     * @notice edit an existing utility
     */
    function editUtility(
        string memory _name,
        string memory _typeOf,
        string memory _functionality,
        string memory _ipfsMetadataHash,
        uint128 _mintPrice,
        uint128 _mintPriceNative,
        uint64 _maxPurchaseTx,
        uint64 _maxSupply,
        uint256 _idx
    ) external onlyOwner {
        require(exists(_idx), "EditUtility: Utility does not exist");
        utilities[_idx].name = _name;
        utilities[_idx].typeOf = _typeOf;
        utilities[_idx].functionality = _functionality;
        utilities[_idx].ipfsMetadataHash = _ipfsMetadataHash;
        utilities[_idx].mintPrice = _mintPrice;
        utilities[_idx].mintPriceNative = _mintPriceNative;
        utilities[_idx].maxSupply = _maxSupply;
        utilities[_idx].maxPurchaseTx = _maxPurchaseTx;
    }

    /**
     * @notice make utility mintable
     */
    function updateMintable(uint256 _idx, bool _mintable) external onlyOwner {
        utilities[_idx].mintable = _mintable;
    }

    /**
     * @notice make purchasable with axion
     */
    function updatePurchaseWithAxn(uint256 _idx, bool _purchasable) external onlyOwner {
        utilities[_idx].purchaseWithAxion = _purchasable;
    }

    /**
     * @notice mint utility tokens
     *
     * @param utilityIdx the utility id to mint
     * @param amount the amount of tokens to mint
     */
    function mint(
        uint256 utilityIdx,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(exists(utilityIdx), "Mint: Utility does not exist");
        require(
            totalSupply(utilityIdx) + amount < utilities[utilityIdx].maxSupply,
            "Mint: Max supply reached"
        );

        _mint(to, utilityIdx, amount, "");

        emit Purchased(utilityIdx, to, amount);
    }

    /**
     * @notice mint utility tokens
     *
     * @param utilityIdx the utility id to mint
     * @param amount the amount of tokens to mint
     */
    function mintExternal(
        uint256 utilityIdx,
        uint256 amount,
        address to
    ) external onlyExternalCaller {
        require(exists(utilityIdx), "Mint: Utility does not exist");
        require(
            totalSupply(utilityIdx) + amount < utilities[utilityIdx].maxSupply,
            "Mint: Max supply reached"
        );

        _mint(to, utilityIdx, amount, "");

        emit Purchased(utilityIdx, to, amount);
    }

    /**
     * @notice mint utility tokens
     *
     * @param utilityIdx the utility id to mint
     * @param amount the amount of tokens to mint
     */
    function bulkMint(
        uint256 utilityIdx,
        uint256 amount,
        address[] calldata to
    ) external onlyOwner {
        require(exists(utilityIdx), "Mint: Utility does not exist");

        for (uint256 i = 0; i < to.length; i++) {
            require(
                totalSupply(utilityIdx) + amount < utilities[utilityIdx].maxSupply,
                "Mint: Max supply reached"
            );

            _mint(to[i], utilityIdx, amount, "");

            emit Purchased(utilityIdx, to[i], amount);
        }
    }

    /**
     * @notice purchase utility tokens
     *
     * @param utilId the utility id to purchase
     * @param amount the amount of tokens to purchase
     */
    function purchase(uint256 utilId, uint16 amount) external whenNotPaused {
        require(
            utilities[utilId].purchaseWithAxion,
            "Purchase: Buy with axion disabled for token set"
        );
        require(utilities[utilId].mintable == true, "Purchase: Token is not mintable");
        require(
            amount <= utilities[utilId].maxPurchaseTx,
            "Purchase: Max purchase per tx exceeded"
        );
        require(
            totalSupply(utilId) + amount <= utilities[utilId].maxSupply,
            "Purchase: Max total supply reached"
        );
        /** Transfer Axion */
        axion.safeTransferFrom(msg.sender, dead, amount * utilities[utilId].mintPrice);

        _mint(msg.sender, utilId, amount, "");

        emit Purchased(utilId, msg.sender, amount);
    }

    /**
     * @notice purchase utility tokens
     *
     * @param utilId the utility id to purchase
     * @param amount the amount of tokens to purchase
     */
    function purchaseNative(uint256 utilId, uint16 amount) external payable whenNotPaused {
        require(
            amount <= utilities[utilId].maxPurchaseTx,
            "Purchase: Max purchase per tx exceeded"
        );
        require(
            totalSupply(utilId) + amount <= utilities[utilId].maxSupply,
            "Purchase: Max total supply reached"
        );

        require(
            msg.value == amount * utilities[utilId].mintPriceNative,
            "Purchase: Incorrect payment"
        );

        _mint(msg.sender, utilId, amount, "");

        emit Purchased(utilId, msg.sender, amount);
    }

    /**
     * @notice Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address to) external onlyOwner {
        uint256 balance = address(this).balance;

        payable(to).transfer(balance);
    }

    /**
     * @notice return total supply for all existing utilitys
     */
    function totalSupplyAll() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](counter.current());

        for (uint256 i; i < counter.current(); i++) {
            result[i] = totalSupply(i);
        }

        return result;
    }

    /**
     *   @notice gets habitatutilitys
     */
    function getUtilities() external view returns (Utility[] memory) {
        Utility[] memory _utils = new Utility[](counter.current());

        for (uint256 i = 0; i < counter.current(); i++) {
            _utils[i] = utilities[i];
        }

        return _utils;
    }

    /** @notice get current idx */
    function getCurrentCounter() external view returns (uint256) {
        return counter.current();
    }

    /**
     * @notice indicates weither any token exist with a given id, or not
     */
    function exists(uint256 id) public view override returns (bool) {
        return utilities[id].maxSupply > 0;
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the utility id to return metadata for
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), utilities[_id].ipfsMetadataHash));
    }

    /** Setters */

    /**
     * @notice sets an external caller
     */
    function setExternalCaller(address caller, bool enabled) external onlyOwner {
        externalCallers[caller] = enabled;
    }

    uint256[50] private __gap;

}