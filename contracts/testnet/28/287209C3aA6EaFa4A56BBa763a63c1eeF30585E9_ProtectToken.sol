// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IProtectToken.sol";

contract ProtectToken is IProtectToken, Ownable {
    using SafeMath for uint256;

    uint256 public maxTokenTransfer = 1000000 * 10 ** 18;
    uint256 public maxTokenTransferForPartner = 1000 * 10 ** 18;
    mapping(address => bool) public sellAdress;
    uint256 public maxNumberTransferToday = 10000;
    uint256 public maxNumberTransferTodayForPartner = 3;
    bool public isCheckTransferToday = true;
    mapping(address => uint256) public timeTransfer;
    mapping(address => mapping(uint256 => uint256)) public numberTransferToday;
    mapping(address => mapping(uint256 => uint256)) public numberTransferTodayForPartner;

    function checkTransferToken(
        address sender,
        address recipient,
        uint256 amount,
        bool partner
    ) external override view returns (bool protect){
        if(sellAdress[sender] || !sellAdress[recipient] || (!sellAdress[sender] && !sellAdress[recipient])){
            return true;
        }

        if(amount > maxTokenTransfer || (partner && amount > maxTokenTransferForPartner)){
            return false;
        }
        if(!isCheckTransferToday){
            return true;
        }
        uint256 numberTransfer  = numberTransferToday[sender][timeTransfer[sender]];
        uint256 _numberTransferTodayForPartner = numberTransferTodayForPartner[sender][timeTransfer[sender]];
        if(checkToday(timeTransfer[sender]) == false){
            numberTransfer = 0;
            _numberTransferTodayForPartner = 0;
        }
        if(numberTransfer >= maxNumberTransferToday || (partner && _numberTransferTodayForPartner >= maxNumberTransferTodayForPartner)){
            return false;
        }
        return true;
    }

    function updateSecurety(address sender, address recipient, uint256 amount) public {
        if(isCheckTransferToday && checkSell(recipient)){
            if(!checkToday(timeTransfer[sender])){
                timeTransfer[sender] = block.timestamp;
            }
            numberTransferToday[sender][timeTransfer[sender]] += 1;
            numberTransferTodayForPartner[sender][timeTransfer[sender]] += 1;
        }
    }

    function checkSell(address sell) public view returns (bool _sell){
        return sellAdress[sell];
    }

    function checkToday(uint256 _time) public view returns (bool inDate) {
        //  (uint yearNow, uint monthNow, uint dayNow) = _daysToDate(block.timestamp / 86400);
        //  (uint yearCheck, uint monthCheck, uint dayCheck) = _daysToDate(_time / 86400);
        //
        //  if (yearNow == yearCheck && monthNow == monthCheck && dayNow == dayCheck) {
        //      return true;
        //  }
        uint256 timecheck = _time + 86400;
        if(timecheck >= block.timestamp){
            return true;
        }
        return false;
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + 2440588;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function setIsCheckTransferToday(bool _isCheckTransferToday) public onlyOwner {
        isCheckTransferToday = _isCheckTransferToday;
    }

    function changeMaxNumberTransferToday(uint256 _maxNumberTransferToday) public onlyOwner {
        maxNumberTransferToday = _maxNumberTransferToday;
    }

    function changeMaxNumberTransferTodayForPartner(uint256 _maxNumberTransferTodayForPartner) public onlyOwner {
        maxNumberTransferTodayForPartner = _maxNumberTransferTodayForPartner;
    }

    function changeMaxTokenTransfer(uint256 amount) public onlyOwner {
        maxTokenTransfer = amount;
    }

    function changeMaxTokenTransferPartner(uint256 amount) public onlyOwner {
        maxTokenTransferForPartner = amount;
    }

    function changeSellAddress(address[] memory sell, bool _active) public onlyOwner {
        for(uint256 index = 0; index < sell.length; index++) {
            sellAdress[sell[index]] = _active;
        }
    }
}