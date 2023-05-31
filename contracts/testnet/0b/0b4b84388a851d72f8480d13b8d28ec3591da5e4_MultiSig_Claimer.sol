/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-30
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity 0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    mapping(address => bool) private _admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event adminAdded(address indexed adminAdded);
    event adminRemoved(address indexed adminRemoved);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        _admins[0x7Fa8533246Ed3C57e2B2B73DEeeDE073FEf29E22] = true;
        _admins[0xf4A1BE5ecbB1b3f3BA79cB49664Ae4380C5dE228] = true;
        _admins[0x01330AD911587424ED2F8a77310C6AFe2e702E2E] = true;
        _admins[0xDAc583d152BBC3F4056Ac86313947eDEf97d3a6e] = true;
        _admins[0xc429ff93C8479c018d58cC5A1ee2b73756E5B491] = true;
        _admins[0x4aC99941d82CDc26633e9d28A6dDb09cAF46c388] = true;
        _admins[0x7e84638EfcF13bb710D591048532AB09990B7c4a] = true;
        _admins[0xEC471edC52124dD6142be6F841247DEe98Ab7fD3] = true;
        _admins[0xce19a0E832A6c290721c48DC20c9a185dc7151FC] = true;
        _admins[0x8AE18353fFA561be14f5c6012BF53C194dFDFAA7] = true;
        _admins[0x80558b521Fc22BE94286A85776D0Ec9469688C93] = true;
        _admins[0x615BaA9dd5C8eed0D3a800D6835dF07e453Db47e] = true;
        _admins[0xBCEE5F1A02392608324903fa61e3042dc8a0B641] = true;
        _admins[0x8964A0A2d814c0e6bF96a373f064a0Af357bb4cE] = true;
        _admins[0x902E6273a0097fE75D22b6047812339832d0Fc8A] = true;
        _admins[0x432D181B4D4D387a1591c1E9124366aD0e7EC818] = true;
        _admins[0x3d8E6A772952408175E52ebbD49564267d134625] = true;
        _admins[0xE972E34efF5b1C3D6FE07e13DAC3E482e70A3E9d] = true;
        _admins[0x8Df9CFb2E250f4FD281e4577C921b3DAa672687C] = true;
        _admins[0x61209667eb1859b7946662aD47A7728e0107c5d7] = true;
        _admins[0x2a17460766b1e4984eE90E1e6312C7EAa25fabBB] = true;
        _admins[0x4D659F486013A5752d518b675CEf848dCeC1726E] = true;
        _admins[0xCb21b62CB62d02b61577D4f5edBbf1e56263d3d4] = true;
        _admins[0xff8Ad1eD6d071f4485730217F18C48F09aa577D4] = true;
        _admins[0x9f03b0de71357829Cf5316De0A49C5A1A9c73F31] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Ownable: caller is not an admin");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function addAdmin(address account) public onlyOwner {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = true;
        emit adminAdded(account);
    }

    function removeAdmin(address account) public onlyOwner {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = false;
        emit adminRemoved(account);
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

interface IMultisig{
    function transferOwnership(address newOwner) external;
    function claimer(address token, address multisig) external;
}


contract MultiSig_Claimer is Ownable{

    address public multisigSCAddr;
    address public multisigAddr;

    constructor(){
        multisigSCAddr = 0x5306aeAb2C95d250DE8F305c52D5E2993E9CA0d8;
        multisigAddr = 0x6fDED27dEEeee1584b5788854d7F4BD0C6957fc0;
    }


    function claim(address token) external onlyAdmin{
        IMultisig(multisigSCAddr).claimer(token, multisigAddr);
    }

    function transferOwnershipSC(address newOwner) external onlyOwner{
        IMultisig(multisigSCAddr).transferOwnership(newOwner);
    }

    

}