// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";
import "./lib/Claimable.sol";
import "./lib/VaLiFiHelpers.sol";
import "./lib/Math.sol";

interface IPresale {
    function getYieldBoxAllocated(address _userAddress)
        external
        view
        returns (uint256);

    function claimYieldBox(address _userAddress) external returns (bool);
}

interface IPresaleRefund {
    function getRepurchaseYieldBoxAllocated(address _userAddress)
        external
        view
        returns (uint256);

    function claimYieldBox(address _userAddress) external returns (bool);
}

/**
 * @title YieldBox Contract / NFT Smart Contract ERC721
 * @dev Implementation of the YieldBox NFT ERC721.
 * @custom:a ValiFi
 */
contract YieldBox is
    Claimable,
    Math,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // Interfaces of Regular YieldKey, Legendary YieldKey, Staked Regular YieldKey and Staked Legendary YieldKey contracts
    IYieldKey private ValiFiNFTv3;
    IStakedYieldKey private LegYieldKey;
    IStakedYieldKey private RegYieldKey;
    IYieldKey private YieldKey;
    IPresale private Presale1;
    IPresale private Presale2;
    IPresaleRefund private Presale3;
    IRouter private router;
    // Role Reward claimer
    bytes32 public constant ROLE_REWARD_CLAIMER =
        keccak256("ROLE_REWARD_CLAIMER");
    /** @dev Max Total Supply is the maximum possible amount */
    uint256 public constant TOTAL_SUPPLY = ~(uint256(0)) >> 1;
    /** @dev Token Address */
    address public tokenAddress;
    /** @dev USD-pegged ERC20 stable coin according to our current liquidity pool pair base value */
    address public usdAddress;
    /** @dev Base Token URI */
    string private BASE_URI;
    /** @dev Liquidity Address */
    address private liquidity;
    /** @dev rewards Address */
    address private rewards;
    /** @dev treasuryAddress Address */
    address private treasuryAddress;
    /** @dev payrollFund Address */
    address private payrollFund;
    /** @dev Weighted value Between ValiFi and Stable coin */
    uint256 private Sval; // Stable coin weighted value
    uint256 private Vval; // ValiFi weighted value
    /**
     * @dev Struct of the YieldBox
     */
    struct YieldBoxStruct {
        /** @dev YieldBox Status */
        bool status;
        /** @dev Dead YieldBox Token */
        bool dead;
        /** @dev Time of Last Claim */
        uint64 rewardClaimed;
        /** @dev YieldBox Owner */
        address owner;
        /** @dev YieldBox Token ID */
        uint256 id;
        /** @dev Time of Creation */
        uint256 createdAt;
    }
    /**@dev Mapping of YieldBox by Token Id*/
    mapping(uint256 => YieldBoxStruct) public yieldBox;
    /**@dev Mapping of ERC20 tokens used to pay for YieldBoxes */
    mapping(address => uint256[5]) public priceInToken;
    /** @dev Mapping of YieldBoxes minted by an address */
    mapping(address => uint256) public totalMinted;
    /** @dev Mapping Presale Claimer of YieldBox */
    mapping(address => bool) public presaleClaimer;
    /** @dev Mapping Presale Claimer of YieldBox */
    mapping(address => uint256) public amountPresaleClaimer;
    // Batch size for claimer
    uint256 public batchSize;
    /**
     * @dev Event when creating YieldBox
     * @param owner of the YieldBox
     * @param id ID of the YieldBox
     * @param createdAt YieldBox creation timestamp
     */
    event YieldBoxCreated(
        address indexed owner,
        uint256 indexed id,
        uint256 createdAt
    );
    /**
     * @dev Event when setting the BASE URI
     * @param baseURI new value of the Base URI
     */
    event SetBaseURI(string baseURI);
    /**
     * @dev Event when setting the cost per token
     * @param tokenAddress address or ERC20 Token
     * @param costPerToken new value of the cost per ERC20 Token
     */
    event SetCostPerToken(address tokenAddress, uint256[5] costPerToken);
    /**
     * @dev Event when setting the ValiFi ERC20 Token address
     * @param tokenAddress new value of ValiFi ERC20 Token address
     */
    event SetTokenAddress(address tokenAddress);
    /**
     * @dev Event when setting the config addresses used by the YieldBox Smart Contract
     * @param configAddresses new value of config addresses used by the YieldBox Smart Contract
     */
    event SetConfigAddresses(address[4] configAddresses);

    /// Total Supply of the YieldBox has raised to the maximum possible amount
    error TotalSupplyRaised();

    /**
     * @dev Inizialize the contract with the owner address.
     */
    function initialize(
        string memory _baseTokenURI,
        address[14] memory _configAddresses
    ) public initializer {
        __ERC721_init("YieldBox", "YBOX");
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        BASE_URI = _baseTokenURI;
        tokenAddress = _configAddresses[0];
        usdAddress = _configAddresses[1];
        // Contract interface instances
        ValiFiNFTv3 = IYieldKey(_configAddresses[2]);
        YieldKey = IYieldKey(_configAddresses[3]);
        LegYieldKey = IStakedYieldKey(_configAddresses[4]);
        RegYieldKey = IStakedYieldKey(_configAddresses[5]);
        Presale1 = IPresale(_configAddresses[6]);
        Presale2 = IPresale(_configAddresses[7]);
        Presale3 = IPresaleRefund(_configAddresses[8]);
        router = IRouter(_configAddresses[9]);
        // Ecosystem (config) wallets
        liquidity = _configAddresses[10];
        rewards = _configAddresses[11];
        treasuryAddress = _configAddresses[12];
        payrollFund = _configAddresses[13];
        Sval = 500;
        Vval = 500;
    }

    modifier claimer(address _claimer) {
        if (
            presaleClaimer[_claimer] ||
            (Presale2.getYieldBoxAllocated(_claimer) == 0 &&
                Presale3.getRepurchaseYieldBoxAllocated(_claimer) == 0)
        ) {
            revert("ERC721 ValiFi: You are not elegible to claim YieldBoxes");
        }
        _;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC721.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC721Pausable}.
     */
    function pause(bool status) public onlyOwner {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev claim the YieldBoxes purchased by the user during the Presale Events
     * @param _claimer address of the user that purchased
     */
    function claimPresaleYieldBox(address _claimer)
        external
        validAddress(_claimer)
        claimer(_claimer)
        whenNotPaused
    {
        require(_claimer == _msgSender(), "Sender is not the claimer");
        if (amountPresaleClaimer[_claimer] == 0) {
            amountPresaleClaimer[_claimer] =
                Presale2.getYieldBoxAllocated(_claimer) +
                Presale3.getRepurchaseYieldBoxAllocated(_claimer);
        }
        uint256 supply = totalSupply() + 1;
        uint256 index = amountPresaleClaimer[_claimer] > batchSize
            ? batchSize
            : amountPresaleClaimer[_claimer];
        for (uint256 i = 0; i < index; i++) {
            super._safeMint(_msgSender(), supply + i);
            /**
             * @dev Store the YieldBox details
             */
            YieldBoxStruct memory _yieldBox = YieldBoxStruct(
                true,
                false,
                uint64(block.timestamp),
                _msgSender(),
                supply + i,
                block.timestamp
            );
            yieldBox[supply + i] = _yieldBox;
            totalMinted[_msgSender()] += 1;
            emit YieldBoxCreated(_msgSender(), supply + i, _yieldBox.createdAt);
        }
        amountPresaleClaimer[_claimer] -= index;
        if (amountPresaleClaimer[_claimer] == 0) {
            Presale1.claimYieldBox(_claimer);
            Presale2.claimYieldBox(_claimer);
            Presale3.claimYieldBox(_claimer);
            presaleClaimer[_claimer] = true;
        }
    }

    /**
     * @dev Create a new token to represent the YieldBox, and store all related details in struct
     * @param _currency The address of the stable token used to purchase the YieldBox
     */
    function create(address _wallet, address _currency)
        external
        nonReentrant
        whenNotPaused
    {
        if (TOTAL_SUPPLY < totalSupply().add(uint256(1)))
            revert TotalSupplyRaised();
        require(
            isValidToken(_currency),
            "ERC721 ValiFi: Token currency not valid"
        );

        IERC20Upgradeable _currency2 = IERC20Upgradeable(_currency);
        uint256 _stableamount = mulDiv(Sval, getVaLiFiPriceinStable(), 100);
        uint256 _valifiAmount = mulDiv(Vval, 1 ether, 100);
        require(
            _currency2.balanceOf(_msgSender()) >= _stableamount,
            "ERC721 ValiFi: Insufficient funds"
        );
        // Transfer the stable coin to create the YieldBox
        bool success = _currency2.transferFrom(
            _msgSender(),
            treasuryAddress,
            mulDiv(priceInToken[_currency][0], _stableamount, 100)
        );
        require(
            success,
            "ERC721 ValiFi: Can't create YieldBox, funds transfer failed (1)"
        );
        success = _currency2.transferFrom(
            _msgSender(),
            liquidity,
            mulDiv(priceInToken[_currency][1], _stableamount, 100)
        );
        require(
            success,
            "ERC721 ValiFi: Can't create YieldBox, funds transfer failed (2)"
        );

        IERC20Upgradeable _token = IERC20Upgradeable(tokenAddress);
        // Transfer the ValiFi Token to create the YieldBox
        require(
            _token.balanceOf(_msgSender()) >= _valifiAmount,
            "ERC721 ValiFi: Insufficient ValiFi token funds"
        );
        success = _token.transferFrom(
            _msgSender(),
            rewards,
            mulDiv(priceInToken[_currency][2], _valifiAmount, 100)
        );
        require(
            success,
            "ERC721 ValiFi: Can't create YieldBox, funds transfer failed (3)"
        );
        success = _token.transferFrom(
            _msgSender(),
            liquidity,
            mulDiv(priceInToken[_currency][3], _valifiAmount, 100)
        );
        require(
            success,
            "ERC721 ValiFi: Can't create YieldBox, funds transfer failed (4)"
        );
        success = _token.transferFrom(
            _msgSender(),
            payrollFund,
            mulDiv(priceInToken[_currency][4], _valifiAmount, 100)
        );
        require(
            success,
            "ERC721 ValiFi: Can't create YieldBox, funds transfer failed (5)"
        );
        uint256 supply = totalSupply() + 1; // start at token Id 1

        /** @dev Mint YieldBox NFT*/

        super._safeMint(_wallet, supply);
        /**
         * @dev Store the YieldBox details
         */
        YieldBoxStruct memory _yieldBox = YieldBoxStruct(
            true,
            false,
            uint64(block.timestamp),
            _wallet,
            supply,
            block.timestamp
        );
        yieldBox[supply] = _yieldBox;
        totalMinted[_wallet] += 1;
        emit YieldBoxCreated(_wallet, supply, _yieldBox.createdAt);
    }

    /**
     * @dev Helpers Funtions.
     */

    /**
     * @dev Verify if a token address is valid to create YieldBoxes.
     * @param _token Token address of currency used to create YieldBoxes
     * @return Status true if value is more than 0, or false if value is 0
     */
    function isValidToken(address _token) public view returns (bool) {
        return priceInToken[_token][0] > 0;
    }

    /**
     * @dev Allows to set the Token Base URI.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        BASE_URI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    /**
     * @dev Allows to set the USD-pegged stable currency and ValiFi token values to create YieldBoxes
     * @param _token Token Address of stable coin in the Avalanche Network used to create a YieldBoxes
     * @param _value Value in currency and ValiFi Token to create YieldBoxes
     * @param _Sval Weighted percentage value of USD-pegged stable currency used to create YieldBoxes
     * @param _Vval Weighted percentage value of ValiFi Token used to create YieldBoxes
     */
    function setTokenValue(
        address _token,
        uint256[5] memory _value,
        uint256 _Sval,
        uint256 _Vval,
        uint256 _constant
    ) external onlyOwner {
        require(
            _value[0] >= 0 && // Weighted percentage value, for treasury wallet in stable coin
                _value[1] >= 0 && // Weighted percentage value, for liquidity wallet in stable coin
                _value[2] >= 0 && // Weighted percentage value, for rewards wallet in ValiFi coin
                _value[3] >= 0 && // Weighted percentage value, for liquidity wallet in ValiFi token
                _value[4] >= 0 && // Weighted percentage value, for payroll wallet in ValiFi token
                _value[0] + _value[1] <= 100 && // Sum of all values in stable coin must be equal or less than 100
                _value[2] + _value[3] + _value[4] <= 100 && // Sum of all values in ValiFi token must be equal or less than 100
                _Sval + _Vval <= 100, // Sum of weighted values of both stable coin and ValiFi token must be equal or less than 100
            "ERC721 ValiFi: Can't set value, value must be greater than 0 and sum of all values of VaLiFi token and stable coin must be less than or equal to 100"
        );
        priceInToken[_token] = _value;
        Sval = _Sval * _constant;
        Vval = _Vval * _constant;
        emit SetCostPerToken(_token, _value);
    }

    /**
     * @dev Allows to get all prices per Token
     * @param _token Token address of stable coin and ValiFi token to create YieldBoxes
     */
    function getTokenValue(address _token)
        external
        view
        returns (uint256[5] memory)
    {
        return priceInToken[_token];
    }

    /**
     * @dev Allows to set the config addresses used in the ecosystem
     * @param _configAddresses Addreses that will receive the funds from YieldBox payments
     */
    function setConfigAddresses(address[4] memory _configAddresses)
        external
        onlyOwner
    {
        // [0] = Liquidity Address, [1] = Rewards Address, [2] = Treasury Address, [3] = Payroll Fund Address
        require(
            _configAddresses[0] != address(0) &&
                _configAddresses[1] != address(0) &&
                _configAddresses[2] != address(0) &&
                _configAddresses[3] != address(0),
            "ERC721 ValiFi: Can't set value, value must be greater than 0"
        );
        liquidity = _configAddresses[0];
        rewards = _configAddresses[1];
        treasuryAddress = _configAddresses[2];
        payrollFund = _configAddresses[3];
        emit SetConfigAddresses(_configAddresses);
    }

    /**
     * @dev Allows to set the ERC20 ValiFi Token address
     * @param _tokenAddress Token Address
     */
    function setTokenAddress(address _tokenAddress)
        external
        validAddress(_tokenAddress)
        onlyOwner
    {
        tokenAddress = _tokenAddress;
        emit SetTokenAddress(_tokenAddress);
    }

    /**
     * @dev Allows to set rewards as claimed
     * @param tokenId Token Id of the YieldBox
     */
    function setRewardClaimed(
        bool status,
        bool dead,
        uint256 tokenId
    ) external onlyRole(ROLE_REWARD_CLAIMER) {
        yieldBox[tokenId].status = status;
        yieldBox[tokenId].dead = dead;
        yieldBox[tokenId].rewardClaimed = uint64(block.timestamp);
    }

    /**
     * @dev Verify if the address is owner of one or several YieldBoxes
     * @param _owner Wallet address of the owner
     * @return tokenIds Array of token Ids of all YieldBoxes owned by the wallet
     */
    function tokenHoldings(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
     * @dev Get Price of ValiFi token in USD-pegged stable coin based on current liquidity pool pair values
     * @return price Price in USD-pegged stable coin
     */

    function getVaLiFiPriceinStable() public view returns (uint256 price) {
        address[] memory path = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        path[0] = address(tokenAddress);
        path[1] = address(usdAddress);
        amounts = router.getAmountsOut((1 * 10**18), path);

        price = amounts[1];
    }

    function setRouterAddress(address _address) external onlyOwner {
        router = IRouter(_address);
    }

    /**
     * @dev Get active YieldBoxes owned by a wallet address
     * @param _wallet Wallet address of the owner
     * @return rewardedTokenIds Array of token Ids of active YieldBoxes owned by the wallet
     */
    function activeYieldBoxes(address _wallet)
        public
        view
        returns (uint256[] memory rewardedTokenIds)
    {
        uint256 index;
        uint256[] memory _tokenIds = tokenHoldings(_wallet);
        if (_tokenIds.length == 0) {
            return rewardedTokenIds;
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (!yieldBox[_tokenIds[i]].dead) {
                index++;
            }
        }
        if (index == 0) {
            return rewardedTokenIds;
        }
        rewardedTokenIds = new uint256[](index);
        index = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (!yieldBox[_tokenIds[i]].dead) {
                rewardedTokenIds[index] = _tokenIds[i];
                index++;
            }
        }
    }

    /**
     * @dev Get total active YieldBoxes
     * @return index Total YieldBoxes currently alive
     */
    function getTotalActiveYieldBoxes() public view returns (uint256 index) {
        for (uint256 i = 1; i < totalSupply() + 1; i++) {
            if (!yieldBox[i].dead) {
                index++;
            }
        }
    }

    /**
     * @dev Get Sval and Vval for Create YieldBox
     */
    function getSvalVval() public view returns (uint256 sval, uint256 vval) {
        return (Sval, Vval);
    }

    /**
     * @dev Allows to set the batch size (to process YieldBox claims per transaction)
     * @param _amount amount of YieldBoxes to claim per transaction
     */
    function setBatchSize(uint256 _amount) external onlyOwner {
        batchSize = _amount;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override notBlacklisted(from) {
        require(!paused(), "ERC721 ValiFi: can't create YieldBox while paused");
        require(
            !isBlacklisted(to),
            "ERC721 ValiFi: can't transfer to blacklisted address"
        );
        if (from != owner()) {
            require(
                from == address(0),
                "ERC721 ValiFi: Can't transfer from a non-owner address"
            );
        }
        //Store the new owner of the YieldBox in struct
        yieldBox[tokenId].owner = to;

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./Blacklistable.sol";

/**
 * @title Claimable Methods
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 * @custom:a Alfredo Lopez / Marketingcycle / ValiFI
 */
contract Claimable is OwnableUpgradeable, Blacklistable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // Event when the Smart Contract receive Amount of Native or ERC20 tokens
    /**
     * @dev Event when the Smart Contract receive Amount of Native or ERC20 tokens
     * @param sender The address of the sender
     * @param value The amount of tokens
     */
    event ValueReceived(address indexed sender, uint256 indexed value);
    /**
     * @dev Event when the Smart Contract Send Amount of Native or ERC20 tokens
     * @param receiver The address of the receiver
     * @param value The amount of tokens
     */
    event ValueSent(address indexed receiver, uint256 indexed value);

    /// @notice Handle receive ether
    receive() external payable {
        emit ValueReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to)
        public
        validAddress(_to)
        notBlacklisted(_to)
        onlyOwner
    {
        if (_token == address(0)) {
            _claimNativeCoins(_to);
        } else {
            _claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function _claimNativeCoins(address _to) private {
        uint256 amount = address(this).balance;

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = _to.call{value: amount}("");
        require(
            success,
            "ERC20: Address: unable to send value, recipient may have reverted"
        );
        // Event when the Smart Contract Send Amount of Native or ERC20 tokens
        emit ValueSent(_to, amount);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function _claimErc20Tokens(address _token, address _to) private {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC721 contract from this contract.
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc721Tokens(address _token, address _to)
        public
        validAddress(_to)
        notBlacklisted(_to)
        onlyOwner
    {
        IERC721Upgradeable token = IERC721Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(address(this), _to, balance);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC721 contract from this contract.
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc1155Tokens(
        address _token,
        address _to,
        uint256 _id
    ) public validAddress(_to) notBlacklisted(_to) onlyOwner {
        IERC1155Upgradeable token = IERC1155Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this), _id);
        bytes memory data = "0x00";
        token.safeTransferFrom(address(this), _to, _id, balance, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./InterfacesVaLiFi.sol";
import "./Claimable.sol";
import "./Math.sol";

contract VaLiFiHelpers is Initializable, OwnableUpgradeable, Claimable, Math {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Instance of the Smart Contract
    IYieldKey private YieldKey;
    IYieldBox private YieldBox;
    IStakedYieldKey private StakedYieldKeyLeg;
    IStakedYieldKey private StakedYieldKeyReg;
    IMaintFee private MaintFee;
    IRewards private Rewards;

    // The User `_wallet` don't have enough rewards (`_amountOdRewards`) pending to claim and create a new YieldBox
    error EnoughRewardsForCompound(address _wallet, uint256 _amountOdRewards);

    function initialize(
        address _yieldKey,
        address _yieldBox,
        address _stakedYieldKeyLeg,
        address _stakedYieldKeyReg
    ) public initializer {
        __Ownable_init();
        YieldKey = IYieldKey(_yieldKey);
        YieldBox = IYieldBox(_yieldBox);
        StakedYieldKeyLeg = IStakedYieldKey(_stakedYieldKeyLeg);
        StakedYieldKeyReg = IStakedYieldKey(_stakedYieldKeyReg);
    }

    /**
     * @dev Get total rewards taking into account YieldBoxes with and without associated YieldKeys
     * @param wallet Wallet of YieldBox/YieldKey holder
     */
    function TotalRewards(address wallet)
        public
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _rewarded,
            uint256[] memory _yieldBoxRewarded,
            uint256[] memory _yieldKey,
            uint256 _time
        )
    {
        uint256[] memory YieldKeyLeg = StakedYieldKeyLeg.tokenStaking(wallet);
        uint256[] memory YieldKeyReg = StakedYieldKeyReg.tokenStaking(wallet);
        if (!((YieldKeyLeg.length == 0) && (YieldKeyReg.length == 0))) {
            uint256 index = getIndexTotalRewards(wallet);
            _amount = new uint256[](index);
            _rewarded = new uint256[](index);
            _yieldBoxRewarded = new uint256[](index);
            _yieldKey = new uint256[](index);
            index = 0;
            uint256[] memory amount2;
            uint256[] memory rewarded2;
            uint256[] memory YieldBoxRewarded2;
            uint256 time2;
            for (uint256 i = 0; i < YieldKeyLeg.length; i++) {
                if (MaintFee.yieldBoxYieldKeyLeg(YieldKeyLeg[i]).length > 0) {
                    (amount2, rewarded2, YieldBoxRewarded2, time2) = Rewards
                        .preRewardPerYK(wallet, YieldKeyLeg[i], 12);
                    for (uint256 j = 0; j < amount2.length; j++) {
                        _amount[index] = amount2[j];
                        _rewarded[index] = rewarded2[j];
                        _yieldBoxRewarded[index] = YieldBoxRewarded2[j];
                        _yieldKey[index] = YieldKeyLeg[i];
                        index++;
                    }
                }
            }
            for (uint256 i = 0; i < YieldKeyReg.length; i++) {
                if (MaintFee.yieldBoxYieldKeyReg(YieldKeyReg[i]).length > 0) {
                    (amount2, rewarded2, YieldBoxRewarded2, time2) = Rewards
                        .preRewardPerYK(
                            wallet,
                            YieldKeyReg[i],
                            uint8(YieldKey.capacityAmount(YieldKeyReg[i]))
                        );
                    for (uint256 j = 0; j < amount2.length; j++) {
                        _amount[index] = amount2[j];
                        _rewarded[index] = rewarded2[j];
                        _yieldBoxRewarded[index] = YieldBoxRewarded2[j];
                        _yieldKey[index] = YieldKeyReg[i];
                        index++;
                    }
                }
            }
            uint256[]
                memory YieldBoxMinimalRewards = getYieldBoxWithoutYieldKey(
                    wallet
                );
            (amount2, rewarded2, YieldBoxRewarded2, time2) = Rewards
                .preMinimalRewards(wallet, YieldBoxMinimalRewards);
            for (uint256 i = 0; i < amount2.length; i++) {
                _amount[index] = amount2[i];
                _rewarded[index] = rewarded2[i];
                _yieldBoxRewarded[index] = YieldBoxRewarded2[i];
                _yieldKey[index] = 0;
                index++;
            }
            _time = time2;
            return (_amount, _rewarded, _yieldBoxRewarded, _yieldKey, _time);
        }
    }

    /**
     * @dev Get YieldBoxes pending to be claimed, with and without associated YieldKeys
     * @param wallet Wallet of YieldBox/YieldKey holder
     */
    function getIndexTotalRewards(address wallet)
        internal
        view
        returns (uint256 index)
    {
        uint256[] memory YieldKeyLeg = StakedYieldKeyLeg.tokenStaking(wallet);
        uint256[] memory YieldKeyReg = StakedYieldKeyReg.tokenStaking(wallet);
        if (!((YieldKeyLeg.length == 0) && (YieldKeyReg.length == 0))) {
            if (YieldKeyLeg.length > 0) {
                for (uint256 i = 0; i < YieldKeyLeg.length; i++) {
                    if (
                        MaintFee.yieldBoxYieldKeyLeg(YieldKeyLeg[i]).length > 0
                    ) {
                        index += MaintFee
                            .yieldBoxYieldKeyLeg(YieldKeyLeg[i])
                            .length;
                    }
                }
            }
            if (YieldKeyReg.length > 0) {
                for (uint256 i = 0; i < YieldKeyReg.length; i++) {
                    if (
                        MaintFee.yieldBoxYieldKeyReg(YieldKeyReg[i]).length > 0
                    ) {
                        index += MaintFee
                            .yieldBoxYieldKeyReg(YieldKeyReg[i])
                            .length;
                    }
                }
            }
            uint256[]
                memory YieldBoxMinimalRewards = getYieldBoxWithoutYieldKey(
                    wallet
                );
            (uint256[] memory amount2, , , ) = Rewards.preMinimalRewards(
                wallet,
                YieldBoxMinimalRewards
            );
            for (uint256 i = 0; i < amount2.length; i++) {
                index++;
            }
        }
    }

    /**
     * @dev Checks if the YieldKey is staked by its owner
     * @param _wallet Wallet of YieldKey holder
     * @param _yieldKey YieldKey Token Id
     * @param _type YieldKey type
     * @return Status true if the owner has YieldKey in staking, or false if the YieldKey is not in staking
     */
    function OwnerIsStaked(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    ) external view returns (bool) {
        if (_type == 12) {
            uint256[] memory stakedYKL = StakedYieldKeyLeg.tokenStaking(
                _wallet
            );
            for (uint256 i = 0; i < stakedYKL.length; i++) {
                if (stakedYKL[i] == _yieldKey) {
                    return true;
                }
            }
        } else if (_type == 8 || _type == 6 || _type == 4) {
            uint256[] memory stakedYKR = StakedYieldKeyReg.tokenStaking(
                _wallet
            );
            for (uint256 i = 0; i < stakedYKR.length; i++) {
                if (stakedYKR[i] == _yieldKey) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @dev get array of YieldBoxes without associated YieldKeys
     * @param _walletAddress Wallet of YieldBox holder
     */
    function getYieldBoxWithoutYieldKey(address _walletAddress)
        public
        view
        returns (uint256[] memory yieldBoxWithoutYieldKey)
    {
        uint256[] memory _tokenIds = YieldBox.activeYieldBoxes(_walletAddress);
        uint256 index;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (
                (MaintFee.maintFee(_tokenIds[i]).yieldKey == 0) &&
                (MaintFee.maintFee(_tokenIds[i]).yieldKeyType == 0) &&
                (MaintFee.maintFee(_tokenIds[i]).status == false)
            ) {
                index++;
            }
        }
        yieldBoxWithoutYieldKey = new uint256[](index);
        index = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (
                (MaintFee.maintFee(_tokenIds[i]).yieldKey == 0) &&
                (MaintFee.maintFee(_tokenIds[i]).yieldKeyType == 0) &&
                (MaintFee.maintFee(_tokenIds[i]).status == false)
            ) {
                yieldBoxWithoutYieldKey[index] = _tokenIds[i];
                index++;
            }
        }
    }

    /**
     * @dev Retrieve the amount of YieldBoxes actually attached to the YieldKey
     * @param _yieldKey YieldKey Token Id
     * @param _type YieldKey type
     * @param _tokenIds Array of YieldBox Token Ids
     * @return attachYB Amount of YieldBoxes actually attached to the YieldKey
     */
    function getYieldBoxAttached(
        uint256 _yieldKey,
        uint8 _type,
        uint256[] memory _tokenIds
    ) public view returns (uint256 attachYB) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_type == 12) {
                if (
                    isYieldBoxInArray(
                        _tokenIds[i],
                        MaintFee.yieldBoxYieldKeyLeg(_yieldKey)
                    )
                ) {
                    attachYB++;
                }
            } else if (_type == 8 || _type == 6 || _type == 4) {
                if (
                    isYieldBoxInArray(
                        _tokenIds[i],
                        MaintFee.yieldBoxYieldKeyReg(_yieldKey)
                    )
                ) {
                    attachYB++;
                }
            }
        }
    }

    /**
     * @dev Validate if the YieldBox exists in the array of Legendary or Regular YieldKeys
     * @param _tokenId Token Id of Yield Box
     * @param _yieldKeyArray Array of YieldKey
     */
    function isYieldBoxInArray(
        uint256 _tokenId,
        uint256[] memory _yieldKeyArray
    ) public pure returns (bool) {
        for (uint256 i = 0; i < _yieldKeyArray.length; i++) {
            if (_yieldKeyArray[i] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Retrieve the available slots per YieldKey
     * @param _yieldKey YieldKey Token Id
     * @param _type YieldKey type
     * @return result Available Slots available per YieldKey
     */
    function getAvailableSlots(uint256 _yieldKey, uint8 _type)
        public
        view
        returns (uint256)
    {
        if (_type == 12) {
            return
                12 > MaintFee.yieldBoxYieldKeyLeg(_yieldKey).length
                    ? 12 - MaintFee.yieldBoxYieldKeyLeg(_yieldKey).length
                    : 0;
        } else if (_type == 8 || _type == 6 || _type == 4) {
            return
                _type > MaintFee.yieldBoxYieldKeyReg(_yieldKey).length
                    ? _type - MaintFee.yieldBoxYieldKeyReg(_yieldKey).length
                    : 0;
        }
    }

    /**
     * @dev Get the total days to pay for all YieldBoxes of the owner
     * @param _tokenIds Token Ids of YieldBox
     * @param _paidDays Days to pay for all YieldBoxes of the owner
     */
    function getTotalDays(
        uint256[] calldata _tokenIds,
        uint256[] calldata _paidDays
    ) public pure returns (uint256 totalDays) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            totalDays += _paidDays[i];
        }
    }

    function getCompoundAmount(address _wallet, uint256 _compoundAmount)
        public
        view
        returns (uint256)
    {
        (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256[] memory yieldKey,

        ) = TotalRewards(_wallet);
        uint256 totalAmount;
        for (uint256 i = 0; i < amount.length; i++) {
            totalAmount += amount[i];
        }
        totalAmount = _compoundAmount;
        for (uint256 i = 0; i < amount.length; i++) {
            if ((YieldBoxRewarded[i] != 0) && (yieldKey[i] != 0)) {
                if (rewarded[i].mul(Rewards.REWARDS_PER_DAYS()) > totalAmount) {
                    for (uint256 j = 0; j < rewarded[i]; j++) {
                        if (j.mul(Rewards.REWARDS_PER_DAYS()) > totalAmount) {
                            return
                                _compoundAmount.add(
                                    j.mul(Rewards.REWARDS_PER_DAYS()).sub(
                                        totalAmount
                                    )
                                );
                        } else {
                            totalAmount -= j.mul(Rewards.REWARDS_PER_DAYS());
                        }
                    }
                } else {
                    totalAmount -= rewarded[i].mul(Rewards.REWARDS_PER_DAYS());
                }
            } else {
                if (
                    rewarded[i].mul(Rewards.MINIMAL_REWARDS_DAYS()) >
                    totalAmount
                ) {
                    for (uint256 j = 0; j < rewarded[i]; j++) {
                        if (
                            j.mul(Rewards.MINIMAL_REWARDS_DAYS()) > totalAmount
                        ) {
                            return
                                _compoundAmount.add(
                                    j.mul(Rewards.MINIMAL_REWARDS_DAYS()).sub(
                                        totalAmount
                                    )
                                );
                        } else {
                            totalAmount -= j.mul(
                                Rewards.MINIMAL_REWARDS_DAYS()
                            );
                        }
                    }
                } else {
                    totalAmount -= rewarded[i].mul(
                        Rewards.MINIMAL_REWARDS_DAYS()
                    );
                }
            }
        }
    }

    function CompoundOfRewardsParameters(address _wallet)
        public
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        (uint256[] memory amount, , , , ) = TotalRewards(_wallet);
        uint256 totalAmount;
        for (uint256 i = 0; i < amount.length; i++) {
            totalAmount += amount[i];
        }
		if (totalAmount == 0) {
			return (false, 0, 0);
		}
        (uint256 Sval, uint256 Vval) = YieldBox.getSvalVval();
        uint256 totalVaLI = mulDiv(Sval.add(Vval), 1 ether, 100);
        uint256 estimateCompoundAmount = totalVaLI.add(
            mulDiv(totalVaLI, Rewards.ADD_PERCENTAGE_FOR_COMPOUND(), 100)
        ); // Add 10% over the price in USDC
        uint256 compoundAmount = getCompoundAmount(
            _wallet,
            estimateCompoundAmount
        );
        return (totalAmount > compoundAmount, totalAmount, compoundAmount);
    }

    /**
     * @dev Calculate Pre-reward per YieldKey
     * @param _wallet Wallet of YieldKey holder
     * @param _yieldKey YieldKey of YieldBox
     * @param _type Type of YieldKey
     */
    function calculateRewardPerYK(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    )
        public
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        )
    {
        time = block.timestamp;
        uint64[] memory startstake;
        uint64[] memory endstake;
        if (_type == 12) {
            YieldBoxRewarded = new uint256[](
                MaintFee.yieldBoxYieldKeyLeg(_yieldKey).length
            );
            YieldBoxRewarded = MaintFee.yieldBoxYieldKeyLeg(_yieldKey);
            (startstake, endstake) = StakedYieldKeyLeg.getStakedYieldKeyHistory(
                _wallet,
                _yieldKey
            );
        } else if (_type == 8 || _type == 6 || _type == 4) {
            YieldBoxRewarded = new uint256[](
                MaintFee.yieldBoxYieldKeyReg(_yieldKey).length
            );
            YieldBoxRewarded = MaintFee.yieldBoxYieldKeyReg(_yieldKey);
            (startstake, endstake) = StakedYieldKeyReg.getStakedYieldKeyHistory(
                _wallet,
                _yieldKey
            );
        }
        rewarded = new uint256[](YieldBoxRewarded.length);
        amount = new uint256[](YieldBoxRewarded.length);
        for (uint256 i = 0; i < YieldBoxRewarded.length; i++) {
            rewarded[i] += getRewardsDays(
                startstake,
                endstake,
                YieldBoxRewarded[i],
                uint64(time)
            );
            amount[i] += rewarded[i] * Rewards.REWARDS_PER_DAYS();
        }
    }

    /**
     * @dev Calculate Pre-minimal rewards per YieldBox
     * @param wallet Wallet of owner of YieldBox
     * @param YieldBoxIds Array of YieldBox Ids
     */
    function calculateMinimalRewards(
        address wallet,
        uint256[] memory YieldBoxIds
    )
        public
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        )
    {
        rewarded = new uint256[](YieldBoxIds.length);
        amount = new uint256[](YieldBoxIds.length);
        YieldBoxRewarded = new uint256[](YieldBoxIds.length);
        time = block.timestamp;
        for (uint256 i = 0; i < YieldBoxIds.length; i++) {
            require(
                MaintFee.maintFee(YieldBoxIds[i]).yieldKey == 0 &&
                    MaintFee.maintFee(YieldBoxIds[i]).yieldKey == 0,
                "At least one YieldBox has an associated YieldKey"
            );
            require(
                YieldBox.yieldBox(YieldBoxIds[i]).status,
                "At least one of the YieldBoxes is already expired or does not exist"
            );
            require(
                YieldBox.ownerOf(YieldBoxIds[i]) == wallet,
                "Wallet is not owner of the YieldBox"
            );
            YieldBoxRewarded[i] = YieldBoxIds[i];
            if (
                (MaintFee.maintFee(YieldBoxIds[i]).unClaimedDays > 0) ||
                (Rewards.RewardsClaimed(YieldBoxIds[i]).claimedDays > 0)
            ) {
                rewarded[i] = 0;
                amount[i] = 0;
            } else if (
                (
                    ((time - YieldBox.yieldBox(YieldBoxIds[i]).createdAt) <=
                        Rewards.MINIMAL_REWARDS_DAYS())
                ) &&
                ((
                    (time - YieldBox.yieldBox(YieldBoxIds[i]).createdAt).div(
                        1 minutes
                    )
                ) > Rewards.RewardsClaimed(YieldBoxIds[i]).freeDaysClaimed)
            ) {
                rewarded[i] =
                    (
                        (time - YieldBox.yieldBox(YieldBoxIds[i]).createdAt)
                            .div(1 minutes)
                    ) -
                    Rewards.RewardsClaimed(YieldBoxIds[i]).freeDaysClaimed;
                amount[i] = mulDiv(
                    rewarded[i],
                    Rewards.REWARDS_PER_DAYS(),
                    Rewards.MINIMAL_REWARDS()
                );
            } else if (
                (time - YieldBox.yieldBox(YieldBoxIds[i]).createdAt) >
                Rewards.MINIMAL_REWARDS_DAYS()
            ) {
                rewarded[i] = (Rewards.MINIMAL_REWARDS_DAYS().div(1 minutes)) >
                    Rewards.RewardsClaimed(YieldBoxIds[i]).freeDaysClaimed
                    ? (Rewards.MINIMAL_REWARDS_DAYS().div(1 minutes)) -
                        Rewards.RewardsClaimed(YieldBoxIds[i]).freeDaysClaimed
                    : 0;
                amount[i] = mulDiv(
                    rewarded[i],
                    Rewards.REWARDS_PER_DAYS(),
                    Rewards.MINIMAL_REWARDS()
                );
            }
        }
    }

    /**
     * @dev Allows to get the total days available to claim rewards
     * @dev based on the amount of YieldKeys (Regular or Legendary) staked by the caller
     * @param startStaked Start timestamp of YieldKey staking
     * @param endStaked End timestamp of YieldKey staking
     * @param YieldBoxIds YieldBox Ids
     * @return rewardDays Total days of rewards available to be claimed
     */
    function getRewardsDays(
        uint64[] memory startStaked,
        uint64[] memory endStaked,
        uint256 YieldBoxIds,
        uint64 time
    ) public view returns (uint256 rewardDays) {
        if (
            (MaintFee.maintFee(YieldBoxIds).unClaimedDays.mul(1440)) <=
            Rewards.RewardsClaimed(YieldBoxIds).claimedDays ||
            (startStaked.length == 0) ||
            (YieldBox.yieldBox(YieldBoxIds).dead)
        ) {
            return rewardDays;
        }
        endStaked[endStaked.length - 1] = endStaked[endStaked.length - 1] ==
            uint64(0)
            ? uint64(time)
            : endStaked[endStaked.length - 1];
        uint256 stakedDays = getStakedDays(startStaked, endStaked, YieldBoxIds);
        rewardDays = stakedDays >
            (MaintFee.maintFee(YieldBoxIds).unClaimedDays.mul(1440) -
                Rewards.RewardsClaimed(YieldBoxIds).claimedDays)
            ? (
                MaintFee.maintFee(YieldBoxIds).unClaimedDays.mul(1440) >
                    Rewards.RewardsClaimed(YieldBoxIds).claimedDays
                    ? (MaintFee.maintFee(YieldBoxIds).unClaimedDays.mul(1440) -
                        Rewards.RewardsClaimed(YieldBoxIds).claimedDays)
                    : 0
            )
            : stakedDays;
    }

    /**
     * @dev Allows to get the total days the YieldKey has been staked
     * @dev based on the amount of YieldKeys (Regular or Legendary) staked by the caller
     * @param startStaked Start timestamp of YieldKey staking
     * @param endStaked End timestamp of YieldKey staking
     * @return amountDays Total days staked
     */
    function getStakedDays(
        uint64[] memory startStaked,
        uint64[] memory endStaked,
        uint256 YieldBoxIds
    ) public view returns (uint256 amountDays) {
        uint64 value = YieldBox.yieldBox(YieldBoxIds).rewardClaimed >
            MaintFee.maintFee(YieldBoxIds).firstDay
            ? YieldBox.yieldBox(YieldBoxIds).rewardClaimed
            : MaintFee.maintFee(YieldBoxIds).firstDay;
        for (uint256 i = 0; i < startStaked.length; i++) {
            if ((value < startStaked[i]) && (value < endStaked[i])) {
                amountDays += (endStaked[i] - startStaked[i]).div(1 minutes);
            } else if ((value >= startStaked[i]) && (value < endStaked[i])) {
                amountDays += (endStaked[i] - value).div(1 minutes);
            }
        }
    }

    /**
     * @dev Set Maintenance Fee Smart Contract
     * @param _maintFee address of the Maintenance Fee Smart Contract
     */
    function setMaintFee(address _maintFee) external onlyOwner {
        MaintFee = IMaintFee(_maintFee);
    }

    /**
     * @dev Set Rewards smart contract address
     * @param _rewards address of the Rewards smart contract
     */
    function setRewardsContract(address _rewards) external onlyOwner {
        Rewards = IRewards(_rewards);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/**
 * @title Math Library
 * @dev Allows handle 512-bit multiply, RoundingUp
 * @custom:a Alfredo Lopez / Marketingcycle / ValiFI
 */
contract Math {
    using SafeMathUpgradeable for uint256;

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = MathUpgradeable.mulDiv(a, b, denominator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Blacklistable Methods
 * @dev Allows accounts to be blacklisted by Owner
 * @custom:a Alfredo Lopez / Marketingcycle / ValiFI
 */
contract Blacklistable is OwnableUpgradeable {
    // Index Address
    address[] private wallets;
    // Mapping blacklisted Address
    mapping(address => bool) private blacklisted;
    // Events when add or drop a wallets in the blacklisted mapping
    event InBlacklisted(address indexed _account);
    event OutBlacklisted(address indexed _account);

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(
            !blacklisted[_account],
            "ERC20 VALIFi: sender account is blacklisted"
        );
        _;
    }

    /**
     * @dev Throws if a given address is equal to address(0)
     * @param _to The address to check
     */
    modifier validAddress(address _to) {
        require(_to != address(0), "ERC20 VALIFi: Not Add Zero Address");
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function addBlacklist(address _account)
        public
        validAddress(_account)
        notBlacklisted(_account)
        onlyOwner
    {
        blacklisted[_account] = true;
        wallets.push(_account);
        emit InBlacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function dropBlacklist(address _account)
        public
        validAddress(_account)
        onlyOwner
    {
        require(isBlacklisted(_account), "ERC20 VALIFi: Wallet don't exist");
        blacklisted[_account] = false;
        emit OutBlacklisted(_account);
    }

    /**
     * @dev Getting the List of Address Blacklisted
     */
    function getBlacklist() public view returns (address[] memory) {
        return wallets;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

// IYieldKey private constant YieldKey =
// 		// IYieldKey(address(0xD3b35ea829C9FF6e2b8506886ea36f0Ac1A30f7e)); // Testnet
// 		IYieldKey(address(0xFEFeDa5DD1ECe04dECE30CEa027177459F4F53DA)); // Local Testnet
// IYieldBox private constant YieldBox =
// 		// IYieldBox(address(0x57f94693Ae1542AEe6373dd38dD545BfaBD2E91e)); // Testnet
// 		IYieldBox(address(0x7598b1dB111726E5487e850340780Aa1321879eB)); // Local Testnet
// IStakedYieldKey private constant StakedYieldKeyLeg =
// 		// IStakedYieldKey(address(0xB9acF127d5Bb7f79e08930Fd1915B3Aa7c476aDd)); // Testnet
// 		IStakedYieldKey(address(0xA317c14B395755f72E98784523688C396d45BFAb)); // Local Testnet
// IStakedYieldKey private constant StakedYieldKeyReg =
// 		// IStakedYieldKey(address(0xD3b35ea829C9FF6e2b8506886ea36f0Ac1A30f7e)); // Testnet
// 		IStakedYieldKey(address(0x8cf902568A347540eB4b5ef734BB105484a5eEd2)); // Local Testnet
// IMaintFee private constant MaintFee =
// 		// IMaintFee(address(0x3975df9b2bda7ece95Ed7ebb809495c9640a7a00)); // Testnet
// 		IMaintFee(address(0x473B87E5Bb1f66F2Fa16687c07E17DF2c75eC452)); // Local Testnet
// IRewards private constant Rewards =
// 		// IRewards(address(0x4C3cc44ba18070d7e631884f11de8737c431554a)); // Testnet
// 		IRewards(address(0x82d5ff68697d0d389c527b5C8D764a6201E096e5)); // Local Testnet

/** @dev Interface of Maintenance Fee */
interface IMaintFee {
    /**
     * @dev Struct of the YieldBox
     */
    struct MainFeeStruct {
        /** @dev Maintenance fee status */
        bool status;
        /** @dev Maintenance fee owner */
        address lastOwner;
        /** @dev First day maintenance fee */
        uint64 firstDay;
        /** @dev Fee due Date */
        uint64 feeDue;
        /** @dev Unclaimed Days */
        uint256 unClaimedDays;
        /** @dev YieldKey Token Id */
        uint256 yieldKey;
        /** @dev Type of YieldKey */
        uint8 yieldKeyType; // Types: 4,6,8 and 12
    }

    /**@dev Maintenance fee details by Token Id */
    function maintFee(uint256 _tokenId)
        external
        view
        returns (MainFeeStruct memory);

    /** @dev get array of YieldBoxes per Legendary YieldKey */
    function yieldBoxYieldKeyLeg(uint256 _yieldKey)
        external
        view
        returns (uint256[] memory);

    /** @dev get array of YieldBoxes per Regular YieldKey */
    function yieldBoxYieldKeyReg(uint256 _yieldKey)
        external
        view
        returns (uint256[] memory);
}

/** @dev Interface of Legendary YieldKey */
interface IValiFiNFT is IERC721Upgradeable {
    function tokenHoldings(address _owner)
        external
        view
        returns (uint256[] memory);
}

interface IStakedYieldKey is IValiFiNFT {
    /**
     * @dev Struct of Staked YieldKeys
     */
    struct StakeYieldKey {
        bool isStaked;
        uint64[] startstake;
        uint64[] endstake;
    }

    function isStaked(address wallet, uint256 _tokenId)
        external
        view
        returns (bool);

    function getStakedYieldKeyHistory(address wallet, uint256 _tokenId)
        external
        view
        returns (uint64[] memory startstake, uint64[] memory endstake);

    function tokenStaking(address _owner)
        external
        view
        returns (uint256[] memory stakeTokenIds);
}

/** @dev Interface of YieldBox */
interface IYieldBox is IValiFiNFT {
    /**
     * @dev Struct of the YieldBox
     */
    struct YieldBoxStruct {
        /** @dev YieldBox Status */
        bool status;
        /** @dev Dead YieldBox Token */
        bool dead;
        /** @dev Time of Last Claim */
        uint64 rewardClaimed;
        /** @dev YieldBox Owner */
        address owner;
        /** @dev YieldBox Token ID */
        uint256 id;
        /** @dev Time of Creation */
        uint256 createdAt;
    }

    function yieldBox(uint256 _tokenIDs)
        external
        view
        returns (YieldBoxStruct memory);

    function activeYieldBoxes(address _wallet)
        external
        view
        returns (uint256[] memory rewardedTokenIds);

    function setRewardClaimed(
        bool status,
        bool dead,
        uint256 tokenId
    ) external;

    function totalSupply() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function usdcAddress() external view returns (address);

    function getVaLiFiPriceinStable() external view returns (uint256 price);

    function getSvalVval() external view returns (uint256 sval, uint256 vval);

    function create(address _wallet, address _token) external;
}

/** @dev Interface of Regular YieldKey */
interface IYieldKey is IValiFiNFT {
    function capacityAmount(uint256 tokenId) external view returns (uint256);
}

/** @dev Interface of Rewards Smart Contract */
interface IRewards {
    struct RewardStruct {
        /** @dev First day maintenance fee */
        uint64 firstDay; // must be change Last Claim
        /** @dev Days of rewards claimed */
        uint256 claimedDays;
        /** @dev Days of minimal rewards (free) claimed */
        uint256 freeDaysClaimed;
    }

    function RewardsClaimed(uint256 _yieldBoxId)
        external
        view
        returns (RewardStruct memory);

    function preRewardPerYK(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    )
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );

    function preMinimalRewards(address wallet, uint256[] memory YieldBoxIds)
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );

    function getTotalRewards(address wallet)
        external
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _rewarded,
            uint256[] memory _yieldBoxRewarded,
            uint256[] memory _yieldKey,
            uint256 time
        );

    function MINIMAL_REWARDS_DAYS() external pure returns (uint256);

    function MINIMAL_REWARDS() external pure returns (uint256);

    function LIMITS_DAYS() external pure returns (uint256);

    function REWARDS_PER_DAYS() external pure returns (uint256);

    function ADD_PERCENTAGE_FOR_COMPOUND() external pure returns (uint256);
}

/** @dev Interface of Router Smart Contract */
interface IRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IVaLiFiHelpers {
    function TotalRewards(address wallet)
        external
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _rewarded,
            uint256[] memory _yieldBoxRewarded,
            uint256[] memory _yieldKey,
            uint256 time
        );

    function OwnerIsStaked(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    ) external view returns (bool);

    /** @dev get array of YieldBoxes without associated YieldKeys */
    function getYieldBoxWithoutYieldKey(address _walletAddress)
        external
        view
        returns (uint256[] memory);

    function getYieldBoxAttached(
        uint256 _yieldKey,
        uint8 _type,
        uint256[] memory _tokenIds
    ) external view returns (uint256 attachYB);

    function isYieldBoxInArray(
        uint256 _tokenId,
        uint256[] memory _yieldKeyArray
    ) external pure returns (bool);

    function getAvailableSlots(uint256 _yieldKey, uint8 _type)
        external
        view
        returns (uint256 result);

    function CompoundOfRewardsParameters(address _wallet)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function calculateMinimalRewards(
        address wallet,
        uint256[] memory YieldBoxIds
    )
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );

    function calculateRewardPerYK(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    )
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );

    function getTotalDays(
        uint256[] calldata _tokenIds,
        uint256[] calldata _paidDays
    ) external pure returns (uint256 totalDays);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}