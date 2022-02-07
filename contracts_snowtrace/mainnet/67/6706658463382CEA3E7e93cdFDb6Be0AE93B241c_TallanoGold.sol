/**
 *Submitted for verification at snowtrace.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

contract TallanoGold is IERC20 {

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    string public ERR_INSUFF_BAL = "Insufficient balance.";
    string public ERR_INSUFF_ALL = "Insufficient allowance.";
    string public ERR_INSUFF_AMT = "Insufficient amount. Amount sent less than minimum value required for the sale.";
    string public ERR_CANNOT_BE_ZERO = "Value cannot be zero";
    string public name = "Tallano Gold";
    string public symbol = "TGB";

    /**
        first address is owner
        nested map are allowances of entities who can spend money on your behalf
    **/
    mapping(address => mapping(address => uint256)) public allowances; 
    mapping(address => uint256) public balances;
    mapping(address => uint256) public indices;
    
    address[] public holders;

    address owner;
    address zero = 0x3dcAa785A72037a8E356F9E966d162443B1dC49a; //Monji Personal
    address dexWallet = 0xe9745E03901d043c3Bed8CC31FA77dC631094b59; //1 chits1
    address corpAddress = 0x8c8F4F7eaAf3a1C4922B3cBE1Ef2520098f174ce; //2 chits2
    address devAddress = 0x41829071c24D207189331F0c1B86540243f153A5; //3 chits3
    address mWallet = 0x3F728642019b0b2397711F19c7ce202D1D31D009; //4 chits4
    
    uint256 public decimals = 18;
    // uint256 public override totalSupply = 1000000000 * 10 ** decimals; //1B CHITS
    uint256 public override totalSupply = 2000 * 10 ** decimals; //1B CHITS
    uint256 private constant MULTIPLIER = 1 * 10 ** 18;
    uint256 public rate = 0;
    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;
    uint256 public minAmount = 5 * 10 ** 17; //0.5 wei

    
    constructor() { //check feasib to later on add more tokens in circulation
        owner = msg.sender;

        //7 wallets in total

        balances[zero] = totalSupply * 4000 / 10000; //remainder to be put on the main wallet
        pushAndIndex(zero);

        balances[dexWallet] = totalSupply * 2400 / 10000; //remainder to be put on the main wallet
        pushAndIndex(zero);

        balances[corpAddress] = totalSupply * 2500 / 10000; //corp wallet\
        pushAndIndex(corpAddress);

        balances[devAddress] = totalSupply * 1000 / 10000; //john/dev wallet
        pushAndIndex(devAddress);

        balances[mWallet] = totalSupply * 100 / 10000; //separate dev wallet
        pushAndIndex(mWallet);

    }

    function buyChits(address beneficiary) public payable{
        uint256 weiAmount = msg.value;

        _preValidatePurchase(beneficiary, weiAmount);

        uint256 tokensToReceive = _getTokenAmount(weiAmount);
        weiRaised += weiAmount;
        tokensSold += tokensToReceive;

        _processPurchase(beneficiary, tokensToReceive);

        emit TokenPurchase(
            msg.sender,
            beneficiary,
            weiAmount,
            tokensToReceive
        );

        _updatePurchasingState(beneficiary, weiAmount);
        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
    * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _postValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
    {
        // optional override
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        require(balanceOf(zero) >= _tokenAmount, ERR_INSUFF_BAL);
        
        balances[_beneficiary] += _tokenAmount;
        balances[zero] -= _tokenAmount;

        pushAndIndex(_beneficiary);     
           
        emit Transfer(zero, _beneficiary, _tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
    * @param _beneficiary Address receiving the tokens
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
    {
        // optional override
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount)
        internal returns (uint256)
    {
        require(_weiAmount > 0, ERR_CANNOT_BE_ZERO);
        require(_weiAmount >= minAmount, ERR_INSUFF_AMT);
        return _weiAmount * _getRate();
    }

    function _getRate() public returns(uint256) {
        // if(balanceOf(zero) > 200000000 * 10 ** decimals) { 15:25 / 200:100
        if(balanceOf(zero) > 700 * 10 ** decimals) {
            return 200;
        }
        return 100;
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        payable(zero).transfer(msg.value);
    }

    receive() external payable {
        require(msg.value >= minAmount, ERR_INSUFF_AMT);
        buyChits(msg.sender);
    }

    fallback () external payable {
        require(msg.value >= minAmount, ERR_INSUFF_AMT);
        buyChits(msg.sender);
    }
 
    function balanceOf(address _owner) public view override returns(uint) {
        return balances[_owner];
    }
        
    /**
        address payable, smart contract can send ether to address
        function payable, addresses can send ether to the method/smart contract
    **/    
    function transfer(address to, uint value) external override returns(bool) {
        require(balanceOf(msg.sender) >= value, ERR_INSUFF_BAL);
        require(value >= 0, ERR_INSUFF_BAL);
        
        
        balances[to] += value;
        balances[msg.sender] -= value;

        pushAndIndex(to);     
           
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public override returns(bool) {
        require(balanceOf(from) >= value, ERR_INSUFF_BAL);
        require(allowances[from][msg.sender] >= value, ERR_INSUFF_ALL);

        balances[to] += value;
        balances[from] -= value;

        pushAndIndex(to);
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public override returns(bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return allowances[_owner][spender];
    }

    //here be dragons
    function pushAndIndex(address recipient) internal {
        // require(balances[recipient] <= 0, "Already in holders list.");//fix this require logic
        holders.push(recipient);
        indices[recipient] = holders.length - 1;
    }

    //here be dragons 
    //add this into the logic
    function deleteIfZeroBal(address _sender) internal {
        if (balances[_sender] <= 0) {
            holders[indices[_sender]] = holders[holders.length - 1];
            holders.pop();
        }
    }

}