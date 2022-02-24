// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <=0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract AnyCivilizationGame is Ownable {
    address private _owner;
    address private _ctzn;
    address private _clstr;
    bool private isLaunched = false;
    mapping(address => uint[]) ownerToCitizen;
    mapping(address => uint[]) ownerToCluster;
    uint[] public citizenIds;
    uint[] public clusterIds;
    
    constructor() {
        _owner = msg.sender;
    }

    function createCluster() whenLaunched payable public returns(bool) {
        require(msg.value >= IClusterGenerator(_clstr).clusterPrice(), "Wrong fee");
        require(ICitizenG(_ctzn).balances(msg.sender) >= 1, "You should have at least 1 citizen.");
        uint id = clusterIds.length;
        IClusterGenerator(_clstr).generateCluster(msg.sender, id);
        clusterIds.push(id);
        ownerToCluster[msg.sender].push(id);
        return true;
    }
    
    function createCitizen() whenLaunched payable public{
        require(msg.value >= (0.1 ether) , "Wrong fee");
        uint id = citizenIds.length;
        ICitizenG(_ctzn).unfrozeCitizen(msg.sender, id);
        citizenIds.push(id);
        ownerToCitizen[msg.sender].push(id);
    }

    function getCitizensOfOwner(address _citizenOwner) public view returns(uint[] memory) {
        return ownerToCitizen[_citizenOwner];
    }

        function getClustersOfOwner(address _clusterOwner) public view returns(uint[] memory) {
        return ownerToCluster[_clusterOwner];
    }

    function setLaunched() onlyOwner public {
        isLaunched = true;
    }

    function setAddresses(address AnyCitizen, address AnyCluster) onlyOwner public {
        _ctzn = AnyCitizen;
        _clstr = AnyCluster;
    }

    function withdraw() onlyOwner public {
    payable(_owner).transfer(address(this).balance);
  }

  modifier whenLaunched() {
      require(isLaunched == true);
      _;
  }
}
    interface IClusterGenerator {
        function generateCluster(address _to, uint _id) payable external returns (uint);
        function clusterPrice() external returns(uint);
        function _ownerOf(uint256 tokenId) external view returns (address);
        function clusterCounter() external view returns(uint);
    }

    interface ICitizenG {
        function unfrozeCitizen(address  _to, uint _id) payable external returns (uint);
        function _ownerOf(uint256 tokenId) external view returns (address);
        function balances(address _address) external view returns (uint);
        function citizenCounter() external view returns(uint);
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