// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

pragma solidity ^0.8.0;

interface IFractionalNFT {
    struct Fractionalization {
        address fractionalToken; // Use address type for the interface
        bool isFractionalized;
        uint256 totalSupply;
    }

    function mint(uint256 tokenId, uint256 totalSupply) external;

    function exists(uint256 tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

    // Get the Fractionalization struct for a specific token ID
    // function getFractionalization(
    //     uint256 tokenId
    // ) external view returns (Fractionalization memory);

    function getIsFractionalized(uint256 tokenId) external view returns (bool);

    function getFractionalSupply(
        uint256 tokenId
    ) external view returns (uint256);

    function getTotalSupplied(uint256 tokenId) external view returns (uint256);

    function updateIsFractionalized(uint tokenId, bool updateBool) external;

    function updateTotalSupplied(uint tokenId, uint totalSupplied) external;

    // Get the total number of token IDs
    function getTokenIdsCount() external view returns (uint256);

    // Get a specific token ID by index
    function getTokenIdByIndex(uint256 index) external view returns (uint256);

    // Fractionalize a specific token ID
    function fractionalize(uint256 tokenId) external;

    // Event emitted when a token is fractionalized
    event TokenFractionalized(
        uint256 indexed tokenId,
        address fractionalToken,
        uint256 totalSupply
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFractionalToken {
    function totalSupply() external view returns (uint256);

    function setClaimAmount(
        address _claimAddress,
        uint256 _claimAmount
    ) external;

    function claim(address to) external view returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IFractionalNFT.sol";
import "./IFractionalToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultFunctionsConsumerV1 is Ownable {
    IFractionalNFT public nftContract;
    IFractionalToken public fractionalToken;
    mapping(uint256 => address) public depositor;

    constructor(address _nftContract, address _fractionalToken) {
        nftContract = IFractionalNFT(_nftContract);
        fractionalToken = IFractionalToken(_fractionalToken);
    }

    function getDepositor(
        uint256 tokenId
    ) external view returns (address depositorAddress) {
        depositorAddress = depositor[tokenId];
    }

    function depositNFT(uint256 nftTokenId) public onlyOwner {
        require(
            !nftContract.getIsFractionalized(nftTokenId),
            "Fractional tokens already minted"
        );
        depositor[nftTokenId] = nftContract.ownerOf(nftTokenId);
        nftContract.transferFrom(
            nftContract.ownerOf(nftTokenId),
            address(this),
            nftTokenId
        );
        _fractionalize(nftTokenId);
    }

    function withdrawNFT(uint256 nftTokenId) public onlyOwner {
        delete (depositor[nftTokenId]);
        // require(
        //     nftContract.getTotalSupplied(nftTokenId) == 0,
        //     "Fractional tokens must be burned first"
        // );
        nftContract.transferFrom(address(this), msg.sender, nftTokenId);
        fractionalToken.burn(
            msg.sender,
            nftContract.getTotalSupplied(nftTokenId)
        );
        nftContract.updateIsFractionalized(nftTokenId, true);
        nftContract.updateTotalSupplied(nftTokenId, 0);
    }

    function _fractionalize(uint256 tokenId) private {
        require(nftContract.exists(tokenId), "Token ID does not exist");
        require(
            !nftContract.getIsFractionalized(tokenId),
            "Token ID is already fractionalized"
        );
        uint256 totalSupply = nftContract.getTotalSupplied(tokenId);
        nftContract.updateIsFractionalized(tokenId, true);
        fractionalToken.mint(depositor[tokenId], totalSupply * 10 ** 18);
    }

    // // Chainlink Keeper function
    // function checkUpkeep(
    //     bytes calldata checkData
    // )
    //     external
    //     view
    //     override
    //     returns (bool upkeepNeeded, bytes memory performData)
    // {
    //     uint256[] memory tokensToFractionalize = new uint256[](
    //         nftContract.getTokenIdsCount()
    //     );
    //     uint256 count = 0;
    //     for (uint256 i = 0; i < nftContract.getTokenIdsCount(); i++) {
    //         uint256 tokenId = nftContract.getTokenIdByIndex(i);
    //         bool isFractionalized = nftContract.getIsFractionalized(tokenId);
    //         if (!isFractionalized) {
    //             tokensToFractionalize[count] = tokenId;
    //             count++;
    //         }
    //     }
    //     if (count > 0) {
    //         upkeepNeeded = true;
    //         performData = abi.encode(tokensToFractionalize, count);
    //     } else {
    //         upkeepNeeded = false;
    //         performData = "0x";
    //     }
    // }

    // // Chainlink Keeper function
    // function performUpkeep(bytes calldata performData) external override {
    //     (uint256[] memory tokensToFractionalize, uint256 count) = abi.decode(
    //         performData,
    //         (uint256[], uint256)
    //     );
    //     for (uint256 i = 0; i < count; i++) {
    //         uint256 tokenId = tokensToFractionalize[i];
    //         _fractionalize(tokenId);
    //     }
    // }
}