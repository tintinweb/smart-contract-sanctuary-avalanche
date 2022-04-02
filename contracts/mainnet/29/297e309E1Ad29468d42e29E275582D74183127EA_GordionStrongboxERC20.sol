/**
 *Submitted for verification at snowtrace.io on 2022-04-01
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: TokenGames/GordionStrongboxERC20.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



interface IAvaGame {
    function houseEdgeCalculator(address player) external view returns (uint houseEdge);
}

interface IERC721_2 is IERC721 {
    function exists(uint tokenId) external returns (bool);

    function reflectToOwners() external payable;

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenID);

    function totalSupply() external returns (uint256);
}

contract GordionStrongboxERC20 {
    /**
    Events
     */
    event DepositAVAX(address indexed sender, uint256 amount);
    event DepositToken(address indexed sender, uint256 amount);

    modifier onlyOwners() {
        require(isOwner[msg.sender], "0x03");
        _;
    }

    mapping(address => bool) public isOwner;
    mapping(address => bool) public isGame;

    address private nftAddress;
    IERC721_2 public nft;
    uint[] public claimableTotal;
    
    uint256[] public nftHolderReward;
    uint256[] public burnRate;
    uint256[] public wShare;

    address public dev = address(0xe650580Ab0B22C253e13257430b1102dB8C27d1E);
    address public vl = address(0x991c2252B11d28100F0F2fa3cdFB821056D5414d);
    address public cube = address(0x1152Ff6d620aa0ED8EC3C83711E8f2f756E5B8D5);
    address public avadice = address(0x4f63428BD8AAb63bEEd04ef0CC6F49286123d2bF);

    
    mapping(uint256 => uint256[4444]) public lastDividendAt;
    uint256[] public totalDividend;

    address[] public playableTokens;
    mapping(address => bool) public isPlayableToken;

    constructor(address _nftAddress) {
        isOwner[msg.sender] = true;
        setNFTAdress(_nftAddress);
    }

    function setNFTAdress(address _nftAddress) public onlyOwners {
        nftAddress = _nftAddress;
        nft = IERC721_2(nftAddress);
    }

    function addGame(address[] calldata _games) external onlyOwners {
        for(uint i = 0; i<_games.length; i++){
            isGame[_games[i]] = true;
        }
    }

    function removeGame(address[] calldata _games) external onlyOwners {
        for(uint i = 0; i<_games.length; i++){
            isGame[_games[i]] = true;
        }
    }

    function setNFTHolderReward(uint _nftHolderReward, uint tokenIndex) external onlyOwners {
        nftHolderReward[tokenIndex] = _nftHolderReward;
    }

    function setBurnRate(uint _burnRate, uint tokenIndex) external onlyOwners {
        burnRate[tokenIndex] = _burnRate;
    }

    function setWShare(uint _wShare, uint tokenIndex) external onlyOwners {
        wShare[tokenIndex] = _wShare;
    }

    function addOwner(address[] calldata _owners) external onlyOwners {
        for(uint i = 0; i<_owners.length; i++){
            isOwner[_owners[i]] = true;
        }
    }

    function removeOwner(address[] calldata _owners) external onlyOwners {
        for(uint i = 0; i<_owners.length; i++){
            isOwner[_owners[i]] = false;
        }
    }

    function addPlayableToken(address _tokenAddress, uint _nftHolderReward, uint _burnRate, uint _wShare) external onlyOwners {
        claimableTotal.push(0);
        playableTokens.push(_tokenAddress);
        isPlayableToken[_tokenAddress] = true;
        nftHolderReward.push(_nftHolderReward);
        burnRate.push(_burnRate);
        wShare.push(_wShare);
        totalDividend.push();
    }

    function removePlayableToken(address _tokenAddress) external onlyOwners {
        isPlayableToken[_tokenAddress] = false;
    }


    /*--------------PAYMENT MANAGEMENT--------------*/
    function depositERC20(uint amount, uint tokenIndex) external {
        if(isGame[msg.sender]) {
            IAvaGame game = IAvaGame(msg.sender);
            uint houseEdge = game.houseEdgeCalculator(tx.origin);
            claimableTotal[tokenIndex] += amount * 1000 / (houseEdge + 1000) * houseEdge / 1000;
        } else {
            IERC20 _token = IERC20(playableTokens[tokenIndex]);
            require(_token.allowance(msg.sender, address(this)) >= amount);
            _token.transferFrom(msg.sender, address(this), amount);
        }
        emit DepositAVAX(msg.sender, amount);
    }

    function executePaymentERC20(uint256 amount, address _to, uint tokenIndex) external{
        require(isGame[msg.sender] || isOwner[msg.sender]);
        IERC20 _token = IERC20(playableTokens[tokenIndex]);
        require((_token.balanceOf(address(this)) - amount) >= claimableTotal[tokenIndex]);
        _token.transfer(_to, amount);
    }

    function withdrawERC20byIndex(uint256 amount, address _to, uint tokenIndex) external{
        require(isOwner[msg.sender]);
        IERC20 _token = IERC20(playableTokens[tokenIndex]);
        _token.transfer(_to, amount);
    }

    function withdrawAnyERC20(uint256 amount, address _to, address tokenAddress) external{
        require(isOwner[msg.sender]);
        IERC20 _token = IERC20(tokenAddress);
        _token.transfer(_to, amount);
    }

    function splitDividend(uint tokenIndex) external onlyOwners {
        IERC20 _token = IERC20(playableTokens[tokenIndex]);
        require(_token.balanceOf(address(this)) > claimableTotal[tokenIndex]);

        uint claimableNFTReward = claimableTotal[tokenIndex] * nftHolderReward[tokenIndex] / 10000;
        reflectDividend(claimableNFTReward, tokenIndex);
        uint burnAmount = claimableTotal[tokenIndex] * burnRate[tokenIndex] / 10000;
        _token.transfer(address(0x000000000000000000000000000000000000dEaD), burnAmount);
        uint developmentShare = claimableTotal[tokenIndex] * wShare[tokenIndex] / 10000;
        _token.transfer(vl,developmentShare);
        _token.transfer(dev,developmentShare);
        uint lastShare = claimableTotal[tokenIndex] - (developmentShare * 2)  - claimableNFTReward - burnAmount;
        _token.transfer(avadice,lastShare);
        claimableTotal[tokenIndex] = 0;
    }

    function resetClaimable(uint tokenIndex) external onlyOwners {
        claimableTotal[tokenIndex] = 0;
    }

    function claimRewards(uint tokenIndex) public {
        uint count = nft.balanceOf(msg.sender);
        require(count > 0);
        uint256 balance = 0;
        for (uint i = 0; i < count; i++) {
            uint token721Id = nft.tokenOfOwnerByIndex(msg.sender, i);
            uint256 _reflectionBalance = getReflectionBalance(token721Id,tokenIndex);
            balance = balance + _reflectionBalance;
            lastDividendAt[tokenIndex][token721Id] = totalDividend[tokenIndex];
        }
        IERC20 _token = IERC20(playableTokens[tokenIndex]);
        _token.transfer(msg.sender, balance);
    }

    function getReflectionBalances(uint tokenIndex) public view returns (uint256 _total) {
        uint count = nft.balanceOf(msg.sender);
        _total = 0;

        for (uint i = 0; i < count; i++) {
            uint tokenId = nft.tokenOfOwnerByIndex(msg.sender, i);
            uint256 _reflectionBalance = getReflectionBalance(tokenId, tokenIndex);
            _total = _total + _reflectionBalance;
        }
    }

    function getReflectionBalance(uint256 token721Id, uint tokenIndex) public view returns (uint256 _reflectionBalance){
        _reflectionBalance = totalDividend[tokenIndex] - lastDividendAt[tokenIndex][token721Id];
    }

    function reflectDividend(uint256 amount, uint tokenIndex) private {
        totalDividend[tokenIndex] = totalDividend[tokenIndex] + (amount / nft.totalSupply());
    }

    function addClaimableToken(uint amount, uint tokenIndex) public {
        IERC20 _token = IERC20(playableTokens[tokenIndex]);
        require(_token.allowance(msg.sender, address(this)) >= amount);
        _token.transferFrom(msg.sender, address(this), amount);
        reflectDividend(amount, tokenIndex);
    }
}