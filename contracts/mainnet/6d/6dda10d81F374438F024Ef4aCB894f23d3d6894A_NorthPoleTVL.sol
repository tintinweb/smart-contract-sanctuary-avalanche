// SPDX-License-Identifier: GPL-v3

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.7;

interface Cauldron {
    function bentoBox() external view returns (address);

    function collateral() external view returns (address);

    function oracle() external view returns (address);
}

interface IBentoBox {
    function totals(address token) external view returns (uint256 elastic, uint256 base);
}

interface IOracle {
    function peekSpot(bytes calldata data) external view returns (uint256 rate);
}

contract NorthPoleTVL is Ownable {
    struct CauldronInfo {
        bool available;
    }

    struct CauldronAddress {
        address cauldron;
    }

    mapping(address => CauldronInfo) public cauldronInfo;

    CauldronAddress[] public bentoBoxCauldrons;

    function addCauldron(address _cauldron) external onlyOwner {
        CauldronInfo memory poolInfo = cauldronInfo[_cauldron];
        poolInfo.available = true;
        cauldronInfo[_cauldron] = poolInfo;
        for (uint256 i = 0; i < bentoBoxCauldrons.length; i++) {
            require(bentoBoxCauldrons[i].cauldron != _cauldron, "already added");
        }
        bentoBoxCauldrons.push(CauldronAddress({cauldron: _cauldron}));
    }

    function setCauldron(address _cauldron, bool _available) external onlyOwner {
        CauldronInfo memory poolInfo = cauldronInfo[_cauldron];
        poolInfo.available = _available;
        cauldronInfo[_cauldron] = poolInfo;
    }

    function singleTVL(address _cauldron) public view returns (uint256 tvl) {
        CauldronInfo memory poolInfo = cauldronInfo[_cauldron];
        if (poolInfo.available) {
            address bentobox = Cauldron(_cauldron).bentoBox();
            address collateral = Cauldron(_cauldron).collateral();
            address oracle = Cauldron(_cauldron).oracle();
            uint256 tokenToUSD = 1e36 / IOracle(oracle).peekSpot(new bytes(0));
            (uint256 elastic, ) = IBentoBox(bentobox).totals(collateral);
            tvl = (elastic * tokenToUSD) / 1e18;
        } else {
            tvl = uint256(0);
        }
    }

    function totalTVL() external view returns (uint256 tvl) {
        for (uint256 i = 0; i < bentoBoxCauldrons.length; i++) {
            tvl = tvl + singleTVL(bentoBoxCauldrons[i].cauldron);
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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