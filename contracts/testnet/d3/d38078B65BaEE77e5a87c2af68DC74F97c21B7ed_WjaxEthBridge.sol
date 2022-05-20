// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IWJAX {
  function mint(address, uint) external;
  function burn(uint) external;
  function transferFrom(address, address, uint) external;
}

contract WjaxEthBridge {

  uint chainId;
  
  uint public fee_percent = 5e5; // 0.5 %
  uint public minimum_fee_amount = 50; // 50 wjax

  address public admin;

  uint public penalty_amount = 0;

  address public penalty_wallet;

  IWJAX public wjax = IWJAX(0xb02801F6d0A76751a60881d2EA027eE0Eb9a99b9);

  struct Request {
    uint srcChainId;
    uint destChainId;
    uint amount;
    uint fee_amount;
    address to;
    uint deposit_timestamp;
    bytes32 depositHash;
  }

  Request[] public requests;

  mapping(address => uint[]) public user_requests;

  address[] public bridge_operators;
  mapping(address => uint) operating_limits;

  mapping(bytes32 => bool) proccessed_deposit_hashes;
  mapping(bytes32 => bool) proccessed_tx_hashes;

  event Deposit(uint indexed request_id, bytes32 indexed depositHash, address indexed to, uint amount, uint fee_amount, uint64 srcChainId, uint64 destChainId, uint128 deposit_timestamp);
  event Release(
    uint indexed request_id, 
    bytes32 indexed depositHash, 
    address indexed to, 
    uint deposited_amount, 
    uint fee_amount,
    uint released_amount, 
    uint64 srcChainId, 
    uint64 destChainId, 
    uint128 deposit_timestamp, 
    string txHash
  );
  event Reject_Request(uint request_id);
  event Set_Fee(uint fee_percent, uint minimum_fee_amount);
  event Set_Operating_Limit(address operator, uint operating_limit);
  event Set_Penalty_Wallet(address wallet);
  event Set_Admin(address admin);
  event Delete_Deposit_Addresses(uint[] ids);
  event Add_Penalty_Amount(uint amount, bytes32 info_hash);
  event Subtract_Penalty_Amount(uint amount, bytes32 info_hash);

  constructor() {
    admin = msg.sender;
    uint _chainId;
    assembly {
        _chainId := chainid()
    }
    chainId = _chainId;
    penalty_wallet = msg.sender;
  }

  modifier onlyAdmin() {
    require(admin == msg.sender, "Only Admin can perform this operation.");
    _;
  }

  modifier onlyOperator() {
    require(isBridgeOperator(msg.sender), "Not a bridge operator");
    _;
  }

  function deposit(uint destChainId, uint amount) external {
    require(amount >= minimum_fee_amount, "Minimum amount");
    require(chainId != destChainId, "Invalid Destnation network");
    uint request_id = requests.length;
    uint fee_amount = amount * fee_percent / 1e8;
    if(fee_amount < minimum_fee_amount) fee_amount = minimum_fee_amount;
    bytes32 depositHash = keccak256(abi.encodePacked(request_id, msg.sender, chainId, destChainId, amount, fee_amount, block.timestamp));
    Request memory request = Request({
      srcChainId: chainId,
      destChainId: destChainId,
      amount: amount,
      fee_amount: fee_amount,
      to: msg.sender,
      deposit_timestamp: block.timestamp,
      depositHash: depositHash
    });
    requests.push(request);
    wjax.transferFrom(msg.sender, address(this), amount);
    wjax.burn(amount);
    emit Deposit(request_id, depositHash, msg.sender, amount, fee_amount, uint64(chainId), uint64(destChainId), uint128(block.timestamp));
  }

  function release(
    uint request_id,
    address to,
    uint srcChainId,
    uint destChainId,
    uint amount,
    uint fee_amount,
    uint deposit_timestamp,
    bytes32 depositHash,
    string calldata txHash
  ) external onlyOperator {
    require( destChainId == chainId, "Incorrect destination network" );
    require( depositHash == keccak256(abi.encodePacked(request_id, to, srcChainId, chainId, amount, fee_amount, deposit_timestamp)), "Incorrect deposit hash");
    bytes32 _txHash = keccak256(abi.encodePacked(txHash));
    require( proccessed_deposit_hashes[depositHash] == false && proccessed_tx_hashes[_txHash] == false, "Already processed" );
    wjax.mint(to, amount - fee_amount);
    if(penalty_amount > 0) {
      if(penalty_amount > fee_amount) {
        wjax.mint(penalty_wallet, fee_amount);
        penalty_amount -= fee_amount;
      }
      else {
        wjax.mint(penalty_wallet, penalty_amount);
        wjax.mint(msg.sender, fee_amount - penalty_amount);
        penalty_amount -= penalty_amount;
      }
    }
    else {
      wjax.mint(msg.sender, fee_amount);
    }
    operating_limits[msg.sender] -= amount;
    proccessed_deposit_hashes[depositHash] = true;
    proccessed_tx_hashes[_txHash] = true;
    emit Release(request_id, depositHash, to, amount, fee_amount, amount - fee_amount, uint64(srcChainId), uint64(destChainId), uint128(deposit_timestamp), txHash);
  }

  function add_bridge_operator(address operator, uint operating_limit) external onlyAdmin {
    for(uint i = 0; i < bridge_operators.length; i += 1) {
      if(bridge_operators[i] == operator)
        revert("Already exists");
    }
    bridge_operators.push(operator);
    operating_limits[operator] = operating_limit;
  }

  function isBridgeOperator(address operator) public view returns(bool) {
    uint i = 0;
    for(; i < bridge_operators.length; i += 1) {
      if(bridge_operators[i] == operator)
        return true;
    } 
    return false;
  }

  function set_operating_limit(address operator, uint operating_limit) external onlyAdmin {
    require(isBridgeOperator(operator), "Not a bridge operator");
    operating_limits[operator] = operating_limit;
    emit Set_Operating_Limit(operator, operating_limit);
  }

  function set_fee(uint _fee_percent, uint _minimum_fee_amount) external onlyAdmin {
    fee_percent = _fee_percent;
    minimum_fee_amount = _minimum_fee_amount;
    emit Set_Fee(_fee_percent, _minimum_fee_amount);
  }

  function set_penalty_wallet(address _penalty_wallet) external onlyAdmin {
    penalty_wallet = _penalty_wallet;
    emit Set_Penalty_Wallet(_penalty_wallet);
  }

  function set_admin(address _admin) external onlyAdmin {
    admin = _admin;
    emit Set_Admin(_admin);
  }

  function add_penalty_amount(uint amount, bytes32 info_hash) external onlyAdmin {
    penalty_amount += amount;
    emit Add_Penalty_Amount(amount, info_hash);
  }

  function subtract_penalty_amount(uint amount, bytes32 info_hash) external onlyAdmin {
    require(penalty_amount >= amount, "over penalty amount");
    emit Subtract_Penalty_Amount(amount, info_hash);
  }
}