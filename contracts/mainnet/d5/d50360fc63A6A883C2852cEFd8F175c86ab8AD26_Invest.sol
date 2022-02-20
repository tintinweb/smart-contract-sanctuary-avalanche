// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IERC20.sol";

contract Invest {

    address public owner;
    address public admin;
    address public coin;
    uint256 public MAXAMOUNT = 0;
    mapping(address => uint256) public amountPaid;
    mapping(address => bool) public whitelist;
    uint256[4] public lootBox;
    address[4] public tokens;
    uint256 public totalInvested;

    constructor(address _coin, uint256 _maxAmount, uint256 _rare, uint256 _epic, uint256 _legendary) {
        owner = msg.sender;
        admin = msg.sender;
        coin = _coin;
        MAXAMOUNT = _maxAmount;
        lootBox[0] = _rare;
        lootBox[1] = _epic;
        lootBox[2] = _legendary;
        // lootBox[3] = _cosmic;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    modifier onlyAdmin {
      require(msg.sender == admin);
      _;
    }

    modifier tokensSet{
        require(tokens[0] != address(0) && tokens[1] != address(0) && tokens[2] != address(0) && tokens[3] != address(0), "Tokens not set");
        _;
    }
    modifier isWhitelisted{
        require( whitelist[msg.sender], "whitelist only");
        _;
    }

    function setCoin (address _coin) external onlyOwner{
        coin = _coin;
    }

    function setOwner (address _owner) external onlyOwner{
        owner = _owner;
    }

    function setAdmin (address _admin) external onlyOwner{
        admin = _admin;
    }

    function setWhitelist (address[] memory _users) external onlyAdmin{
        for (uint256 _user = 0; _user < _users.length; _user++) {
            whitelist[_users[_user]] = true;            
        }
    }
    
    function removeWhitelist (address[] memory  _users) external onlyAdmin{
        for (uint256 _user = 0; _user < _users.length; _user++) {
            whitelist[_users[_user]] = false;            
        }
    }

    function setMaxAmount (uint256 _maxAmount) external onlyOwner{
        MAXAMOUNT = _maxAmount;
    }

    function setLootBoxValue(uint256 _rare, uint256 _epic, uint256 _legendary) external onlyOwner{
        lootBox[0] = _rare;
        lootBox[1] = _epic;
        lootBox[2] = _legendary;
        // lootBox[3] = _cosmic;
    }

    function setTokens(address _rare, address _epic, address _legendary, address _cosmic) external onlyOwner{
        require(_rare != address(0) && _epic != address(0) && _legendary != address(0) && _cosmic != address(0));
        tokens[0] = _rare;
        tokens[1] = _epic;
        tokens[2] = _legendary;
        tokens[3] = _cosmic;
    }

    function invest(uint256 _amount) external isWhitelisted tokensSet{
        require((amountPaid[msg.sender] + _amount) <= MAXAMOUNT,"MAX AMOUNT");
        uint256 allowance = IERC20(coin).allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        IERC20(coin).transferFrom(msg.sender, address(this), _amount);
        amountPaid[msg.sender] = amountPaid[msg.sender] + _amount;
        _mintToken(msg.sender, _amount);
        totalInvested += _amount;
    }

    function _mintToken(address _to, uint256 _amount) internal tokensSet{
        if(_amount < lootBox[0]){
            IERC20(tokens[0]).mint(_to, _amount);
        } else if(_amount < lootBox[1]){
            IERC20(tokens[1]).mint(_to, _amount);
        } else if(_amount < lootBox[2]){
            IERC20(tokens[2]).mint(_to, _amount);
        } else {
            IERC20(tokens[3]).mint(_to, _amount);
        }
    }

    function withdrawCoin() external onlyOwner{
        uint256 amount = IERC20(coin).balanceOf(address(this));
        IERC20(coin).transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

    function mint(address to, uint256 amount) external returns (bool);
}