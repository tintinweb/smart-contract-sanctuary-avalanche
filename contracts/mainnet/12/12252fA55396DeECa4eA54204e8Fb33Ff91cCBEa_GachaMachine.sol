/**
 *Submitted for verification at snowtrace.io on 2023-02-02
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/interfaces/IElementalStone.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IElementalStone {
    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function attune(
        address account,
        uint256 id,
        uint256 girlId
    ) external;
}

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File contracts/Gacha/GachaMachine.sol

pragma solidity ^0.8.4;

interface IMoonstone {
    function mint(address to, uint256 amount) external;
}

interface ICosmicDust {
    function mint(address to, uint256 amount) external;
}

contract GachaMachine is Ownable {
    IMoonstone public moonstone;
    ICosmicDust public cosmicDust;
    IElementalStone public elementalStone;

    mapping(address => bool) public isArc;
    mapping(address => bool) public isWorker;

    uint256 public costPerSpin = 10 ether;

    event DealerSent(address indexed user, uint256 indexed spinId);

    constructor(address _arc) {
        isArc[_arc] = true;
        setWorker(msg.sender, true);
    }

    function setMoonstone(address _a) public onlyOwner {
        moonstone = IMoonstone(_a);
    }

    function setCosmicDust(address _a) public onlyOwner {
        cosmicDust = ICosmicDust(_a);
    }

    function setElementalStone(address _a) public onlyOwner {
        elementalStone = IElementalStone(_a);
    }

    function dealerSend(
        address user,
        uint256 spinId,
        uint256 cosmicDustAmount,
        uint256 moonstoneAmount,
        uint256 flameAmount,
        uint256 terraAmount,
        uint256 aquaAmount
    ) external onlyWorker {
        cosmicDust.mint(user, cosmicDustAmount);

        if (moonstoneAmount > 0) {
            moonstone.mint(user, moonstoneAmount);
        }

        if (flameAmount > 0) {
            elementalStone.mint(user, 1, flameAmount);
        }

        if (terraAmount > 0) {
            elementalStone.mint(user, 2, terraAmount);
        }

        if (aquaAmount > 0) {
            elementalStone.mint(user, 3, aquaAmount);
        }

        emit DealerSent(user, spinId);
    }

    function getCost() external view returns (uint256) {
        return costPerSpin;
    }

    function setCost(uint256 _c) public onlyOwner {
        costPerSpin = _c;
    }

    function setWorker(address _worker, bool _isWorker) public onlyOwner {
        isWorker[_worker] = _isWorker;
    }

    modifier onlyWorker() {
        require(isWorker[msg.sender], "Gacha: only worker can call");
        _;
    }
}