// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/ISpaceFarmer.sol";
import "./interfaces/IFarm.sol";
import "./interfaces/IBurnableToken.sol";
import "./Seed.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IShop.sol";
import "./interfaces/IFundsManager.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./GNFChecker.sol";
import "./SupplyManager.sol";

contract SpaceFarmer is
  ERC721,
  ERC721Enumerable,
  Ownable,
  Pausable,
  ReentrancyGuard
{
  using Strings for uint256;

  struct Prices {
    uint256 regular;
    uint256 discounted;
    uint256 superMutant;
  }

  Prices private prices;

  address private constant MULTI_SIG_ADDRESS =
    0x430406E3B0F14fe57Ecd1F56593effCf3ab3e548;

  // Number of tokens that can be claimed against AVAX
  uint256 private constant PAID_TOKENS = 11000;

  string public baseURI = "https://charming-antonelli.51-210-190-173.plesk.page/space-farmer/metadata/";

  // By default equal to 0 so Gen0
  MintPhase public mintPhase;

  // reference to the Farm
  IFarm private farm;

  Seed public immutable randomSource;

  IWhitelist private immutable whitelist;

  address private shop;

  GNFChecker private immutable gnfChecker;

  IFundsManager private immutable fundsManager;

  SupplyManager private immutable supplyManager;

  // 0 -> For G&F Holders
  // 1 -> For whitelisted address
  // 2 -> Public sale
  uint256 public mintStep;

  constructor(
    address _whitelist,
    address _gnfChecker,
    address _fundsManager,
    address _supplyManager
  ) ERC721("Space Farmer Game", "SPFA") {
    require(
        _whitelist != address(0) &&
        _fundsManager != address(0) &&
        _gnfChecker != address(0) &&
        _supplyManager != address(0),
      "Invalid address"
    );
    whitelist = IWhitelist(_whitelist);
    randomSource = new Seed();
    fundsManager = IFundsManager(_fundsManager);
    gnfChecker = GNFChecker(_gnfChecker);
    prices = Prices({
      // 1.5 AVAX
      regular: 1500000000000000000,
      // 1 AVAX
      discounted: 1000000000000000000,
      // 2 AVAX
      superMutant: 2000000000000000000
    });
    supplyManager = SupplyManager(_supplyManager);
  }

  /**
    * @dev Trade $SEED for NFTs
    * @param amount Amount of NFTs to trade against $SEED considering
    * that each NFT is 250,000 $SEED
    * @param stake Whether to stake these NFTs directly
   */
  function tradeSeedForMints(uint256 amount, bool stake) external
  {
    address sender = _msgSender();
    // Only available in Gen0
    require(mintPhase == MintPhase.Gen0, "Minting phase over");
    // The hero parameter is not used for Gen0 mints
    _genericMint(amount, stake, Hero.Mutant, sender);
    // Will burn the $SEED traded for these tokens
    gnfChecker.claimTokensForSeed(sender, amount);
  }

  /**
    * @dev Claim free NFTs for each G&F NFTs owned by the sender
    * @param stake Whether to stake these NFTs directly
   */
  function claimFreeMints(bool stake) external {
    address sender = _msgSender();
    // Only available in Gen0
    require(mintPhase == MintPhase.Gen0, "Minting phase over");
    // Get the number of free mints available
    uint256 freeMints = gnfChecker.getAvailableFreeMints(sender, true);
    // Check there are free mints left
    require(freeMints > 0, "No free mints left");
    // Check the max supply for Gen0 hasn't been reached
    require(totalSupply() + freeMints <= PAID_TOKENS, "All tokens minted");
    // The hero parameter is not used for Gen0 mints
    _genericMint(freeMints, stake, Hero.Mutant, sender);
    // Will mark the token as claimed
    gnfChecker.claimTokens(sender);
  }

  /**
    * @dev Main mint function. To be used for the public sale or whitelist mint
    * @param amount Amount of NFTs to mint
    * @param stake Whether to stake the NFTs straightaway or not
   */
  function mint(uint256 amount, bool stake)
    external
    payable
  {
    address sender = _msgSender();
    // Check there is enough supply left
    require(totalSupply() + amount <= PAID_TOKENS, "All tokens minted");
    // Check the mint phase is not Gen1
    require(mintPhase != MintPhase.Gen1, "Minting phase over");
    // Get if the sender is whitelisted
    bool isWhitelisted = whitelist.isWhitelisted(sender);
    // Get if the sender is a holder of G&F tokens
    bool isGNFHolder = gnfChecker.isGNFHolder(sender);
    // Public sale is mint step 2, mint step 1 is for whitelisted address only
    // and mint step 0 is for GNF holders only
    require(mintStep >= 2 || (isWhitelisted && mintStep >= 1) || isGNFHolder, "Mint not open");

    // Get the total price
    uint256 total = getTotalPrice(sender, amount);
    // Check the amount of AVAX given is correct
    require(
      total == msg.value,
      "Invalid payment amount"
    );
    // If whitelisted then we need to update the number of claims
    // made by this address
    if(isWhitelisted) {
      whitelist.addToClaims(sender, amount);
    }
    // If GNF holder we also need to update the number of claims 
    // made by this address
    // Also this can only done during mint step 0
    if(isGNFHolder && mintStep == 0) {
      gnfChecker.claimDiscountedMints(sender, amount);
    }
    // The hero parameter is not used for Gen0 mints
    _genericMint(amount, stake, Hero.Mutant, sender);
  }

  /**
    * @dev Generic mint function callable by the other Space Farmer contract or 
    * the owner of the contract (for giveaways)
    * @param amount Amount of NFTs to mint
    * @param stake Whether to stake these NFTs directly
    * @param hero Which hero to mint (will be ignored before Gen1)
    * @param to Address to which these NFTs will be sent
   */
  function genericMint(    
    uint256 amount,
    bool stake,
    Hero hero,
    address to
  ) 
    external {
    // The owner can mint for free
    require(_msgSender() == owner() || _msgSender() == shop || _msgSender() == address(farm), "Not allowed");
    _genericMint(amount, stake, hero, to);
  }

  function _genericMint(
    uint256 amount,
    bool stake,
    Hero hero,
    address to
  ) private whenNotPaused nonReentrant {
    // Only up to 30 mints per transaction
    require(amount > 0 && amount <= 30, "Invalid mint amount");
    uint256[] memory tokenIds = new uint256[](amount);
    uint256 seed;

    for (uint256 i = 0; i < amount; i++) {
      // Get a random seed
      seed = random(totalSupply());
      randomSource.update(totalSupply() ^ seed);
      // Generate a token id from the seed and according to the rules 
      // of the supply and the mint phase and hero
      uint256 tokenId = supplyManager.generateTokenId(seed, mintPhase, hero);
      // If we stake directly then the recipient is the Farm contract
      // otherwise it's the address to mint to
      address recipient = stake ? address(farm) : to;
      // Mint the token
      _safeMint(recipient, tokenId);
      if (stake) {
        // Keep track of it for below if we stake
        tokenIds[i] = tokenId;
      }
    }

    if (stake) {
      // Stake the tokens if we chose staking
      farm.stakeMany(to, tokenIds);
    }
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    // The Farm contract can transfer any token without prior approval
    return operator == address(farm) || super.isApprovedForAll(owner, operator);
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) private view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
          )
        )
      ) ^ randomSource.seed();
  }

  /***READ */

  function getTotalPrice(address addr, uint256 tokenAmount)
    public
    view
    returns (uint256 total)
  {
    // Get how many tokens can be claimed at whitelist price
    uint256 whitelistClaimable = whitelist.getClaimableDiscounts(addr);
    // Get how many tokens can be claimed at discounted price for G&F holders
    uint256 gnfHolderDiscountBalance = gnfChecker.getAvailableDiscountedMints(
      addr
    );
    // Get the discounted amount
    uint256 discountedAmount = gnfHolderDiscountBalance > 0 && mintStep == 0 ? gnfHolderDiscountBalance : whitelistClaimable;
    // The regular price is different if it's the Super Mutant mint
    if (discountedAmount > 0 && mintPhase == MintPhase.Gen0) {
      // If the discounted amount is greater than the amount requested,
      // then the discounted amount is just the amount requested
      discountedAmount = discountedAmount > tokenAmount ? tokenAmount : discountedAmount;
      // We get the total according to the remaining tokens at the discounted price
      // plus the rest at regular price
      total =
        prices.discounted *
        discountedAmount +
        ((prices.regular * 80) / 100) *
        (tokenAmount - discountedAmount);
    } else if(mintPhase == MintPhase.Gen0SuperMutant) {
      // Special price for the Super Mutant
      total = prices.superMutant  * tokenAmount;
    } else {
      // The first 5 at the regular price and the following is discounted by 20%
      uint256 baseAmount = tokenAmount > 5 ? 5 : tokenAmount;
      uint256 rebateAmount = tokenAmount > 5 ? tokenAmount - baseAmount : 0;
      total = prices.regular * baseAmount + ((prices.regular  * 80) / 100) * rebateAmount;
    }
  }

  /***ADMIN */

  function setFarmAndShop(address _farm, address _shop) external onlyOwner {
    farm = IFarm(_farm);
    shop = _shop;
  }
  /**
   * Allows Multi-Sig or owner to withdraw funds from minting
   */
  function withdraw() external {
    require(_msgSender() == MULTI_SIG_ADDRESS || _msgSender() == owner(), "Not allowed");
    fundsManager.transferFunds{ value: address(this).balance }();
  }

  /**
   * Enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setMintSettings(MintPhase phase, uint256 step) external onlyOwner {
    mintPhase = phase;
    mintStep = step;
  }

  /***RENDER */

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    // Concatenate the baseURI and the tokenId as the tokenId should
    // just be appended at the end to access the token metadata
    return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
  }

  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  function setPrices(Prices memory _prices) external onlyOwner {
    prices = _prices;
  }

  function getSupplyLeft(Hero hero) external view returns(uint256) {
    return supplyManager.getSupplyLeft(mintPhase, hero);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable)  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

