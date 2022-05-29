/**
 *Submitted for verification at snowtrace.io on 2022-05-28
*/

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/interfaces/INft.sol

pragma solidity ^0.8.0;



interface INft is IERC721, IERC721Enumerable {
    function setNftMetadata(
        string memory _baseTokenUri,
        uint256 _mintPrice,
        uint256 _maxMintSupply,
        address _paymentSplitterContractAddress,
        address _burnerContractAddress,
        bool _mintingEnabled,
        bool _whitelistMintingEnabled
    ) external;

    function mint(uint256 amount) external;

    function claimFreeMints(uint256 amount) external;

    function mintExtra(address recievingAddress, uint256 tokenId) external;

    function setWhitelistAddress(address[] memory userAddresses, bool isWhitelisted)
        external;

    function setFreeMintsForAddress(address userAddress, uint256 amount)
        external;
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/applications/FreeMints.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract FreeMints is Ownable {

    address private CONTRACT_ADDRESS = 0x7D881698BD4F8134DA8db586cB2238AB905D89d5;
    
    constructor(){}

    function execute() public {
        address[63] memory addresses  = [0x9B385f6479204E26C2A68ec4a7BC48C5c0AbD735,0xd751cAD901FEe442Da3C1bAB558e81cc8FdcFa95,0x8073273f19d14A9D8545BE778d2c27d62F83B302,0x7C95C348aef18Fec3857C62b160a0eCbc6cD973F,0xB37eF4EAa5293Ab383792cdE9c7Dc42668038A00,0xcd720c571335eDDaeB5B0BBB7B2A9F1FA952821a,0x54Abb9F417702f25D91b1987Bb56f235298Af9D7,0xE67BA38196b029Fa5FC2f2781300Bc024050095E,0xB5001Ab85Ca0295c71C852bb4C11Fc7d264A429C,0x20144C31d380Bdc127dd76422A5627b41D4ccA1F,0xE9db81A85fDc1f28239bdcA8D3054ad39F44A8D5,0xcc3f3E0d5155C7436A5C8f7Aa6b7bDE5797813E9,0xDD277b589804DE50560Ec5bd3562Fc00aaecF325,0xea08dD1D9162B58e22bb93747CC402b588AC1122,0x7969639a1565a1C157e33382dF53CB6B319d0F23,0xAB4bFE2c164355b9Fbc3c70Ec35cDC44786484Fb,0x6Ef41e2a411b55A76C0a5C6736c8Af644585Fe70,0x79D0890a75a14beF6bF52B71fF508E05D2E1eec0,0x668fF879557b113b5a37e6952cca6A0AAE2F1DBB,0x49cb861920b873945b3C26FaDDF38C7579006B5D,0xd8936E602E38dfEe5d6466865068b94b1943DEBF,0x984c5d268B220784E87fbe8EDbb5C6b9F7ba9Fc4,0x8Aa8677980DfccBb5C5b39a8B742baB750056d7C,0x5F4814860A598c24f699827Bb4f593abdfdAA276,0x4ebCe12FF36E8781B0c699EB92978ABcc4556cE2,0x820dC4cE6677FF32A3Af41A1eD12Ec406f12eB9F,0x3aAb4A7F45bD9030eC3607738EDd817BbdAB6DD4,0x3255db9aDFe3D2c95118D58d94C6Ee98d4c98933,0xe23696614faB51731d1731F5a8E105b22f8d26A6,0x32A9e673F84e53Ad6Ab5F006F6F7F425fAbfe53f,0xfbd0E71A4fF49eBb789bF14b55d1A1c2c06a74AF,0x85031f66d6d9D2ab7E15059b01c1a43086bED87E,0xCCc8fd4FD942560d5002410CBacEa79020469dd5,0xfaF8a56f600e6758BCe4E724FD738C3ca1Cd0A25,0x37F710E60AbdFd1C0E905c61a49dbCfBE5128329,0x8B39440F2740e1cB832509790A40A1395b5e386a,0x724186d0C9AcF65bA3335573b2C81D8C9ddab282,0x0492A80d26Ed93742F2a0b67600A774c7cC1A22e,0x8553E24b9eb99c21Ea96A3E167CF4B8c75fb345C,0x33158e92B8c0f2051d759Fc03AF75Fca7cBeca84,0xF157F81f8F596845c0b21507a385a197Ee5F8E1B,0x38111EE99D8D3ab575fC6814eFf689fA6AD51971,0x58EB9BBA9DCaDA1023C9B585509bF0c907a413FA,0x02B3d4378156009E000Ef4A5B92026F3C0aE7E5b,0xd4Be5943103836D3fD909dD5c244451ee8e1786a,0xabf1FF91cECD9990B3f29363B62B87FD76f55F4A,0x0e5B1e1129D38bFA0010F83D4cc313e39f9a727F,0x58B311908EF0Cfc304B603E94bb0d10AFca3A93F,0xdFa5CE59C8363522B559e109D17fc880B59cCF88,0x232dbcF74015379c336007b281628E435ee542fB,0xd3572fB6c349AE55346Fc472581220b1dE14ccA7,0x85378cdCCF0aEd81Fb31CB19529156C0444546f4,0x77b13B881CceC49F721A76c38C4EBE09004Ae042,0x155b6485305CcaB44EF7da58AC886C62cE105CF9,0x1486b56ef5DB1dDD0d052b543c34A89d55379c30,0xf70Cc6d6535822FdF3E3cd51042a15EBA7e5d367,0xddcc6A7c9F53a437F4d6515bdf058b029e8E1169,0xF343E409F07d21d7710a680d9EE07E8ff609d60B,0x1E7f1f48b537b1fD8a5943DC1a88c080C3860E6A,0xb1da15a88edb50fDdaBFfcfB60E43d559Aa5689d,0x91c5891771628AAFD75815B2Db0093F5af130c1b,0x5B187c84b31C243202959aB4B54f8396E5DBaf32,0xa13Ab7683126E2d203E8761D43DA6bc59C82D542];
        uint8[63] memory mints = [1, 1, 1, 3, 2, 1, 5, 3, 2, 1, 2, 10, 1, 1, 1, 1, 1, 179, 1, 1, 1, 44, 3, 6, 1, 4, 1, 1, 1, 1, 1, 121, 2, 1, 1, 1, 1, 3, 1, 3, 1, 1, 7, 1, 3, 2, 3, 5, 2, 1, 1, 10, 3, 3, 1, 1, 1, 5, 1, 1, 2, 2, 3];

        for (uint256 i=0; i<addresses.length; i++) {
            INft(CONTRACT_ADDRESS).setFreeMintsForAddress(addresses[i], mints[i]);
        }
    }
}