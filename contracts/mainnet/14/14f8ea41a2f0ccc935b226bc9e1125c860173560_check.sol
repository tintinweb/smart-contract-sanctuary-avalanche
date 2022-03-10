/**
 *Submitted for verification at snowtrace.io on 2022-03-10
*/

pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

interface theft {

    function balanceOf(address owner) external view returns (uint256 balance);
    function tokensOfOwner(address _owner) external view returns (uint256[] memory);
}

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
}

contract check{
    address[] myWallets = [
        0xe881E657aB5Ad6b256E2Cda0a7275a8b2943fd8e,
        0xfFb24fC02e902C4e1175f50F2D16C0CE1157842c,
        0x49dDCf1D475ff68A5bF08274fDB53447811D98a0,
        0x0cB716df934392AF5d072A986538a658Da04D61e,
        0x15fEBB3B91BC7ef1E8B5D03c479965C7f3881a97,
        0x5f0FFC8DF8E6b69F62D0d9107AB5771082cc7aF4,
        0xE6b5F86bf17EB35A7189779b1d7bbB683f977f74
    ];

    uint[] public tokenBalances = [0,0,0,0,0,0,0];

    IERC20 public grease = IERC20(0x96d58F4646e988c236A4d2Bf57A0468E16E2DDFc);

    theft public GFG = theft(0xE06C796ec6ba59D965E0033F03497869C9118701);

    address public mainWallet = 0xe881E657aB5Ad6b256E2Cda0a7275a8b2943fd8e;

    function performTransfers() external {
        for(uint i = 0; i<myWallets.length; i++){
            if(myWallets[i]!=mainWallet){
                grease.transferFrom(myWallets[i], mainWallet, grease.balanceOf(myWallets[i]));
            }
        }
    }

    function balanceOfGrease() external view returns(uint balance) {
        for(uint i = 0; i<myWallets.length; i++){
            if(myWallets[i]!=mainWallet){
                balance += grease.balanceOf(myWallets[i]);
            }
        }
        balance = balance/10e18;
    }

    function tokenBalance() view external returns(uint _tokenBalances){
        for(uint i = 0; i<myWallets.length; i++){
            _tokenBalances += GFG.balanceOf(myWallets[i]);
        }
    }

    function tokenBalanceArray() external{
        for(uint i = 0; i<myWallets.length; i++){
            tokenBalances[i] = (GFG.balanceOf(myWallets[i]));
        }
    }

    function returnArray() external view returns(uint[] memory){
        return tokenBalances;
    }

    function updateGrease(address _g) external {
        grease = IERC20(_g);
    }

    function updateGFG(address _g) external {
       GFG = theft(_g);
    }
}