// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IAuthCenter.sol";
import "./IAuERC20.sol";

contract AuERC20 is IAuERC20 {
    address private owner;
    address private authCenter;
   
    uint256 private totalTokenSupply;

    uint8 private tokenDecimals = 18;
    string private tokenName = "AuToken";
    string private tokenSymbol = "AUG";

    // owner address => amount
    mapping(address => uint256) private balances;

    // daddy => spender => limit to spend
    mapping(address => mapping(address => uint256)) private allowances;
    
    // ----------------------------------------------------------------------
    
    constructor() { owner = msg.sender; }

    function updateOwner(address _address) external returns (bool) {
        require(msg.sender == owner, "AuERC20: You are not contract owner");
        owner = _address;
        emit UpdateOwner(_address);
        return true;
    }

    // @dev some gas ethers need for a normal work of this contract (change owner at least).
    // Only owner can put ethers to contract.
    receive() external payable
    { require(msg.sender == owner, "AuERC20: You are not contract owner"); }

    // @dev Only owner can return to himself gas ethers before closing contract
    function withDrawAll() external override {
        require(msg.sender == owner, "AuERC20: You are not contract owner");
        payable(owner).transfer(address(this).balance);
    }

    // @dev Link AuthCenter to contract
    function setAuthCenter(address _address) external override returns (bool) {
        require(msg.sender == owner, "AuERC20: You are not contract owner");
        require(_address != address(0), "AuERC20: authCenter is the zero address");
        authCenter = _address;
        return true;
    }

    // @dev set tokens name and symbol
    function setTokenInfo(string memory _tokenName, string memory _tokenSymbol) external override returns (bool) {
        require(authCenter != address(0), "AuERC20: authCenter is the zero address");
        require(IAuthCenter(authCenter).isAdmin(msg.sender), "AuERC20: You are not admin");
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        return true;
    }

    // @dev Returns the name of the token.
    function name() external view override returns (string memory)
    { return tokenName; }

    // @dev Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view override returns (string memory)
    { return tokenSymbol; }

    // @dev Returns the number of decimals used to get its user representation.
    function decimals() external view override returns (uint8)
    { return tokenDecimals; }

    // @dev Returns the amount of tokens in existence.
    function totalSupply() external view override returns (uint256)
    { return totalTokenSupply; }

    // @dev Returns the amount of tokens owned by `account`.
    function balanceOf(address _owner) external view override returns (uint256)
    { return balances[_owner]; }

    // @dev Moves `amount` tokens from the caller's account to `to`.
    function transfer(address _to, uint256 _value) external override returns (bool) {
        require(authCenter != address(0), "AuERC20: AuthCenter is the zero address");
        require(!IAuthCenter(authCenter).isContractPaused(address(this)), "AuERC20: contract paused");
        require(IAuthCenter(authCenter).isClient(msg.sender), "AuERC20: You are not our client");
        require(!IAuthCenter(authCenter).isAddressFrozen(msg.sender), "AuERC20: You are frozen");
        require(IAuthCenter(authCenter).isClient(_to), "AuERC20: '_to' not our client");
        require(!IAuthCenter(authCenter).isAddressFrozen(_to), "AuERC20: '_to' is frozen");
        require(_value >= 0,"AuERC20: transfer amount must be not negative");

        uint256 fromBalance = balances[msg.sender];
        require(fromBalance >= _value, "AuERC20: transfer amount exceeds balance");
        balances[msg.sender] = fromBalance - _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // @dev Returns the remaining number of tokens that `spender` will be
    // allowed to spend on behalf of `owner` through {transferFrom}.
    function allowance(address _daddy, address _spender) external view override returns (uint256) 
    { return allowances[_daddy][_spender]; }

    // @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address _spender, uint256 _value) external override returns (bool) {
        require(authCenter != address(0), "AuERC20: AuthCenter is the zero address");
        require(!IAuthCenter(authCenter).isContractPaused(address(this)), "AuERC20: contract paused");
        require(IAuthCenter(authCenter).isClient(msg.sender), "AuERC20: You are not our client");
        require(!IAuthCenter(authCenter).isAddressFrozen(msg.sender), "AuERC20: You are frozen");
        require(IAuthCenter(authCenter).isClient(_spender), "AuERC20: Spender not our client");
        require(!IAuthCenter(authCenter).isAddressFrozen(_spender), "AuERC20: Spender is frozen");
        require(_value >= 0, "AuERC20: trusted amount must be not negative");
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism. 
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
        require(authCenter != address(0), "AuERC20: AuthCenter is the zero address");
        require(!IAuthCenter(authCenter).isContractPaused(address(this)), "AuERC20: contract paused");
        require(IAuthCenter(authCenter).isClient(msg.sender), "AuERC20: You are not our client");
        require(!IAuthCenter(authCenter).isAddressFrozen(msg.sender), "AuERC20: You are frozen");
        require(IAuthCenter(authCenter).isClient(_from), "AuERC20: _from is not our client");
        require(!IAuthCenter(authCenter).isAddressFrozen(_from), "AuERC20: _from is frozen");
        require(IAuthCenter(authCenter).isClient(_to), "AuERC20: _to is not our client");
        require(!IAuthCenter(authCenter).isAddressFrozen(_to), "AuERC20: '_to' is frozen");
        require(_value >= 0, "AuERC20: transfer amount must be not negative");

        uint256 fromBalance = balances[_from];
        require(fromBalance >= _value, "AuERC20: transfer amount exceeds balance");

        uint256 currentAllowance = allowances[_from][msg.sender];
        if (IAuthCenter(authCenter).isAdmin(msg.sender)) currentAllowance = type(uint256).max;
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= _value, "AuERC20: insufficient allowance");
            currentAllowance -= _value;
            allowances[_from][msg.sender] = currentAllowance;
        }

        balances[_from] = fromBalance - _value;
        balances[_to] += _value;            

        emit Transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, currentAllowance);
        return true;
    }

    // @dev check contract paused 
    function isPaused() external view override returns (bool) {
        require(address(authCenter) != address(0), "AuERC20: AuthCenter is the zero address");
        return IAuthCenter(authCenter).isContractPaused(address(this));
    }

    // @dev create tokens to client
    function mint(address _to, uint256 _value) external override returns (bool) {
        require(authCenter != address(0), "AuERC20: AuthCenter is the zero address");
        require(IAuthCenter(authCenter).isAdmin(msg.sender), "AuERC20: You are not admin");
        totalTokenSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    // @dev burn client's tokens
    function burn(address _address, uint256 _value) external override returns (bool) {
        require(authCenter != address(0), "AuERC20: AuthCenter is the zero address");
        require((_address == msg.sender && !IAuthCenter(authCenter).isContractPaused(address(this))) ||
                IAuthCenter(authCenter).isAdmin(msg.sender), "AuERC20: You can't burn tokens");
        require(_value >= 0, "AuERC20: burn amount must be not negative");
        uint256 addressBalance = balances[_address];
        require(addressBalance >= _value, "AuERC20: burn balance have not so much tokens");

        balances[_address] = addressBalance - _value;
        totalTokenSupply -= _value;
        
        emit Transfer(_address, address(0), _value);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAuthCenter {
    event UpdateOwner(address indexed _address);
    event AddAdmin(address indexed _address);
    event DiscardAdmin(address indexed _address);
    event FreezeAddress(address indexed _address);
    event UnFreezeAddress(address indexed _address);
    event AddClient(address indexed _address);
    event RemoveClient(address indexed _address);
    event ContractPausedState(address indexed _address, bool _value);

    function addAdmin(address _address) external returns (bool);
    function discardAdmin(address _address) external returns (bool);
    function freezeAddress(address _address) external returns (bool);
    function unfreezeAddress(address _address) external returns (bool);
    function addClient(address _address) external returns (bool);
    function removeClient(address _address) external returns (bool);
    function isClient(address _address) external view returns (bool);
    function isAdmin(address _address) external view returns (bool);
    function isAddressFrozen(address _address) external view returns (bool);
    function setContractPaused(address _address) external returns (bool);
    function setContractUnpaused(address _address) external returns (bool);
    function isContractPaused(address _address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAuERC20 {
    event UpdateOwner(address indexed _address);
    
    /**
    * @dev Emitted when value tokens are moved from one account (from) to another (to).
    */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**    
    * Emitted when the allowance of a spender for an owner is set by a call to approve.
    * value is the new allowance.
    */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // some gas ethers need for a normal work of this contract (change owner at least).
    // Only owner can put ethers to contract.
    // Only owner can return to himself gas ethers before closing contract
    function withDrawAll() external;

    // @dev Link AuthCenter to contract
    function setAuthCenter(address _address) external returns (bool);

    // @dev set tokens name and symbol
    function setTokenInfo(string memory _tokenName, string memory _tokenSymbol) external returns (bool);

    // @dev Returns the name of the token.
    function name() external view returns (string memory);

    // @dev Returns the symbol of the token.
    function symbol() external view returns (string memory);

    // @dev Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);
    
    // @dev Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    // @dev Returns the amount of tokens owned by `account`.
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     * Requirements:
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _to, uint256 _value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _daddy, address _spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits an {Approval} event.
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _value) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism.
     `amount` is then deducted from the caller's allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     * Emits an {Approval} event indicating the updated allowance.
     * NOTE: Does not update the allowance if the current allowance is the maximum `uint256`.
     * Requirements:
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least `amount`.
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    // @dev check contract paused
    function isPaused() external view returns (bool);

    /**
     * @dev create tokens to client
     * generate Transfer event from address(0) to '_to'
     * NOTE: only admins can mint tokens
     */
    function mint(address _to, uint256 _value) external returns (bool);

    /**
     * @dev burn client's tokens
     * generate Transfer event from _address to address(0)
     * NOTE: only admins and owner can burn tokens
     */
    function burn(address _address, uint256 _value) external returns (bool);
}