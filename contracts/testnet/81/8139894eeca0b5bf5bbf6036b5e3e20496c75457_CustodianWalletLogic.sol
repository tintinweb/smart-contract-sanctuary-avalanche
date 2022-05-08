/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Factory {
  ////////////////////////////////////////
  //                                    //
  //         STATE VARIABLES            //
  //                                    //
  ////////////////////////////////////////

  /// @notice EOA of deployer wallet
  address public ochestrator;

  /// @notice the address of the Custodian Wallet Logic
  address public custodianWalletLogic;

  address public escrowContractAddress;

  /// @notice mapping of account unique id to custodian wallet
  /// Note avoid passing predictable number such as incremental number. Use UUID string instead
  mapping(string => address) public accounts;

  event NewCustodian(string uniqueId, address indexed account);

  ////////////////////////////////////////
  //                                    //
  //              FUNCTIONS             //
  //                                    //
  ////////////////////////////////////////
  modifier onlyOchesrator() {
    require(msg.sender == ochestrator, "F: only ochestrator");
    _;
  }

  constructor() {
    ochestrator = msg.sender;
    escrowContractAddress = address(new Escrow(msg.sender));
    custodianWalletLogic = address(new CustodianWalletLogic());
  }

  /**
   * @dev create a new custodian wallet
   * @param uuid is the unique id of the custodian wallet
   */
  function newCustodian(string memory uuid)
    public
    onlyOchesrator
    returns (string memory, address)
  {
    require(accounts[uuid] == address(0x0), "F: account exist");

    address wallet = address(
      new CustodianWalletProxy(custodianWalletLogic, ochestrator, address(this))
    );
    accounts[uuid] = wallet;

    emit NewCustodian(uuid, wallet);

    return (uuid, wallet);
  }
}

contract Types {
  /// @notice structure of an order
  struct Order {
    address seller;
    address buyer;
    address receiver;
    uint256 amount;
    uint256 rate;
    uint256 fee;
    uint8 orderType;
    uint8 orderStatus;
    uint256 startTime;
    uint256 fulfiledTime;
  }

  Order[] public orders;

  mapping(address => uint256[]) public openOrders;

  /// @notice 0 = BUY, 1 = SELL
  enum OrderType {
    BUY,
    SELL
  }

  enum OrderStatus {
    OPEN, // order is open
    FULFILLED, // order is fulfilled
    CANCELLED, // order is cancelled
    EXPIRED, // order is expired (not fulfilled)
    REJECTED, // order is rejected by seller
    REFUNDED // order is refunded to the seller
  }

  ////////////////////////////////////////
  //                                    //
  //              EVENTS                //
  //                                    //
  ////////////////////////////////////////

  event OpenOrder(
    uint256 orderId,
    address indexed seller,
    address indexed buyer,
    address indexed receiver,
    uint256 amount,
    uint256 rate,
    uint256 fee,
    uint8 orderType,
    uint8 orderStatus
  );

  event OrderFulfilled(uint256 orderId);

  event ClosedOrder(
    uint256 orderId,
    address indexed seller,
    address indexed buyer,
    address indexed receiver,
    uint256 amount,
    uint256 rate,
    uint256 fee,
    uint8 orderType,
    uint256 fulfiledTime,
    uint8 orderStatus
  );

  event RejectedOrder(uint256 orderId);

  event ApproveRejectedOrder(uint256 orderId);
}

