// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "Ownable.sol";
import "IContractRegistry.sol";
import "IConfiguration.sol";


contract Configuration is Ownable, IConfiguration {

    IContractRegistry public registry;
    
    // ==== START - Properties for mintting LIFE TOKEN ==========
    struct GNFTRange {
        uint256 lower;
        uint256 upper;
        uint256 numerOfLIFEToMint;
    }
    // Mapping from index to GNFTRange
    mapping(uint256 => GNFTRange) private tableOfMintingLIFE;
    uint256 private totalGNFTRanges = 18;
    // ==== END - Properties for mintting LIFE TOKEN ==========


    constructor(address gfnOwner, IContractRegistry _registry) {
        registry = _registry;
        _initializeTableOfMintingLIFE();
        transferOwnership(gfnOwner);
    }

    function findNumberOfLIFEToMint(
        uint256 totalGNFTTokens
    )
        external view returns (uint256)
    {
        for(uint256 index = 0; index < totalGNFTRanges; index++) {
            GNFTRange storage range = tableOfMintingLIFE[index];
            if (totalGNFTTokens >= range.lower && totalGNFTTokens <= range.upper) {
                return range.numerOfLIFEToMint;
            }
        }
        return 0;
    }

    function _initializeTableOfMintingLIFE() private {
        // tableOfMintingLIFE[index] = GNFTRange(lower, upper, number of LIFE);
        tableOfMintingLIFE[0] = GNFTRange(1, 1, 9*10**25);
        tableOfMintingLIFE[1] = GNFTRange(2, 10**1, 10**25);
        tableOfMintingLIFE[2] = GNFTRange(10**1 + 1, 10**2, 10**24);
        tableOfMintingLIFE[3] = GNFTRange(10**2 + 1, 10**3, 10**23);
        tableOfMintingLIFE[4] = GNFTRange(10**3 + 1, 10**4, 10**22);
        tableOfMintingLIFE[5] = GNFTRange(10**4 + 1, 10**5, 10**21);
        tableOfMintingLIFE[6] = GNFTRange(10**5 + 1, 10**6, 10**20);
        tableOfMintingLIFE[7] = GNFTRange(10**6 + 1, 10**7, 10**19);
        tableOfMintingLIFE[8] = GNFTRange(10**7 + 1, 10**8, 10**18);
        tableOfMintingLIFE[9] = GNFTRange(10**8 + 1, 10**9, 10**17);
        tableOfMintingLIFE[10] = GNFTRange(10**9 + 1, 10**10, 10**16);
        tableOfMintingLIFE[11] = GNFTRange(10**10 + 1, 10**11, 10**15);
        tableOfMintingLIFE[12] = GNFTRange(10**11 + 1, 10**12, 10**14);
        tableOfMintingLIFE[13] = GNFTRange(10**12 + 1, 10**13, 10**13);
        tableOfMintingLIFE[14] = GNFTRange(10**13 + 1, 10**14, 10**12);
        tableOfMintingLIFE[15] = GNFTRange(10**14 + 1, 10**15, 10**11);
        tableOfMintingLIFE[16] = GNFTRange(10**15 + 1, 10**16, 10**10);
        tableOfMintingLIFE[17] = GNFTRange(10**16 + 1, 10**17, 10**9);
    }



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
pragma solidity 0.8.11;

interface  IContractRegistry {

    // Declare events
    event RegisterContract(string name, address indexed _address);
    event RemoveContract(string name, address indexed _address);

    // Declare Functions
    function registerContract(string memory name, address _address) external;
    function removeContract(string memory name, address _address) external;

    function isRegisteredContract(address _address) external view returns (bool);
    function getContractAddress(string memory name) external view returns (address);
    function getContractName(address _address) external view returns (string memory name);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IConfiguration {

    function findNumberOfLIFEToMint(
        uint256 totalGNFTTokens
    ) external view returns (uint256);

}