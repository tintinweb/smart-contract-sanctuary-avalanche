// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract OverrideMatrix is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant SETENV_ROLE = keccak256("SETENV_ROLE");
    bytes32 public constant REMOVE_ROLE = keccak256("REMOVE_ROLE");
    bytes32 public constant INIT_ROLE = keccak256("INIT_ROLE");
    bytes32 public constant ENTRY_ROLE = keccak256("ENTRY_ROLE");

    struct matrix6 {
        address vertex;
        address upper;
        address[2] upperLayer;
        address[4] lowerLayer;
        uint256 amount;
        bool isReVote;
    }

    struct matrix3 {
        address vertex;
        address[3] upperLayer;
        uint256 amount;
        bool isReVote;
    }

    struct accountInfo {
        bool isRegister;
        address referRecommender;
        uint256 currentMaxGrade;
        mapping(uint256 => bool) gradeExist;
        mapping(uint256 => matrix6) matrix6Grade;
        mapping(uint256 => matrix3) matrix3Grade;
        mapping(uint256 => bool) isPauseAutoNewGrant;
        mapping(uint256 => bool) isPauseAutoReVote;
    }

    mapping(address => accountInfo) private accountInfoList;

    address public noReferPlatform;
    address public feePlatform;
    uint256 public maxAuto = 20;
    uint256 public baseRewardRate = 1e18;
    uint256 public baseLocationPrice = 5e6;
    uint256 public basePlatformRate = 25e4;

    IERC20 public USDToken;
    IERC20 public Token1;
    IERC20 public Token2;

    uint256 public constant maxGrade = 12;
    uint256 private rate = 1e6;
    uint256 private perAutoTimes = 0;

    event NewLocationEvent(
        address indexed account,
        address indexed location,
        uint256 grade,
        uint256 index
    );
        
    event TokenTransferEvent(
        address indexed account,
        uint256 flag,
        uint256 grade
    );

    event ExceptEvent(uint256 setLocation, address indexed account);

    constructor(address _usdt, address _token1, address _token2, address _noReferPlatform, address _feePlatform, address _initAcc) {
        // 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2
        _grantRole(DEFAULT_ADMIN_ROLE, 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2);
        // 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2
        _grantRole(SETENV_ROLE, 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2);
        // 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2
        _grantRole(REMOVE_ROLE, 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2);
        // 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2
        _grantRole(INIT_ROLE, 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2);
        // 0x50A30c6dE1dE43B7eB5be8774Db8bac45f3007A3
        _grantRole(ENTRY_ROLE, 0x3bD653E6617E14DE9b1D397B746055A0283499ff);


        USDToken = IERC20(_usdt); // 
        Token1 = IERC20(_token1); // 
        Token2 = IERC20(_token2); // 
        noReferPlatform = _noReferPlatform; // 
        feePlatform = _feePlatform;  // 

        accountInfoList[_initAcc].isRegister = true; // 
    }

    function refer(address _refer) public {
        require(
            accountInfoList[_refer].referRecommender != _msgSender() &&
            accountInfoList[_msgSender()].referRecommender == address(0) &&
            _refer != address(0),
            "param account error"
        );
        require(accountInfoList[_refer].isRegister, "refer not registered");
        accountInfoList[_msgSender()].isRegister = true;
        accountInfoList[_msgSender()].referRecommender = _refer;
    }

    function newLocation(uint256 newGrade) public {
        require(newGrade > 0 && newGrade <= maxGrade, "param newGrade error");
        _newLocation(_msgSender(), newGrade);
        perAutoTimes = 0;
    }

    function openAutoGrade(uint256 grade) public {
        require(accountInfoList[_msgSender()].isPauseAutoNewGrant[grade], "already open AutoGrade");
        require(grade > 0 && grade < maxGrade, "param grade error");
        require(accountInfoList[_msgSender()].gradeExist[grade], "grade not exist");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            require(accountInfoList[_msgSender()].matrix3Grade[grade].upperLayer[0] == address(0), "not close");
        } else {
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[1] == address(0), "not close");
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[2] == address(0), "not close");
        }
        accountInfoList[_msgSender()].isPauseAutoNewGrant[grade] = false;
    }

    function closeAutoGrade(uint256 grade) public {
        require(!accountInfoList[_msgSender()].isPauseAutoNewGrant[grade], "already close AutoGrade");
        require(grade > 0 && grade < maxGrade, "param grade error");
        require(accountInfoList[_msgSender()].gradeExist[grade], "grade not exist");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            require(accountInfoList[_msgSender()].matrix3Grade[grade].upperLayer[0] == address(0), "not close");
        } else {
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[1] == address(0), "not close");
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[2] == address(0), "not close");
        }
        accountInfoList[_msgSender()].isPauseAutoNewGrant[grade] = true;
    }

    function openAutoVote(uint256 grade) public {
        require(accountInfoList[_msgSender()].isPauseAutoReVote[grade], "already open AutoVote");
        require(grade > 0 && grade < maxGrade && accountInfoList[_msgSender()].gradeExist[grade], "param grade error");
        accountInfoList[_msgSender()].isPauseAutoReVote[grade] = false;
    }

    function closeAutoVote(uint256 grade) public {
        require(!accountInfoList[_msgSender()].isPauseAutoReVote[grade], "already close AutoVote");
        accountInfoList[_msgSender()].isPauseAutoReVote[grade] = true;
    }

    function setBasePrice(uint256 amount) public onlyRole(SETENV_ROLE) {
        baseLocationPrice = amount;
    }

    function setMaxAuto(uint256 max) public onlyRole(SETENV_ROLE) {
        maxAuto = max;
    }

    function setBasePlatformRate(uint256 newRate) public onlyRole(SETENV_ROLE) {
        basePlatformRate = newRate;
    }

    function setNoReferPlatform(address platform) public onlyRole(SETENV_ROLE) {
        noReferPlatform = platform;
    }

    function setFeePlatform(address platform) public onlyRole(SETENV_ROLE) {
        feePlatform = platform;
    }

    function removeLiquidity(address token, address account, uint256 amount) public onlyRole(REMOVE_ROLE) {
        IERC20(token).transfer(account, amount);
    }

    function _newLocation(address _account, uint256 _newGrade) internal {
        require(!accountInfoList[_account].gradeExist[_newGrade], "this grade already exists");
        require(accountInfoList[_account].currentMaxGrade.add(1) >= _newGrade, "new grade is more than the current");
        require(accountInfoList[_account].isRegister, "account must has recommender");
        uint256 price = currentPrice(_newGrade);
        USDToken.transferFrom(_account, address(this), price);
        uint256 tmpPrice = price.mul(baseRewardRate).div(rate);
        if (Token1.balanceOf(address(this)) > 0) {
            if (Token1.balanceOf(address(this)) < tmpPrice && Token1.balanceOf(address(this)) > 0) {
                tmpPrice = Token1.balanceOf(address(this));             
            }
            Token1.transfer(_account, tmpPrice);            
        }
        emit TokenTransferEvent(_account, 1, _newGrade);
    
        _addLocations(_account, accountInfoList[_account].referRecommender, _newGrade);
    }

    function _addLocations(address _account, address _vertex, uint256 _newGrade) internal {
        uint256 types = matrixMember(_newGrade);
        if (_vertex != address(0)) {
            if (!accountInfoList[_vertex].gradeExist[_newGrade]) {
                _vertex = address(0);
                USDToken.transfer(noReferPlatform, currentPrice(_newGrade));
                accountInfoList[_account].gradeExist[_newGrade] = true;
                if (accountInfoList[_account].currentMaxGrade < _newGrade) {
                    accountInfoList[_account].currentMaxGrade = _newGrade;
                }
                return;
            }
        } else {
            USDToken.transfer(noReferPlatform, currentPrice(_newGrade));
            accountInfoList[_account].gradeExist[_newGrade] = true;
            if (accountInfoList[_account].currentMaxGrade < _newGrade) {
                accountInfoList[_account].currentMaxGrade = _newGrade;
            }
            return;
        }
        if (types == 6) {
            if (_vertex != address(0)) {
                _addLocationsTo6(_account, _vertex, _newGrade);
            }
        }
        if (types == 3) {
            accountInfoList[_account].matrix3Grade[_newGrade].vertex = _vertex;
            if (_vertex != address(0)) {
                _addLocationsTo3(_account, _vertex, _newGrade);
            }
        }
        accountInfoList[_account].gradeExist[_newGrade] = true;
        if (accountInfoList[_account].currentMaxGrade < _newGrade) {
            accountInfoList[_account].currentMaxGrade = _newGrade;
        }
    }

    function _addLocationsTo6(address _account, address _vertex, uint256 _grade) internal {
        if (accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0] == address(0) ||
            accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[1] == address(0)) {
            if (accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                _set6Location(_vertex, _account, _grade, 0);
            } else {
                _set6Location(_vertex, _account, _grade, 1);
            }
        } else {
            for (uint256 i = 0; i < 4; i++) {
                if (accountInfoList[_vertex].matrix6Grade[_grade].lowerLayer[i] == address(0)) {
                    if (i == 0 || i == 1) {
                        address upper = accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0];
                        if (i == 0) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                                _set6Location(upper, _account, _grade, 0);
                            }
                        }
                        if (i == 1) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[1] == address(0)) {
                                _set6Location(upper, _account, _grade, 1);
                            }
                        }
                    } else {
                        address upper = accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[1];
                        if (i == 2) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                                _set6Location(upper, _account, _grade, 0);
                            }
                        }
                        if (i == 3) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[1] == address(0)) {
                                _set6Location(upper, _account, _grade, 1);
                            }
                        }
                    }
                    return;
                }
            }
        }
    }

    function _addLocationsTo3(address _account, address _vertex, uint256 _grade) internal {
        if (!accountInfoList[_vertex].gradeExist[_grade]) {
            USDToken.transfer(noReferPlatform, currentPrice(_grade));
        } else {
            for (uint256 i = 0; i < 3; i++) {
                if (accountInfoList[_vertex].matrix3Grade[_grade].upperLayer[i] == address(0)) {
                    _set3Location(_vertex, _account, _grade, i);
                    return;
                }
            }
        }
    }

    function _set6Location(address _setKey, address _setValue, uint256 _setGrade, uint256 _setLocation) internal {
        if (_setLocation == 0) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0] = _setValue;
            if (accountInfoList[_setKey].matrix6Grade[_setGrade].upper != address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = accountInfoList[_setKey].matrix6Grade[_setGrade].upper;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            } else {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            }
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper != address(0)) {
                if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[1] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[2] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 4);
                    }
                } else if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[0] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[0] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 2);
                    }
                }
            } else {
                emit ExceptEvent(_setLocation, accountInfoList[_setValue].matrix6Grade[_setGrade].upper);
            }
            if (
                accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].vertex == address(0)
            ) {
                USDToken.transfer(noReferPlatform, currentPrice(_setGrade));
            } else {
                emit ExceptEvent(_setLocation, accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].vertex);
            }
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 1);
            return;
        }
        if (_setLocation == 1) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1] = _setValue;
            if (accountInfoList[_setKey].matrix6Grade[_setGrade].upper != address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = accountInfoList[_setKey].matrix6Grade[_setGrade].upper;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            } else {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            }
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper != address(0)) {
                if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[1] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[3] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 5);
                    }
                } else if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[0] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[1] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 3);
                    }
                }
            } else {
                emit ExceptEvent(_setLocation, accountInfoList[_setValue].matrix6Grade[_setGrade].upper);
            }
            if (
                accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].vertex == address(0)
            ) {
                USDToken.transfer(noReferPlatform, currentPrice(_setGrade));
            } else {
                emit ExceptEvent(_setLocation, accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].vertex);
            }
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 2);
            return;
        }
        if (_setLocation == 2) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[0] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[0] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 0);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 3);
            USDToken.transfer(_setKey, currentPrice(_setGrade));
            return;
        }
        if (_setLocation == 3) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[1] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[1] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 1);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 4);
            _should6AutoNewGrant(_setKey, _setGrade);
            _should6AutoReVote(_setKey, _setGrade);
            return;
        }
        if (_setLocation == 4) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[2] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[0] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 0);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 5);
            _should6AutoNewGrant(_setKey, _setGrade);
            return;
        }
        if (_setLocation == 5) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[3] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[1] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 1);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 6);
            _should6AutoReVote(_setKey, _setGrade);
            return;
        }
    }

    function _set3Location(address _setKey, address _setValue, uint256 _setGrade, uint256 _setLocation) internal {
        accountInfoList[_setKey].matrix3Grade[_setGrade].upperLayer[_setLocation] = _setValue;
        emit NewLocationEvent(_setValue, _setKey, _setGrade, _setLocation.add(1));
        if (_setLocation == 0) {
            _should3AutoNewGrant(_setKey, _setGrade);
        }
        if (_setLocation == 1) {
            _should3AutoNewGrant(_setKey, _setGrade);
        }
        if (_setLocation == 2) {
            _should3AutoReVote(_setKey, _setGrade);
        }
    }

    function _should6AutoNewGrant(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        
        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (accountInfoList[_account].matrix6Grade[_grade].isReVote) {
                USDToken.transfer(_account, price);
                return;
            }

            if (accountInfoList[_account].matrix6Grade[_grade].amount == 0) {
                USDToken.transfer(_account, price);
                return;
            }

            if (
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0) &&
                accountInfoList[_account].matrix6Grade[_grade].amount != 0
            ) {
                if (accountInfoList[_account].matrix6Grade[_grade].amount != 1) {
                    price = price.add(accountInfoList[_account].matrix6Grade[_grade].amount);
                    accountInfoList[_account].matrix6Grade[_grade].amount = 1;
                    USDToken.transfer(_account, price);
                    return;
                }
                transferPlatform(_account, price);
                return;
            }
        }

        if (
            accountInfoList[_account].currentMaxGrade >= _grade.add(1) &&
            accountInfoList[_account].isPauseAutoNewGrant[_grade]
            ) {
                uint256 price = currentPrice(_grade);
                if (accountInfoList[_account].matrix6Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    if (accountInfoList[_account].matrix6Grade[_grade].amount != 1) {
                        price = price.add(accountInfoList[_account].matrix6Grade[_grade].amount);
                        accountInfoList[_account].matrix6Grade[_grade].amount = 1;
                    }
                    transferPlatform(_account, price);
                }
                return;
        }
        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                if (accountInfoList[_account].matrix6Grade[_grade].amount == 0) {
                    transferPlatform(_account, price);
                } else {
                    if (accountInfoList[_account].matrix6Grade[_grade].amount != 1) {
                        price = price.add(accountInfoList[_account].matrix6Grade[_grade].amount);
                        accountInfoList[_account].matrix6Grade[_grade].amount = 1;
                    }
                    USDToken.transfer(_account, price);
                }
            } else {
                if (accountInfoList[_account].matrix6Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    transferPlatform(_account, price);   
                }
            }
            return;
        } else {
            if (
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0)
            ) {
                if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    uint256 tmpPrice = currentPrice(_grade.add(1)).mul(baseRewardRate).div(rate);
                    if (Token1.balanceOf(address(this)) > 0) {
                        if (Token1.balanceOf(address(this)) < tmpPrice && Token1.balanceOf(address(this)) > 0) {                       
                            tmpPrice = Token1.balanceOf(address(this));                       
                        }
                        Token1.transfer(_account, tmpPrice);   
                    }
                    emit TokenTransferEvent(_account, 1, _grade.add(1));

                    perAutoTimes++;
                    address vertex = accountInfoList[_account].referRecommender;
                    if (!accountInfoList[vertex].gradeExist[_grade.add(1)]) {
                        vertex = address(0);
                    }
                    _addLocations(_account, vertex, _grade.add(1));
                } else {
                    uint256 price = currentPrice(_grade);
                    transferPlatform(_account, price);
                }
            } else {
                if (accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    uint256 price = currentPrice(_grade);
                    transferPlatform(_account, price);
                } else {
                    accountInfoList[_account].matrix6Grade[_grade].amount = currentPrice(_grade);
                }
            }
        }
    }

    function _should6AutoReVote(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[0] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[3] != address(0)
        ) {
            accountInfoList[_account].matrix6Grade[_grade].isReVote = true;
            if (!accountInfoList[_account].isPauseAutoReVote[_grade]) {
                uint256 tmpPrice = currentPrice(_grade).mul(baseRewardRate).div(rate);
                if (Token2.balanceOf(address(this)) > 0) {
                    if (Token2.balanceOf(address(this)) < tmpPrice && Token2.balanceOf(address(this)) > 0) {
                        tmpPrice = Token2.balanceOf(address(this));  
                    }
                    Token2.transfer(_account, tmpPrice);
                }
                emit TokenTransferEvent(_account, 2, _grade);

                perAutoTimes++;
                address recommender = accountInfoList[_account].referRecommender;
                if (accountInfoList[recommender].gradeExist[_grade]) {
                    _addLocations(_account, recommender, _grade);
                } else {
                    _addLocations(_account, address(0), _grade);
                }
                resetAccount6Matrix(_account, _grade);            
            } else {
                uint256 price = currentPrice(_grade);
                transferPlatform(_account, price);
                accountInfoList[_account].gradeExist[_grade] = false;
                resetAccount6Matrix(_account, _grade);
            }
        }
    }

    function _should3AutoNewGrant(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (_grade == maxGrade) {
            uint256 price = currentPrice(maxGrade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                USDToken.transfer(_account, price);
            } else {
                transferPlatform(_account, price);
            }
            return;
        }

        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (accountInfoList[_account].matrix3Grade[_grade].isReVote) {
                USDToken.transfer(_account, price);
                return;
            }

            if (accountInfoList[_account].matrix3Grade[_grade].amount == 0) {
                USDToken.transfer(_account, price);
                return;
            }

            if (
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0) &&
                accountInfoList[_account].matrix3Grade[_grade].amount != 0
            ) {
                if (accountInfoList[_account].matrix3Grade[_grade].amount != 1) {
                    price = price.add(accountInfoList[_account].matrix3Grade[_grade].amount);
                    accountInfoList[_account].matrix3Grade[_grade].amount = 1;
                    USDToken.transfer(_account, price);
                    return;
                }
                transferPlatform(_account, price);
                return;
            }
        }

        if (
            accountInfoList[_account].currentMaxGrade >= _grade.add(1) &&
            accountInfoList[_account].isPauseAutoNewGrant[_grade]
            ) {
                uint256 price = currentPrice(_grade);
                if (accountInfoList[_account].matrix3Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    if (accountInfoList[_account].matrix3Grade[_grade].amount != 1) {
                        price = price.add(accountInfoList[_account].matrix3Grade[_grade].amount);
                        accountInfoList[_account].matrix3Grade[_grade].amount = 1;
                    }
                    transferPlatform(_account, price);
                }
                return;
        }

        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                if (accountInfoList[_account].matrix3Grade[_grade].amount == 0) {
                    transferPlatform(_account, price);
                } else {
                    if (accountInfoList[_account].matrix3Grade[_grade].amount != 1) {
                        price = price.add(accountInfoList[_account].matrix3Grade[_grade].amount);
                        accountInfoList[_account].matrix3Grade[_grade].amount = 1;
                    }
                    USDToken.transfer(_account, price);
                }
            } else {        
                if (accountInfoList[_account].matrix3Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    transferPlatform(_account, price); 
                }
            }
            return;
        } else {
            if (
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0)
            ) {
                if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    uint256 tmpPrice = currentPrice(_grade.add(1)).mul(baseRewardRate).div(rate);
                    if (Token1.balanceOf(address(this)) > 0) {
                        if (Token1.balanceOf(address(this)) < tmpPrice && Token1.balanceOf(address(this)) > 0) {
                            tmpPrice = Token1.balanceOf(address(this));  
                        }
                        Token1.transfer(_account, tmpPrice);
                    }
                    emit TokenTransferEvent(_account, 1, _grade.add(1));

                    perAutoTimes++;
                    address vertex = address(0);
                    if (accountInfoList[accountInfoList[_account].referRecommender].gradeExist[_grade.add(1)]) {
                        vertex = accountInfoList[_account].referRecommender;
                    }
                    _addLocations(_account, vertex, _grade.add(1));
                } else {
                    uint256 price = currentPrice(_grade);
                    transferPlatform(_account, price);
                }
            } else {
                if (accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    uint256 price = currentPrice(_grade);
                    transferPlatform(_account, price);
                } else {
                    accountInfoList[_account].matrix3Grade[_grade].amount = currentPrice(_grade);
                }
            }
        }
    }

    function _should3AutoReVote(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0) &&
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[2] != address(0)
        ) {
            accountInfoList[_account].matrix3Grade[_grade].isReVote = true;
            if (!accountInfoList[_account].isPauseAutoReVote[_grade]) {
                uint256 tmpPrice = currentPrice(_grade).mul(baseRewardRate).div(rate);
                if (Token2.balanceOf(address(this)) > 0) {
                    if (Token2.balanceOf(address(this)) < tmpPrice && Token2.balanceOf(address(this)) > 0) {
                        tmpPrice = Token2.balanceOf(address(this));                   
                    }
                    Token2.transfer(_account, tmpPrice);
                }
                emit TokenTransferEvent(_account, 2, _grade);

                perAutoTimes++;
                address recommender = accountInfoList[_account].referRecommender;
                if (accountInfoList[recommender].gradeExist[_grade]) {
                    _addLocations(_account, recommender, _grade);
                } else {
                    _addLocations(_account, address(0), _grade);
                }
                resetAccount3Matrix(_account, _grade);               
            } else {
                uint256 price = currentPrice(_grade);
                transferPlatform(_account, price);
                accountInfoList[_account].gradeExist[_grade] = false;
                resetAccount3Matrix(_account, _grade);
            }
        }
    }

    function transferPlatform(address _account,uint256 price) internal {
        uint256 platformRate = price.mul(basePlatformRate).div(rate);
        USDToken.transfer(feePlatform, platformRate);
        USDToken.transfer(_account, price.sub(platformRate));
    }

    function resetAccount6Matrix(address _account, uint256 _grade) internal {
        accountInfoList[_account].matrix6Grade[_grade].upperLayer[0] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].upperLayer[1] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[0] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[3] = address(0);
    }

    function resetAccount3Matrix(address _account, uint256 _grade) internal {
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] = address(0);
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] = address(0);
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[2] = address(0);
    }

    function matrixMember(uint256 _grade) internal pure returns (uint256) {
        require(_grade > 0 && _grade <= maxGrade, "error grade");
        if (_grade == 3 || _grade == 6 || _grade == 9 || _grade == maxGrade) {return 3;}
        return 6;
    }

    function currentPrice(uint256 _grade) public view returns (uint256) {
        return baseLocationPrice.mul(2 ** _grade.sub(1));
    }

    function accountGrade(address account, uint256 grade) public view returns (address[8] memory array) {
        require(account != address(0) && grade > 0 && grade <= maxGrade, "param error");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            array[0] = accountInfoList[account].matrix3Grade[grade].upperLayer[0];
            array[1] = accountInfoList[account].matrix3Grade[grade].upperLayer[1];
            array[2] = accountInfoList[account].matrix3Grade[grade].upperLayer[2];
            array[6] = accountInfoList[account].matrix3Grade[grade].vertex;
        }
        if (member == 6) {
            array[0] = accountInfoList[account].matrix6Grade[grade].upperLayer[0];
            array[1] = accountInfoList[account].matrix6Grade[grade].upperLayer[1];
            array[2] = accountInfoList[account].matrix6Grade[grade].lowerLayer[0];
            array[3] = accountInfoList[account].matrix6Grade[grade].lowerLayer[1];
            array[4] = accountInfoList[account].matrix6Grade[grade].lowerLayer[2];
            array[5] = accountInfoList[account].matrix6Grade[grade].lowerLayer[3];
            array[6] = accountInfoList[account].matrix6Grade[grade].vertex;
            array[7] = accountInfoList[account].matrix6Grade[grade].upper;           
        }
        return array;
    }

    function accInfo(address account, uint256 grade) public view returns (bool isPauseAutoNewGrant, bool isPauseAutoReVote) {
        return (accountInfoList[account].isPauseAutoNewGrant[grade], accountInfoList[account].isPauseAutoReVote[grade]);
    }

    function referRecommender(address account) public view returns (address) {
        return accountInfoList[account].referRecommender;
    }

    function latestGrade(address account) public view returns (uint256) {
        return accountInfoList[account].currentMaxGrade;
    }

    function accmatrixAmount(address account, uint256 grade) public view returns (uint256) {
        uint256 member = matrixMember(grade);
        if (member == 3) {
            return accountInfoList[account].matrix3Grade[grade].amount;
        } else {
            return accountInfoList[account].matrix6Grade[grade].amount;
        }   
    }

    function accmatrixReVote(address _account, uint256 _grade) public view returns (bool) {
        uint256 member = matrixMember(_grade);
        if (member == 3) {
            return accountInfoList[_account].matrix3Grade[_grade].isReVote;
        } else {
            return accountInfoList[_account].matrix6Grade[_grade].isReVote;
        }
    }

    function withdrawal(uint256 _grade) public {
        uint256 member = matrixMember(_grade);
        uint256 amount = 0;
        if (member == 3) {
            amount = accountInfoList[_msgSender()].matrix3Grade[_grade].amount;
            accountInfoList[_msgSender()].matrix3Grade[_grade].amount = 1;
        } else {
            amount = accountInfoList[_msgSender()].matrix6Grade[_grade].amount;
            accountInfoList[_msgSender()].matrix6Grade[_grade].amount = 1;
        }
        uint256 platformRate = amount.mul(basePlatformRate).div(rate);
        USDToken.transfer(feePlatform, platformRate);
        USDToken.transfer(_msgSender(), amount.sub(platformRate));
        accountInfoList[_msgSender()].isPauseAutoNewGrant[_grade] = true;
    }

    
    function accountRelationShip(address _account, address _refer, uint256 _currentMaxGrade) public onlyRole(ENTRY_ROLE) {
        _accountRelationShip(_account, _refer, _currentMaxGrade);
    }
    
    
    function _accountRelationShip(address _account, address _refer, uint256 _currentMaxGrade) internal {
        accountInfoList[_account].isRegister = true;
        accountInfoList[_account].referRecommender = _refer;
        accountInfoList[_account].currentMaxGrade = _currentMaxGrade;
        for (uint256 i = 1; i<=_currentMaxGrade; i++) {
            accountInfoList[_account].gradeExist[i] = true;
            if (i == _currentMaxGrade) {
                return;
            }
            uint256 member = matrixMember(i);
            if (member == 3) {
                accountInfoList[_account].matrix3Grade[i].isReVote = true;
            } else {
                accountInfoList[_account].matrix6Grade[i].isReVote = true;
            }
        }
    }

    function matrix3Setup(address _account, uint256 _grade, address _vertex, uint256 _amount) public onlyRole(ENTRY_ROLE) {
        _matrix3RelationShip(_account, _grade, _vertex, _amount);
    }
    
    function _matrix3RelationShip(address _account, uint256 _grade, address _vertex, uint256 _amount) internal {
        if (_vertex != address(0)) {
            accountInfoList[_account].matrix3Grade[_grade].vertex = _vertex;
        }
        accountInfoList[_account].matrix3Grade[_grade].amount = _amount;
    }

    function matrix3SetupSite(address _account, uint256 _grade, address _1, address _2, address _3) public onlyRole(ENTRY_ROLE) {
        _matrix3Site(_account, _grade, _1, _2, _3);
    }

    function _matrix3Site(address _account, uint256 _grade, address _1, address _2, address _3) internal {
        _matrix3Site(_account, _grade, 0, _1);
        _matrix3Site(_account, _grade, 1, _2);
        _matrix3Site(_account, _grade, 2, _3);
    }

    function _matrix3Site(address _account, uint256 _grade, uint256 _site, address _number) internal {
        if (_number != address(0)) {
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[_site] = _number;
        }
    }

    function matrix6SetupSite(address _account, uint256 _grade, address _1, address _2, address _3, address _4, address _5, address _6) public onlyRole(ENTRY_ROLE) {
        _matrix6Sites(_account, _grade, _1, _2, _3, _4, _5, _6);
    }

    function _matrix6Sites(address _account, uint256 _grade,address _1, address _2, address _3, address _4, address _5, address _6) internal {
        _matrix6Site(_account, _grade, true, 0, _1);
        _matrix6Site(_account, _grade, true, 1, _2);
        _matrix6Site(_account, _grade, false, 0, _3);
        _matrix6Site(_account, _grade, false, 1, _4);
        _matrix6Site(_account, _grade, false, 2, _5);
        _matrix6Site(_account, _grade, false, 3, _6);
    }

    function _matrix6Site(address _account, uint256 _grade, bool _isUp, uint256 _site, address _number) internal {
        if (_number != address(0)) {
            if (_isUp) {
                accountInfoList[_account].matrix6Grade[_grade].upperLayer[_site] = _number;
            } else {
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[_site] = _number;
            }       
        }
    }

    function matrix6Setup(address _account, uint256 _grade, address _vertex, address _upper, uint256 _amount) public onlyRole(ENTRY_ROLE) {
        _matrix6RelationShip(_account, _grade, _vertex, _upper, _amount);
    }

    function _matrix6RelationShip(address _account, uint256 _grade, address _vertex, address _upper, uint256 _amount) internal {
        if (_upper != address(0)) {
            accountInfoList[_account].matrix6Grade[_grade].upper = _upper;
        }
        if (_vertex != address(0)) {
            accountInfoList[_account].matrix6Grade[_grade].vertex = _vertex;
        }  
        accountInfoList[_account].matrix6Grade[_grade].amount = _amount;
    }
}