// SPDX-License-Identifier: MIT

import "./IShop.sol";

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

enum Hero {
  Mutant,
  SuperMutant,
  SpaceFarmer
}

enum MintPhase {
  Gen0,
  Gen0SuperMutant,
  Gen1
}

interface ISpaceFarmer is IERC721, IERC721Enumerable {
  function mintPhase() external view returns (MintPhase);

  function genericMint(
    uint256 amount,
    bool stake,
    Hero hero,
    address to
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISpaceFarmer.sol";

struct Stake {
  uint256 tokenId;
  uint256 timestamp;
  uint256 juicePerSpaceFarmer;
  address owner;
}

interface IFarm {
  function stakeMany(address account, uint256[] calldata tokenIds) external;

  function farm(uint256)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function totalJuiceEarned() external view returns (uint256);

  function lastClaimTimestamp() external view returns (uint256);

  function getHero(uint256 tokenId) external pure returns (Hero hero);

  function getJuiceProducedBy(address addr) external view returns (uint256);

  function getTokensByOwner(address owner)
    external
    view
    returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBurnableToken is IERC20 {
  function MAX_SUPPLY() external pure returns (uint256);

  function mint(address account, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function addController(address controller) external;

  function removeController(address controller) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Seed is Ownable {
  uint256 public seed;

  function update(uint256 _seed) external onlyOwner returns (uint256) {
    seed =
      seed ^
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            _seed,
            block.timestamp,
            blockhash(block.number - 1)
          )
        )
      );

    return seed;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWhitelist {
  function isWhitelisted(address addr) external view returns (bool);

  function getClaimableDiscounts(address addr) external view returns (uint256);

  function addToClaims(address addr, uint256 amountMinted) external;

  function MAX_CLAIMS_PER_ADDRESS() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IShop {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFundsManager {
  function transferFunds() external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGardenerAndFarmer.sol";
import "./interfaces/IBurnableToken.sol";
import "./interfaces/IField.sol";

contract GNFChecker is Ownable {
  IGardenerAndFarmer public gnf;
  IBurnableToken public seedToken;
  IField public field;
  address public spaceFarmer;

  uint256 public constant SEED_PRICE = 250000 ether;

  // Token id => whether it has already been claimed for free mint
  mapping(uint256 => bool) private idToFreeMintClaimed;
  // Address => how many discounted mints this address did so far
  mapping(address => uint8) private discountedMints;
  uint16 public mintLeft = 1000;

  constructor(
    address _gnf,
    address _seedToken,
    address _field
  ) {
    require(
      _gnf != address(0) && _field != address(0) && _seedToken != address(0),
      "Invalid address"
    );
    gnf = IGardenerAndFarmer(_gnf);
    seedToken = IBurnableToken(_seedToken);
    field = IField(_field);
  }

  /**
   * @dev Modifier to make sure that the mint for holder of G and F
   * can only be done when the Gardener and Farmer contract is paused
   */
  modifier whenGNFPaused() {
    require(gnf.paused(), "Gardener and Farmer not paused");
    _;
  }

  /**
   * @dev Functions modifying state of this contract can only be called
   * by the SpaceFarmer contract
   */
  modifier onlySpaceFarmer() {
    require(_msgSender() == spaceFarmer, "Not allowed");
    _;
  }

  function claimTokensForSeed(address buyer, uint256 amount)
    external
    whenGNFPaused
    onlySpaceFarmer
  {
    require(mintLeft >= amount, "Not enough mints left");
    // Get the total price form the amount and price per token
    uint256 totalPrice = amount * SEED_PRICE;
    // Get the balance of the buyer
    uint256 balance = seedToken.balanceOf(buyer);
    // Check that the buyer has enough $SEED
    require(balance >= totalPrice, "Not enough $SEED");
    // Burn the $SEED associated to this purchase
    seedToken.burn(buyer, totalPrice);
    // Removing the minted tokens from the supply left to mint
    // for v1 holders
    mintLeft -= uint16(amount);
  }

  function claimDiscountedMints(address owner, uint256 amount)
    external
    whenGNFPaused
    onlySpaceFarmer
  {
    require(mintLeft >= amount, "Not enough mints left");
    // If the amount plus the already claimed discounted mints
    // is higher than the limit per address of 5, we limit it
    // to the rest available for the sender if any
    uint256 amountToAdd = discountedMints[owner] + amount > 5
      ? 5 - discountedMints[owner]
      : amount;
    // If any left we update the state accordingly
    if (amountToAdd > 0) {
      discountedMints[owner] += uint8(amountToAdd);
      mintLeft -= uint16(amountToAdd);
    }
  }

  function claimTokens(address owner) external whenGNFPaused onlySpaceFarmer {
    // Get the balance of the buyer
    uint256 balance = gnf.balanceOf(owner);
    // Get the staked GNF tokens
    uint256[] memory stakedTokens = field.getTokensByOwner(owner);
    uint256[] memory tokenIds = new uint256[](balance + stakedTokens.length);

    for (uint256 i = 0; i < balance + stakedTokens.length; i++) {
      // Get both the staked and unstaked tokens
      uint256 tokenId = i >= balance
        ? stakedTokens[i - balance]
        : gnf.tokenOfOwnerByIndex(owner, i);
      // Add the to the array
      tokenIds[i] = tokenId;
    }
    // Then proceed to the update the state for each
    _claimTokens(tokenIds);
  }

  function _claimTokens(uint256[] memory tokenIds) private {
    uint256 total;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      // Skip the ones already claimed
      if (idToFreeMintClaimed[tokenId]) {
        continue;
      }
      bool isGardener = gnf.getTokenTraits(tokenId).isGardener;
      // A gardener gives 1 free mint while a farmer gives 2
      uint256 freeMints = isGardener ? 1 : 2;
      // Add to the total
      total += freeMints;
      // Limit to 20 per transactions
      if (total > 20) {
        break;
      }
      // Update the state accordingly
      mintLeft -= isGardener ? 1 : 2;
      // Marked the mint associated to this token as claimed
      idToFreeMintClaimed[tokenId] = true;
    }
  }

  function isGNFHolder(address owner) public view returns (bool) {
    // Check both the staked and unstaked balance
    return gnf.balanceOf(owner) > 0 || field.getTokensByOwner(owner).length > 0;
  }

  function getAvailableFreeMints(address owner, bool includeLimit)
    external
    view
    returns (uint256)
  {
    // Skip it altogether if no mint is left
    require(mintLeft > 0, "Not enough mints left");
    uint256 balance = gnf.balanceOf(owner);
    uint256[] memory stakedTokens = field.getTokensByOwner(owner);
    uint256 total = 0;
    for (uint256 i = 0; i < balance + stakedTokens.length; i++) {
      // Get both the staked and unstaked tokens
      uint256 tokenId = i >= balance
        ? stakedTokens[i - balance]
        : gnf.tokenOfOwnerByIndex(owner, i);
      // Update the state if not already claimed
      if (!idToFreeMintClaimed[tokenId]) {
        bool isGardener = gnf.getTokenTraits(tokenId).isGardener;
        // 2 tokens for a farmer and 1 for a gardener
        uint256 freeMints = isGardener ? 1 : 2;
        // If we include the limit then it's 20 per transaction max
        if (includeLimit && total + freeMints > 20) {
          break;
        }
        // Update the total accordingly
        total += freeMints;
      }
    }
    return total;
  }

  function isTokenClaimed(uint256 tokenId) external view returns (bool) {
    return idToFreeMintClaimed[tokenId];
  }

  function getAvailableDiscountedMints(address owner)
    external
    view
    returns (uint256)
  {
    return isGNFHolder(owner) ? 5 - discountedMints[owner] : 0;
  }

  function setSpaceFarmer(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    spaceFarmer = addr;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISpaceFarmer.sol";

contract SupplyManager is Ownable {
  uint256 private constant GEN0_MUTANT_COUNT = 9000;
  uint256 private constant GEN0_SPACE_FARMER_COUNT = 1000;
  uint256 private constant GEN1_MUTANT_COUNT = 45000;
  uint256 private constant GEN1_SPACE_FARMER_COUNT = 5000;
  uint256 private constant SUPER_MUTANT_COUNT = 1000;

  address public spaceFarmer;

  mapping(uint256 => uint256) private movedIds;
  // Mint phase => Hero => supply left
  mapping(MintPhase => mapping(Hero => uint256)) private supplyLeft;

  constructor() {
    supplyLeft[MintPhase.Gen0][Hero.Mutant] = GEN0_MUTANT_COUNT;
    supplyLeft[MintPhase.Gen0][Hero.SpaceFarmer] = GEN0_SPACE_FARMER_COUNT;
    supplyLeft[MintPhase.Gen0SuperMutant][
      Hero.SuperMutant
    ] = SUPER_MUTANT_COUNT;
    supplyLeft[MintPhase.Gen1][Hero.Mutant] = GEN1_MUTANT_COUNT;
    supplyLeft[MintPhase.Gen1][Hero.SpaceFarmer] = GEN1_SPACE_FARMER_COUNT;
    supplyLeft[MintPhase.Gen1][Hero.SuperMutant] = SUPER_MUTANT_COUNT;
  }

  function generateTokenId(
    uint256 randomNumber,
    MintPhase mintPhase,
    Hero hero
  ) external returns (uint256 tokenId) {
    // Only the Space Farmer contract can alter the state of this contract
    require(_msgSender() == spaceFarmer, "Not allowed");
    // The generation logic is different for Gen1 and Gen0
    if (mintPhase == MintPhase.Gen1) {
      tokenId = _generateGen1TokenId(randomNumber, hero);
    } else {
      tokenId = _generateGen0TokenId(randomNumber, mintPhase);
    }
  }

  function _generateGen0TokenId(uint256 randomNumber, MintPhase mintPhase)
    private
    returns (uint256)
  {
    // Only for Gen0 and Gen0SuperMutant
    require(mintPhase != MintPhase.Gen1, "Wrong mint phase");
    uint256 tokenId;
    if (mintPhase == MintPhase.Gen0) {
      // Check there's enough supply left
      require(
        supplyLeft[MintPhase.Gen0][Hero.SpaceFarmer] > 0 ||
          supplyLeft[MintPhase.Gen0][Hero.Mutant] > 0,
        "No supply left"
      );
      // Generate either a Space Farmer or Mutant between id 1 and 10000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        10000,
        0,
        GEN0_MUTANT_COUNT +
          GEN0_SPACE_FARMER_COUNT -
          (supplyLeft[MintPhase.Gen0][Hero.Mutant] +
            supplyLeft[MintPhase.Gen0][Hero.SpaceFarmer])
      );
      if (tokenId <= 1000) {
        // If below or equal to 1000, then it's an id of a Space Farmer
        // so remove that one from the supply left
        supplyLeft[MintPhase.Gen0][Hero.SpaceFarmer] -= 1;
      } else {
        // Similarly above 1000 and below 10001 it's a Mutant
        supplyLeft[MintPhase.Gen0][Hero.Mutant] -= 1;
      }
    } else if (mintPhase == MintPhase.Gen0SuperMutant) {
      // Check there's enough supply left
      require(
        supplyLeft[MintPhase.Gen0SuperMutant][Hero.SuperMutant] > 0,
        "No supply left"
      );
      // Super Mutant have id between 10001 and 11000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        11000,
        10000,
        SUPER_MUTANT_COUNT -
          supplyLeft[MintPhase.Gen0SuperMutant][Hero.SuperMutant]
      );
      // Update the state accordingly
      supplyLeft[MintPhase.Gen0SuperMutant][Hero.SuperMutant] -= 1;
    }
    require(tokenId > 0, "Unable to generate token id");
    return tokenId;
  }

  function _generateGen1TokenId(uint256 randomNumber, Hero hero)
    private
    returns (uint256)
  {
    // Check there's enough supply left
    require(supplyLeft[MintPhase.Gen1][hero] > 0, "No supply left");
    uint256 tokenId;
    // Mint a specific hero according to the one requested in Gen1
    if (hero == Hero.Mutant) {
      // Mutants are between 11001 and 56000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        56000,
        11000,
        GEN1_MUTANT_COUNT - supplyLeft[MintPhase.Gen1][Hero.Mutant]
      );
    } else if (hero == Hero.SpaceFarmer) {
      // Space Farmers are between 56001 and 61000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        61000,
        56000,
        GEN1_SPACE_FARMER_COUNT - supplyLeft[MintPhase.Gen1][Hero.SpaceFarmer]
      );
    } else if (hero == Hero.SuperMutant) {
      // Super Mutants are between 61001 and 62000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        62000,
        61000,
        SUPER_MUTANT_COUNT - supplyLeft[MintPhase.Gen1][Hero.SuperMutant]
      );
    }
    // Update the supply left according to the hero chosen
    supplyLeft[MintPhase.Gen1][hero] -= 1;
    require(tokenId > 0, "Unable to generate token id");
    return tokenId;
  }

  /**
   * @dev Pick a random token id among the ones still available
   * @param randomNumber Random seed to serve for the generation
   */
  function _generateTokenId(
    uint256 randomNumber,
    uint256 upperBound,
    uint256 lowerBound,
    uint256 supplyMinted
  ) private returns (uint256) {
    // We get the number of ids remaining
    uint256 rangeSize = upperBound - lowerBound - supplyMinted;
    // Keep the randomIndex within the range
    uint256 randomIndex = (randomNumber % rangeSize) + lowerBound;
    // Pick the id at randomIndex within the ids remanining
    uint256 tokenId = getIdAt(randomIndex);

    // Move the last id in the remaining ids in the current range into position randomIndex
    // That way if we get that randomIndex again it will return that number
    movedIds[randomIndex] = getIdAt(rangeSize - 1 + lowerBound);
    // Free the storage used at the last index if used
    delete movedIds[rangeSize - 1 + lowerBound];

    return tokenId;
  }

  function getIdAt(uint256 i) private view returns (uint256) {
    // Return the number stored at index i if it has been defined
    if (movedIds[i] != 0) {
      return movedIds[i];
    } else {
      // Otherwise just return the i + 1 (as it starts at 1)
      return i + 1;
    }
  }

  function getSupplyLeft(MintPhase phase, Hero hero)
    external
    view
    returns (uint256)
  {
    return supplyLeft[phase][hero];
  }

  function setSpaceFarmer(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    spaceFarmer = addr;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IGardenerAndFarmer is IERC721, IERC721Enumerable {
  // struct to store each token's traits
  struct GardenerFarmer {
    bool isGardener;
    uint8 eyes;
    uint8 hat;
    uint8 beard;
    uint8 clothes;
    uint8 shoes;
    uint8 accessory;
    uint8 gloves;
    uint8 hair;
    uint8 scoreIndex;
  }

  function paused() external view returns (bool);

  function setPaused(bool value) external;

  function getPaidTokens() external view returns (uint256);

  function getTokenTraits(uint256 tokenId)
    external
    view
    returns (GardenerFarmer memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IField {
  function getTokensByOwner(address owner)
    external
    view
    returns (uint256[] memory tokenIds);
}