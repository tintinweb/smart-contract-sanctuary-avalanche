//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IFeeReceiver {
    function trigger() external;
}

contract xWalrus is IERC20, Ownable {

    using SafeMath for uint256;

    // total supply
    uint256 private _totalSupply;

    // token data
    string private constant _name = 'xWalrus';
    string private constant _symbol = 'XWLRS';
    uint8  private constant _decimals = 18;

    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Amount Burned and Minted
    uint256 public totalBurned;
    uint256 public totalMinted;
    uint256 public totalWalrus;

    // Fee Recipients
    address public feeRecipient;

    // Trigger Fee Recipients
    bool public triggerRecipient = true;

    // Walrus Token Address
    address public constant walrus = 0x395908aeb53d33A9B8ac35e148E9805D34A555D3;

    // Scale Factor
    uint256 public scaleFactor = 2500;
    uint256 public constant denominator = 10**5;

    // Whether Or Not xWalrus Mint Rate Reduces As Supply Is Burned
    bool public haveRateDynamicByTokenSupply = false;
    
    // events
    event SetFeeRecipient(address recipient);
    event SetAutoTrigger(bool autoTrigger);

    constructor() {
        emit Transfer(address(0), msg.sender, 0);
    }

    /////////////////////////////////
    /////    ERC20 FUNCTIONS    /////
    /////////////////////////////////

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        return _transferFrom(sender, recipient, amount);
    }


    /////////////////////////////////
    /////   PUBLIC FUNCTIONS    /////
    /////////////////////////////////

    function burn(uint256 amount) external returns (bool) {
        return _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        _allowances[account][msg.sender] = _allowances[account][msg.sender].sub(amount, 'Insufficient Allowance');
        return _burn(account, amount);
    }

    function trigger() public {
        require(feeRecipient != address(0), 'Zero Receiver');
        IFeeReceiver(feeRecipient).trigger();
    }

    function mint(uint256 amountWalrus) external {
        
        // take walrus to mint
        uint256 received = _takeWalrus(amountWalrus);

        // amount to mint
        uint256 amountToMint = scaledAmountOut(received);
        require(
            amountToMint > 0,
            'Zero To Mint'
        );

        // increment total walrus
        unchecked { 
            totalWalrus += received;
        }

        // trigger receiver
        trigger();

        // mint amount to sender
        _mint(msg.sender, amountToMint);
    }

    function scaledAmountOut(uint256 amount) public view returns (uint256) {
        return scale(amountOut(amount));
    }

    function amountOut(uint256 amount) public view returns (uint256) {
        return ( ( amount * 10**18 ) / redeemRate() );
    }

    function scale(uint amount) public view returns (uint256) {
        uint scalar = ( amount * scaleFactor ) / denominator;
        return amount - scalar;
    }

    function redeemRate() public view returns (uint256) {
        if (totalMinted == 0 || totalWalrus == 0 || _totalSupply == 0) {
            return 10**18;
        }

        // average total supply and total minted amount
        uint denom = haveRateDynamicByTokenSupply ? _totalSupply : totalMinted;

        // totalWalrusReceived / averaged minted
        return ( totalWalrus * 10**18 ) / denom;
    }

    /////////////////////////////////
    /////    OWNER FUNCTIONS    /////
    /////////////////////////////////

    function withdraw(address token) external onlyOwner {
        require(token != address(0), 'Zero Address');
        bool s = IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }

    function withdrawBNB() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), 'Zero Address');
        feeRecipient = recipient;
        emit SetFeeRecipient(recipient);
    }

    function setAutoTriggers(
        bool triggerReceiver
    ) external onlyOwner {
        triggerRecipient = triggerReceiver;
        emit SetAutoTrigger(triggerReceiver);
    }

    function setScaleFactor(uint newFactor) external onlyOwner {
        require(
            newFactor <= denominator / 2,
            'Factor Too Large'
        );
        scaleFactor = newFactor;
    }

    function setHaveRateDynamicByTokenSupply(bool haveDynamicRate) external onlyOwner {
        haveRateDynamicByTokenSupply = haveDynamicRate;
    }

    //////////////////////////////////
    /////   INTERNAL FUNCTIONS   /////
    //////////////////////////////////

    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(
            recipient != address(0),
            'Zero Recipient'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            amount <= balanceOf(sender),
            'Insufficient Balance'
        );
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _burn(address account, uint256 amount) internal returns (bool) {
        require(
            account != address(0),
            'Zero Address'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            amount <= balanceOf(account),
            'Insufficient Balance'
        );

        // delete from balance and supply
        _balances[account] = _balances[account].sub(amount, 'Balance Underflow');
        _totalSupply = _totalSupply.sub(amount, 'Supply Underflow');

        // increment total burned
        unchecked {
            totalBurned += amount;
        }

        // emit transfer
        emit Transfer(account, address(0), amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal returns (bool) {
        require(
            account != address(0),
            'Zero Address'
        );
        require(
            amount > 0,
            'Zero Amount'
        );

        // delete from balance and supply
        _balances[account] += amount;
        _totalSupply += amount;

        // increment total burned
        unchecked {
            totalMinted += amount;
        }

        // emit transfer
        emit Transfer(address(0), account, amount);
        return true;
    }

    function _takeWalrus(uint256 amount) internal returns (uint256) {
        // ensure allowance is preserved
        require(
            IERC20(walrus).allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );

        // transfer in Walrus
        uint before = IERC20(walrus).balanceOf(feeRecipient);
        IERC20(walrus).transferFrom(msg.sender, feeRecipient, amount);
        uint After = IERC20(walrus).balanceOf(feeRecipient);
        require(
            After > before,
            'Zero Received'
        );

        // verify amount received
        return After - before;
    }
}