contract CustodianWalletProxy is Types {
  /// @notice address of factory
  address public factory;

  /// @notice address of wallet logic to
  /// copy code from and call using delegatecall
  address public immutable logic;

  /// @notice address of escrow contract
  address public immutable ochestrator;

  /**
   * @param _logic address of already deployed Custodian Wallet that can receive upgrade
   * @param _ochestrator address of Escrow that can has sole control over all custodian wallets
   */
  constructor(
    address _logic,
    address _ochestrator,
    address _factory
  ) {
    ochestrator = _ochestrator;
    logic = _logic;
    factory = _factory;
  }

  // prettier-ignore
  /**
   * @dev Forward any call to any function with any set of parameters to the logic contract
   * without it needing to know anything in particular of the logic contract’s interface.
   *
   * Note By using this proxy approach we are able to upgrade the logic contract at any time and allow
   * already deployed proxy wallets benefit from new updates.
   *
   * Since msg.sender when calling Wallet Logic chnages to address(this) due to usage of delegate call
   * we are unable to determinable set a modifier on functions in Wallet Logic to limit calls to Escrow.
   * So we require that caller to all wallet proxies to call our wallet logic can only be escrow.
   *
   *
   * Credit to https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol
   */
  fallback() external payable {
    // solhint-disable-line no-complex-fallback

    require(msg.sender == ochestrator, "WP: deployer only");

    address _impl = logic;

    // This is never suppose to happen by any chance
    if (_impl == address(0)) {
      revert("Logic contract not set");
    }

    assembly {
      // solhint-disable-line no-inline-assembly
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  // ======== Receive =========

  receive() external payable {} // solhint-disable-line no-empty-blocks
}

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

contract Escrow is Types {
  ////////////////////////////////////////
  //                                    //
  //         STATE VARIABLES            //
  //                                    //
  ////////////////////////////////////////

  /// @notice EOA of deployer wallet
  address public ochestrator;

  /// @notice address of accepted USDC on deployed chain
  address public usdcToken;

  ////////////////////////////////////////
  //                                    //
  //              FUNCTIONS             //
  //                                    //
  ////////////////////////////////////////
  modifier onlyOchesrator() {
    require(msg.sender == ochestrator, "F: only ochestrator");
    _;
  }

  constructor(address _ochestrator) {
    ochestrator = _ochestrator;

    //Create default order on zero index
    Order memory order = Order(
      address(0x0), // seller
      address(0x0), // buyer
      address(0x0), // receiver
      0,
      0,
      0,
      0,
      1, // closed
      block.timestamp, // startTime
      block.timestamp // fulfilledTime
    );

    orders.push(order);
  }

  /**
   * @param _seller is the address of the vendor
   * @param _buyer is the address of the customer
   * @param _amount is the amount of USD to be transferred plus fees (18 decimals)
   * @param _rate is the rate to buy usdc against customer fiat
   * @param _fee is the amount of fees to be paid to the escrow to be minus from _amount (18 decimals)
   * @param _orderType is the type of order (0: buy, 1: sell)
   */
  function newOrder(
    address _seller,
    address _buyer,
    address _receiver,
    uint256 _amount,
    uint256 _rate,
    uint256 _fee,
    uint8 _orderType
  ) public returns (uint256) {
    require(msg.sender == _buyer, "C: customer only");
    require(_amount > 0, "C: invalid order");

    Order memory order = Order(
      _seller,
      _buyer,
      _receiver,
      _amount,
      _rate,
      _fee,
      _orderType,
      0, // open
      block.timestamp,
      0
    );

    orders.push(order);

    uint256 orderId = orders.length - 1;

    openOrders[_seller].push(orderId);

    emit OpenOrder(
      orderId,
      _seller,
      _buyer,
      _receiver,
      _amount,
      _rate,
      _fee,
      _orderType,
      0 // open
    );

    return orderId;
  }

  function numberOfOpenOrders(address _seller) public view returns (uint256) {
    return openOrders[_seller].length;
  }

  function getOpenOrdersOf(address _seller)
    public
    view
    returns (uint256[] memory)
  {
    return openOrders[_seller];
  }

  function getOrderById(uint256 _orderId) public view returns (Order memory) {
    return orders[_orderId];
  }

  function closeOpenOrder(address _seller, uint256 _orderIndex) public {
    require(msg.sender == _seller, "C: only seller");

    uint256 _orderId = openOrders[_seller][_orderIndex];

    delete openOrders[_seller][_orderIndex];

    Order storage order = orders[_orderId];

    order.fulfiledTime = block.timestamp;
    order.orderStatus = 1; // closed

    emit ClosedOrder(
      _orderId,
      order.seller,
      order.buyer,
      order.receiver,
      order.amount,
      order.rate,
      order.fee,
      order.orderType,
      order.fulfiledTime,
      order.orderStatus
    );
  }

  /**
   * @dev allow deployer to update of USD Token contract address
   * @param usdcContractAddress is the address of the chosen stabel currency to accepted
   * Note use with caution, once a certain USD token is accepted changing will make the other USD token stuck
   */
  function setUsdcTokenAddress(address usdcContractAddress)
    public
    onlyOchesrator
  {
    require(usdcContractAddress != address(0x0), "F: invalid address");
    usdcToken = usdcContractAddress;
  }

  /**
   * @dev allow deployer to withdraw all fees earned from escrow
   */
  function withdrawFeesEarned() public onlyOchesrator {
    uint256 totalFeeEarned = IERC20(usdcToken).balanceOf(address(this));

    IERC20(usdcToken).transfer(ochestrator, totalFeeEarned);
  }

  function rejectOrder(address _seller, uint256 _orderId) public {
    require(msg.sender == _seller, "C: only seller");

    Order storage order = orders[_orderId];

    order.orderStatus = 4; // rejected

    emit RejectedOrder(_orderId);
  }

  function consentOrderRejected(address _buyer, uint256 _orderIndex) public {
    require(msg.sender == _buyer, "C: only buyer");

    uint256 _orderId = openOrders[_buyer][_orderIndex];

    delete openOrders[_buyer][_orderIndex];

    emit ApproveRejectedOrder(_orderId);
  }
}


contract CustodianWalletLogic is Types {
  /// @notice address of factory
  address public factory;

  function getTotalBalance() external view returns (uint256) {
    return _getUsdcBalance();
  }

  function getOpenOrders() external view returns (uint256[] memory) {
    return _getOpenOrders();
  }

  function _getUsdcBalance() internal view returns (uint256) {
    return IERC20(_getEscrow().usdcToken()).balanceOf(msg.sender);
  }

  function _getEscrow() internal view returns (Escrow) {
    return Escrow(Factory(factory).escrowContractAddress());
  }

  /// @notice when a customer buy USD with local fiat
  function newBuyOrder(
    address _seller,
    address _receiver,
    uint256 _amount,
    uint256 _rate,
    uint256 _fee
  ) external returns (uint256) {
    address usdcAddress = _getEscrow().usdcToken();

    require(_seller != address(0x0), "CWL: seller not set");
    require(usdcAddress != address(0x0), "CWL: usdc token not set");

    require(
      IERC20(usdcAddress).balanceOf(_seller) >= _amount + _fee,
      "C: not enough USD"
    );

    return
      _getEscrow().newOrder(
        _seller, // vendor
        address(this),
        _receiver,
        _amount,
        _rate,
        _fee,
        0 // buy
      );
  }

  /// @notice when a customer sell USD for local fiat to vendor
  function newSellOrder(
    address _buyer,
    address _receiver,
    uint256 _amount,
    uint256 _rate,
    uint256 _fee
  ) external returns (uint256) {
    return
      _getEscrow().newOrder(
        address(this),
        _buyer, //vendor
        _receiver,
        _amount,
        _rate,
        _fee,
        1 // sell
      );
  }

  /// @notice returns operating balance of the seller custodian wallet (total USD balance - open orders against wallet)
  function availBalance() external view returns (uint256) {
    return _availBalance();
  }

  function _availBalance() internal view returns (uint256) {
    uint256[] memory openOrders = _getOpenOrders();
    uint256 balance = _getUsdcBalance();

    for (uint256 queue = 0; queue < (openOrders.length - 1); queue++) {
      Order memory order = _getEscrow().getOrderById(openOrders[queue]);
      balance -= order.amount; // subtract amount of open order
      balance -= order.fee; // subtract fee of open order
    }

    return balance;
  }

  function _getOpenOrders() internal view returns (uint256[] memory) {
    return _getEscrow().getOpenOrdersOf(address(this));
  }

  function approveOrder(uint256 _openOrderIndex) external {
    uint256[] memory openOrders = _getOpenOrders();

    require(openOrders.length > 0, "CWL: no open orders");
    uint256 _orderId = openOrders[_openOrderIndex];

    Order memory order = _getEscrow().getOrderById(_orderId);

    require(order.seller == address(this), "CWL: invalid order");

    _getEscrow().closeOpenOrder(address(this), _openOrderIndex);

    _sendFunds(order.receiver, order.amount, order.fee);

    emit OrderFulfilled(_orderId);
  }

  function rejectOrder(uint256 _orderId) external {
    Order memory order = _getEscrow().getOrderById(_orderId);

    require(order.seller == address(this), "CWL: only seller");

    _getEscrow().rejectOrder(address(this), _orderId);
  }

  function consentOrderRejected(uint256 _openOrderIndex) external {
    uint256[] memory openOrders = _getOpenOrders();

    uint256 _orderId = openOrders[_openOrderIndex];

    Order memory order = _getEscrow().getOrderById(_orderId);

    require(order.buyer == address(this), "CWL: only buyer");

    _getEscrow().consentOrderRejected(address(this), _openOrderIndex);
  }

  function _sendFunds(
    address _to,
    uint256 _amount,
    uint256 _fee
  ) internal {
    require(_to != address(this), "CWL: self forbidden");
    require(_to != address(0x0), "CWL: invalid to address");
    require(_amount > 0, "CWL: amount cannot equal 0");
    require(_availBalance() >= _amount, "CWL: insufficient funds");

    IERC20(_getEscrow().usdcToken()).transfer(_to, _amount);
    IERC20(_getEscrow().usdcToken()).transfer(address(_getEscrow()), _fee);
  }
}