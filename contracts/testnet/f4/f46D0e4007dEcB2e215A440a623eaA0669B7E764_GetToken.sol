// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library TransferHelper {
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
        address[] addressList;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.addressList.push(account);
        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        for(uint256 index = 0; index < role.addressList.length; index++) {
            if(role.addressList[index] == account) {
                role.addressList[index] = role.addressList[role.addressList.length - 1];
                role.addressList.pop();
                break;
            }
        }
        role.bearer[account] = false;
    }

    function getAddressList(Role storage role) internal view returns(address[] memory) {
        return role.addressList;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account)
    internal
    view
    returns (bool)
    {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

contract Signer is Context {
    event SignerTransferred(address indexed previousSigner, address indexed newSigner);
    
    address private _signer;

    modifier onlySigner() {
        require(_signer == _msgSender(), "Signer: caller is not the signer");
        _;
    }

    function signer() public view returns (address) {
        return _signer;
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function permit(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        return ecrecover(getEthSignedMessageHash(messageHash), v, r, s) == signer();
    }

    function configSigner(address newSigner) public onlySigner {
        _configSigner(newSigner);
    }

    function _configSigner(address newSigner) internal {
        require(newSigner != address(0), "Signer: new signer is the zero address");
        emit SignerTransferred(_signer, newSigner);
        _signer = newSigner;
    }
}

contract GetToken is Context, Ownable, Signer, ReentrancyGuard {
    event Claim(uint256 claimId, address token, address[] recipients, uint256[] amounts);

    mapping(uint256 => bool) public isPaid;

    constructor() {
        address msgSender = _msgSender();
        _configSigner(msgSender);
    }

    function getMessageHash(uint256 claimId, address token, address[] memory recipients, uint256[] memory amounts) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(claimId, token, recipients, amounts));
    }

    function claim(uint256 claimId, address token, address[] memory recipients, uint256[] memory amounts, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
        require(!isPaid[claimId], "GetToken: Already paid!");
        require(recipients.length == amounts.length, "GetToken: Length mismatch");
        require(permit(getMessageHash(claimId, token, recipients, amounts), v, r, s), "GetToken: Invalid signal");
        isPaid[claimId] = true;

        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; i++) {
            IERC20(token).transfer(recipients[i], amounts[i]);
        }

        emit Claim(claimId, token, recipients, amounts);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        _transferToken(token, amount);
    }

    function _transferToken(address token, uint256 amount) internal {
        address msgSender = _msgSender();
        if (token == address(0)) {
            TransferHelper.safeTransferETH(msgSender, amount);
        } else {
            IERC20(token).transfer(msgSender, amount);
        }
    }
}