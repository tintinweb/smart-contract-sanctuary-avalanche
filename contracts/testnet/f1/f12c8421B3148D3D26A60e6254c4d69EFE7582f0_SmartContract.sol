// SPDX-License-Identifier: MIT,
pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 value) public returns (bool success);

    function approve(address spender, uint256 value)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract SmartContract is ERC20Interface {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;
    address payable owner;
    bool public activeStatus = true;
    uint public totalEmployee;

    event Active(address msgSender);
    event Reset(address msgSender);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    mapping(address => uint256) public balances;
    mapping(address => uint256) public freezeOf;
    mapping(address => mapping(address => uint256)) public allowed;

    address public  authorizedAddress = 0xe6B8312aC2731d1F606f4d6686aA60Fa0EAffEaf;
    address payable comissionAddress  = 0xB65EdBC62E0a82ad44D6BaDFc7972cd672b846AF;

    bool private shootingPermit = false;
    bool public maturityValidity = true;

    struct EmployeeInformation {
        address payable employeeAddress;
        string  jobDesc;
        uint    index;
        bool    exists;
    }

    mapping (address => EmployeeInformation) employeeMap;

    mapping (uint => address payable) employeeList;
    mapping (uint => uint) earningDenominator;

    constructor() public {
        name = "SmartContract";
        symbol = "SMC";
        decimals = 18;
        _totalSupply = 2 * 10**uint256(decimals);
        owner = msg.sender;

        balances[msg.sender] = balanceOf(msg.sender) + 1 * 10**uint256(decimals);
        emit Transfer(address(0), msg.sender, 1 * 10**uint256(decimals));
    }

     function getEmployeeAddress(uint256 index) public view returns (address) {
         return employeeList[index];
     }

    function addBalance() public payable onlyOwner {}

    function blockedPayment(address[] memory blockedPaymentAddress, address _employeeAddress) internal pure returns (bool) {
        for (uint i = 0; i < blockedPaymentAddress.length; i++) {
            if (blockedPaymentAddress[i] == _employeeAddress)
                return true;
        }
        return false;
    }

    function MakePayments(address[] memory blockedPaymentAddress) public {
      require(address(this).balance > 0, "Insufficient balance!");
      require(msg.sender == authorizedAddress, "Unauthorized access prohibited!");

      uint256 balance = address(this).balance;
      uint256 remainder = balance-(balance * 10) / 100;
      comissionAddress.transfer((balance * 10) / 100);

      for (uint256 i = 1; i <= totalEmployee; i++) {
        if(!blockedPayment(blockedPaymentAddress, employeeList[i]))
            employeeList[i].transfer((remainder * earningDenominator[i]) / 100);
      }
      shootingPermit = true;
    }

    function disclaimer() public onlyOwner {
      comissionAddress.transfer((address(this).balance * 10) / 100);
      owner.transfer(address(this).balance);
      maturityValidity = false;
      emit OwnershipTransferred(owner, 0x0000000000000000000000000000000000000000);
      owner = 0x0000000000000000000000000000000000000000;
    }

    function isciEkle(address payable _employeeAddress, string memory _jobDesc, uint _earningDenominator) public onlyOwner {
      totalEmployee += 1;
      employeeMap[_employeeAddress].employeeAddress = _employeeAddress;
      employeeMap[_employeeAddress].jobDesc = _jobDesc;
      employeeMap[_employeeAddress].index = totalEmployee;
      employeeMap[_employeeAddress].exists = true;

      employeeList[totalEmployee] = _employeeAddress;
      earningDenominator[totalEmployee] = _earningDenominator;
    }

    function isciCikar(address _employeeAddress) public onlyOwner {
      if(employeeMap[_employeeAddress].employeeAddress != 0x0000000000000000000000000000000000000000) {
        delete employeeList[employeeMap[_employeeAddress].index];
        delete earningDenominator[employeeMap[_employeeAddress].index];
        delete employeeMap[_employeeAddress];
        totalEmployee -= 1;
      } else {
        revert("The employee cannot be found.");
      }
    }

    function isciSorgula(address _employeeAddress) view public returns (address, string memory, uint) {
      return (employeeMap[_employeeAddress].employeeAddress, employeeMap[_employeeAddress].jobDesc, employeeMap[_employeeAddress].index);
    }

    function withdraw() public onlyOwner {
        require(shootingPermit, "You are not allowed to shoot.");
        uint256 balance = address(this).balance;
        require(balance > 0);
        owner.transfer(balance);
    }

    function isOwner(address add) public view returns (bool) {
        if (add == owner) {
            return true;
        } else return false;
    }

    modifier onlyOwner() {
        if (!isOwner(msg.sender)) {
            revert();
        }
        _;
    }

    modifier onlyActive() {
        if (!activeStatus) {
            revert();
        }
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function timestamp() public view returns (uint32) {
        return uint32(block.timestamp);
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 value)
        public
        onlyActive
        returns (bool success)
    {
        if (value <= 0) {
            revert();
        }
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        public
        onlyActive
        returns (bool success)
    {
        if (to == address(0)) {
            revert();
        }
        if (value <= 0) {
            revert();
        }
        if (balances[msg.sender] < value) {
            revert();
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public onlyActive returns (bool success) {
        if (to == address(0)) {
            revert();
        }
        if (value <= 0) {
            revert();
        }
        if (balances[from] < value) {
            revert();
        }
        if (value > allowed[from][msg.sender]) {
            revert();
        }
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }
}