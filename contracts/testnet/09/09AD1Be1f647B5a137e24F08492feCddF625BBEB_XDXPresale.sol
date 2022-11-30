// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

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
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

  function decimals() external view returns (uint8);

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

contract XDXPresale is Ownable {
  // stable coin addresses
  address public immutable USDT;
  address public immutable USDC;
  address public immutable USDCE;
  address public immutable BUSD;
  address public immutable DAI;
  address public immutable XDX;

  // multisig wallet address
  address public multisig;

  // signer address
  address public immutable signer;

  // Price per XDX
  uint256 public pricePerXDX = 800;

  // Presale period
  uint32 public openingTime;
  uint32 public closingTime;

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  // buy XDX event
  event Buy(
    address indexed _executor,
    string indexed _tokenNameToDeposit,
    uint256 _deposit,
    uint256 _withdraw
  );

  // set Period event
  event SetPeriod(uint32 openingTime, uint32 closingTime);

  constructor(
    address _singer,
    address _multisig,
    address _USDT,
    address _USDC,
    address _USDCE,
    address _BUSD,
    address _DAI,
    address _XDX
  ) {
    require(_singer != address(0), "Invalid signer address");
    require(_multisig != address(0), "Invalid multisig address");
    require(_USDT != address(0), "Invalid USDT address");
    require(_USDC != address(0), "Invalid USDC address");
    require(_USDCE != address(0), "Invalid USDC.e address");
    require(_BUSD != address(0), "Invalid BUSD address");
    require(_DAI != address(0), "Invalid DAI address");
    require(_XDX != address(0), "Invalid XDX address");
    signer = _singer;
    multisig = _multisig;
    USDT = _USDT;
    USDC = _USDC;
    USDCE = _USDCE;
    BUSD = _BUSD;
    DAI = _DAI;
    XDX = _XDX;
  }

  function isOpen() public view returns (bool) {
    return block.timestamp >= openingTime && block.timestamp < closingTime;
  }

  // function:    validates buy function variables
  // @return    ture -> valid, false -> invalid
  function _isBuyParamValid(
    uint256 amountToDeposit,
    string memory tokenNameToDeposit,
    Sig calldata sig
  ) private view returns (bool) {
    bytes32 messageHash = keccak256(
      abi.encodePacked(_msgSender(), amountToDeposit, tokenNameToDeposit)
    );

    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    return signer == ecrecover(ethSignedMessageHash, sig.v, sig.r, sig.s);
  }

  // buy XDX with stable coin
  function buy(
    uint256 amountToDeposit,
    string memory tokenNameToDeposit,
    Sig calldata sig
  ) external returns (uint256 result) {
    require(isOpen(), "XDXPresale: Not open now");
    require(
      _isBuyParamValid(amountToDeposit, tokenNameToDeposit, sig),
      "XDXPresale: Invalid signature"
    );

    address tokenToDeposit;

    if (keccak256(abi.encodePacked(tokenNameToDeposit)) == keccak256(abi.encodePacked("USDT")))
      tokenToDeposit = USDT;
    else if (keccak256(abi.encodePacked(tokenNameToDeposit)) == keccak256(abi.encodePacked("USDC")))
      tokenToDeposit = USDC;
    else if (
      keccak256(abi.encodePacked(tokenNameToDeposit)) == keccak256(abi.encodePacked("USDCE"))
    ) tokenToDeposit = USDCE;
    else if (keccak256(abi.encodePacked(tokenNameToDeposit)) == keccak256(abi.encodePacked("BUSD")))
      tokenToDeposit = BUSD;
    else if (keccak256(abi.encodePacked(tokenNameToDeposit)) == keccak256(abi.encodePacked("DAI")))
      tokenToDeposit = DAI;
    else revert("XDXPresale: Incorrect deposit token");

    uint256 tokenDecimalToDeposit = IERC20(tokenToDeposit).decimals();
    uint256 multiplier = IERC20(XDX).decimals() - tokenDecimalToDeposit;
    uint256 currentAmountInUSD = (IERC20(XDX).balanceOf(_msgSender()) * pricePerXDX) /
      100 /
      (10**multiplier);

    require(
      amountToDeposit + currentAmountInUSD <= 1000 * (10**tokenDecimalToDeposit),
      "XDXPresale: Max deposit amount is $1000 per wallet"
    );

    uint256 _balance = balance();
    uint256 amountWithdrawalXDX = (amountToDeposit * (10**multiplier) * 100) / pricePerXDX;
    require(amountWithdrawalXDX <= _balance, "XDXPresale: Insufficient withdrawal amount");
    require(
      IERC20(tokenToDeposit).balanceOf(_msgSender()) >= amountToDeposit,
      "XDXPresale: Insufficient deposit balance"
    );

    IERC20(tokenToDeposit).transferFrom(_msgSender(), multisig, amountToDeposit);
    IERC20(XDX).transfer(_msgSender(), amountWithdrawalXDX);

    emit Buy(_msgSender(), tokenNameToDeposit, amountToDeposit, amountWithdrawalXDX);

    return amountWithdrawalXDX;
  }

  // balance of XDX
  function balance() public view returns (uint256) {
    return IERC20(XDX).balanceOf(address(this));
  }

  // set presale period
  function setPeriod(uint32 _openingTime, uint32 _closingTime) external onlyOwner {
    require(_closingTime > _openingTime, "XDXPresale: Invalid time window");
    openingTime = _openingTime;
    closingTime = _closingTime;

    emit SetPeriod(openingTime, closingTime);
  }

  // withdraw all XDX to another address
  function withdraw(address _recipient) external onlyOwner {
    uint256 _balance = balance();
    IERC20(XDX).transfer(_recipient, _balance);
  }

  // renounce price of XDX ($ per XDX)
  function renouncePrice(uint256 _priceXDX) external onlyOwner {
    require(_priceXDX > 0, "XDXPresale: Price must be greater than zero");
    pricePerXDX = _priceXDX;
  }

  // renounce multisig wallet address
  function renounceMultiSig(address _multisig) external onlyOwner {
    require(_multisig != address(0), "XDXPresale: Invalid address");
    multisig = _multisig;
  }
}