/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-14
*/

pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
interface IDeployer{
        function deployProxy(address[] calldata _addresses,uint256[] calldata _values,bool[] memory _isSet,string[] memory _details) external returns (address);

}


contract Owned {
    address payable public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

contract PresaleProxy is Owned {
    using SafeMath for uint256;

    struct Sale{
        address _sale;
        uint256 _start;
        uint256 _end;
        string _name;
        address _usewithToken;
        bool _launchpadType;
        bool _isWhitelisted;
    }

    uint256 public depolymentFee = 0;
    uint256 public fee = 0;
    uint256 public userFee = 0;
    bool public checkForSuccess = true;  // Make False to Sale reaches soft cap to make it success

    address public fundReciever;

    address public implementation;
   

    mapping(address => address) public _preSale;
    mapping(address => uint256) public saleId;
    Sale[] public _sales;

    constructor() public{

    }

    function setImplemnetation(address _implemetation) public onlyOwner{
        implementation = _implemetation;
    }
 

    function getSale(address _token) public view returns (address) {
        return _preSale[_token];
    }

    function setDeploymentFee(uint256 _fee) external onlyOwner {
        depolymentFee = _fee;
    }

    function setForSuccess(bool _value) external onlyOwner {
       checkForSuccess = _value;
    }

    function setTokenFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }


    function getDeploymentFee() public view returns(uint256){
        return depolymentFee;
    }
 

    function setUserFee(uint256 _userfee) external onlyOwner {
        userFee = _userfee;
    }

    function getUserFee() public view returns(uint256){
        return userFee;
    } 
    function getfundReciever() public view returns (address){
        return fundReciever;
    }

    function setfundReciever(address _reciever) external onlyOwner {
        fundReciever = _reciever;
    }

    function getTokenFee() public view returns(uint256){
        return fee;
    }

    function getTotalSales() public view returns (Sale[] memory){
        return _sales;
    }

    function getCheckSuccess() public view returns (bool){
        return checkForSuccess;
    }


    function deleteSalePresale(address _saleAddress) public onlyOwner {
        uint256 _saleId = saleId[_saleAddress];
        _sales[_saleId] = _sales[_sales.length - 1];
        saleId[_sales[_sales.length - 1]._sale] = _saleId;
        _sales.pop();
    }

    function createPresale(address[] calldata _addresses,uint256[] calldata _values,bool[] memory _isSet,string[] memory _details) public payable {
          // _token 0
        //_router 1
        //owner 2
        // usewithToken 3 i.e buytoken 3
        
        //_min 0 
        //_max 1
        //_rate 2
        // _soft  3
        // _hard 4
        //_pancakeRate  5
        //_unlockon  6
        // _percent 7
        // _start 8
        //_end 9
        //_vestPercent 10
        //_vestInterval 11
        //_userFee 12

        // isAuto 0
        //_isvested 1
        // isWithoutToken 2
        // isWhitelisted 3
        // buyType isBNB or not 4
        // isToken isToken or not 5
        // LaunchpadType normal or fair 6

        // description 0 
        // website,twitter,telegram 1,2,3
        // logo 4
        // name 5
        // symbol 6
        // githup 7
        // instagram 8
        // discord 9
        // reddit 10
        // youtube 11

           require(depolymentFee == msg.value,"Insufficient fee");
           payable(fundReciever).transfer(msg.value);
         address _saleAddress = IDeployer(implementation).deployProxy(_addresses,_values,_isSet,_details);
           _preSale[_addresses[0]] = _saleAddress;
           saleId[_saleAddress] = _sales.length;
            _sales.push(
                Sale({
                    _sale: _saleAddress,
                    _start: _values[8],
                    _end: _values[9],
                    _name: _details[5],
                    _usewithToken : _addresses[3],
                    _launchpadType : _isSet[6],
                    _isWhitelisted : _isSet[3]

                })
            );
        
        
    }


}