/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-16
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Auth {
    address public owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract Defire is Auth {
    using SafeMath for *;

    uint16 public refPercent = 150;
    uint16 public percentDivider = 1_000;

    struct UserData {
        uint256 totalDeposits;
        uint256 totalDepositAmount;
        mapping(uint8 => bool) pkgBought;
        mapping(uint8 => PkgData) personalMatrix;
    }

    struct PkgData {
        uint256 id;
        address referrer;
        uint256 refBonus;
        uint256 downlineCount;
        address[] directs;
        mapping(uint8 => uint256[]) refLevels;
        uint256 reinvestCount;
    }

    mapping(uint8 => mapping(uint256 => address)) public idToAdress;
    mapping(uint8 => uint256) public pkgPrice;
    mapping(uint8 => uint256) public lastId;
    mapping(address => UserData) public users;

    constructor() Auth(msg.sender) {}

    function buyPackage(uint8 _pkg, address _referrer) public payable {
        require(msg.value >= pkgPrice[_pkg], "Invalid amount");
        require(!users[msg.sender].pkgBought[_pkg], "Already bought");
        if(_referrer == msg.sender){
            _referrer = owner;
        }
        UserData storage user = users[msg.sender];
        user.totalDeposits++;
        user.totalDepositAmount += msg.value;
        user.pkgBought[_pkg] = true;
        updatePersonalMatrix(msg.sender, _referrer, _pkg);
    }

    function updatePersonalMatrix(
        address _user,
        address _referrer,
        uint8 _pkg
    ) internal {
        PkgData storage user = users[_user].personalMatrix[_pkg];
        PkgData storage ref = users[_referrer].personalMatrix[_pkg];
        user.id = ++lastId[_pkg];
        idToAdress[_pkg][user.id] = _user;
        user.referrer = _referrer;
        ref.directs.push(_user);

        if (ref.refLevels[1].length < 3) {
            updateUpline(_referrer, user.id, _pkg, 1);
        } else if (ref.refLevels[2].length < 9) {
            updateUpline(_referrer, user.id, _pkg, 2);
            updateDownline(_referrer, user.id, _pkg, 1, 3);
        } else if (ref.refLevels[3].length < 27) {
            updateUpline(_referrer, user.id, _pkg, 3);
            updateDownline(_referrer, user.id, _pkg, 2, 9);
        } else if (ref.refLevels[4].length < 81) {
            updateUpline(_referrer, user.id, _pkg, 4);
            updateDownline(_referrer, user.id, _pkg, 3, 27);
        } else if (ref.refLevels[5].length < 243) {
            updateUpline(_referrer, user.id, _pkg, 5);
            updateDownline(_referrer, user.id, _pkg, 4, 81);
        }
    }

    function updateUpline(
        address _referrer,
        uint256 _userId,
        uint8 _pkg,
        uint8 _from
    ) internal {
        address upline = _referrer;
        for (uint8 i = _from; i <= 5; i++) {
            if (upline == address(0)) {
                break;
            }
            users[upline].personalMatrix[_pkg].refLevels[i].push(_userId);
            users[upline].personalMatrix[_pkg].refBonus += pkgPrice[_pkg]
                .mul(refPercent)
                .div(percentDivider);
            users[upline].personalMatrix[_pkg].downlineCount++;
            upline = users[upline].personalMatrix[_pkg].referrer;
        }
    }

    function updateDownline(
        address _referrer,
        uint256 _userId,
        uint8 _pkg,
        uint8 _lvl,
        uint8 _length
    ) internal {
        for (uint8 i = 0; i < _length; i++) {
            PkgData storage ref = users[_referrer].personalMatrix[_pkg];
            address downline = idToAdress[_pkg][ref.refLevels[_lvl][i]];
            if (users[downline].personalMatrix[_pkg].refLevels[1].length < 3) {
                users[downline].personalMatrix[_pkg].refLevels[1].push(_userId);
                users[downline].personalMatrix[_pkg].refBonus += pkgPrice[_pkg]
                    .mul(refPercent)
                    .div(percentDivider);
                users[downline].personalMatrix[_pkg].downlineCount++;
                break;
            }
        }
    }

    function claimRewrad(uint8 _pkg) public {
        PkgData storage user = users[msg.sender].personalMatrix[_pkg];
        payable(msg.sender).transfer(user.refBonus);
    }

    function setPkgPrice(uint8 _pkg, uint256 _price) external onlyOwner {
        pkgPrice[_pkg] = _price;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getUserPkgData(address _user, uint8 _pkg)
        public
        view
        returns (
            uint256 id,
            address referrer,
            uint256 refBonus,
            uint256 downlineCount
        )
    {
        PkgData storage user = users[_user].personalMatrix[_pkg];
        id = user.id;
        referrer = user.referrer;
        refBonus = user.refBonus;
        downlineCount = user.downlineCount;
    }

    function getUserPkgDownline(
        address _user,
        uint8 _pkg,
        uint8 _lvl,
        uint256 _index
    ) public view returns (uint256 userId) {
        userId = users[_user].personalMatrix[_pkg].refLevels[_lvl][_index];
    }

    function getUserPkgDownlineLength(
        address _user,
        uint8 _pkg,
        uint8 _lvl
    ) public view returns (uint256 lvlLength) {
        lvlLength = users[_user].personalMatrix[_pkg].refLevels[_lvl].length;
    }

    function getUserPkgDirects(
        address _user,
        uint8 _pkg,
        uint8 _index
    ) public view returns (address downline) {
        downline = users[_user].personalMatrix[_pkg].directs[_index];
    }
    function getPersonalMatrix(address _referrer,  uint8 _pkg, uint8 refsAt) public view returns(
        uint256 id,
        address referrer,
        uint256 refBonus,
        uint256 downlineCount,
        uint256 directs,
        uint256 refLevels,
        uint256 reinvestCount
    ) {
        PkgData storage ref = users[_referrer].personalMatrix[_pkg];
        id = ref.id;
        referrer = ref.referrer;
        refBonus = ref.refBonus;
        downlineCount = ref.downlineCount;
        directs = ref.directs.length;
        refLevels = ref.refLevels[refsAt].length;
        reinvestCount = ref.reinvestCount;
    }

    function getUserPkgDirectsLength(address _user, uint8 _pkg)
        public
        view
        returns (uint256 length)
    {
        length = users[_user].personalMatrix[_pkg].directs.length;
    }

    function isPkgBought(address _user, uint8 _pkg) public view returns (bool) {
        return users[_user].pkgBought[_pkg];
    }
}