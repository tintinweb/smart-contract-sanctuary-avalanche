/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-30
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/bridge.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Bridge {
    address public owner;
    address public bridgeAddress;
    IERC20 private token;
    uint public tokenCount = 1;

    struct Tokens {
        string name;
        address tokenAddress;
        string symbol;
        uint decimal;
    }

    event Log(address indexed sender, uint amount, uint tokenID, string tokenName);


    mapping(uint => Tokens) public supportedTokens;

    constructor(address _owner, address _bridgeAddress) {
        owner = _owner;
        bridgeAddress = _bridgeAddress;
    }

    function addSupportedToken(string memory _name, string memory _symbol, address _tokenAddress, uint _decimal) public onlyOwner {
        supportedTokens[tokenCount] = Tokens({
            name: _name,
            tokenAddress: _tokenAddress,
            symbol: _symbol,
            decimal: _decimal
        });
        tokenCount++;
    }

    function viewCount() public view returns(uint) {
        return tokenCount;
    }

    function viewSupportedToken(uint _tokenID) public view returns (Tokens memory) {
        return supportedTokens[_tokenID];
    }

    function approveToken(uint _amount, uint _tokenID) public {
        token = IERC20(supportedTokens[_tokenID].tokenAddress);
        token.approve(address(this), _amount);

    }


    function deposit(uint256 _amount,uint _tokenID) public {
        token = IERC20(supportedTokens[_tokenID].tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);
        emit Log(msg.sender, _amount, _tokenID,supportedTokens[_tokenID].name);
    }
    


    modifier onlyBridge() {
        require(msg.sender == bridgeAddress, "You should use Bridge");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }


}