/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



abstract contract Ownable is Context {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract TokensVesting is Ownable {

    using SafeMath for uint256;

    event NewVest(address indexed _from, address indexed _to, uint256 _value);
    event UnlockVest(address indexed _holder, uint256 _value);

    struct Vest {
        uint256 value;
        uint256 transferred;
        uint256 vestCount;
        uint256 nextvest;
    }
    mapping(address => Vest) public vests;
    address[] public vesters;

    uint256[] public unlockSequence = [25,15,10,50];    //unlock percentage sequence
    uint256 public phaseSequence = 18000;  //3 * 30 days;         //3 months of phase sequence

    uint256 public startTime;
    uint256 public firstUnlock;                         //first unlock after that the phase adjust on auto.

    address public crowdsaleAddress;
    uint256 public totalVesting;

    IERC20 public Carbon12;

    modifier onlyCrowdsale() {
        require(_msgSender() == crowdsaleAddress);
        _;
    }

    constructor(address _token) {
        require(
            _token != address(0),
            "TokenVestings: invalid zero address for token provided"
        );
        Carbon12 = IERC20(_token);
    }


    function vest(
        address _to,
        uint256 _value
    ) public onlyCrowdsale {
        require(
            _to != address(0),
            "TokensVesting: invalid zero address for beneficiary!"
        );
        require(startTime != 0, "TokensVesting: Vesting Not Started Yet!");
        require(_value > 0, "TokensVesting: invalid value for beneficiary!");
        
        if (vests[_to].value == 0) {
            vests[_to] = Vest({
                value: 0,
                transferred: 0,
                vestCount: 0,
                nextvest: firstUnlock     
            });
            vesters.push(_to);
        }

        vests[_to].value += _value;

        totalVesting = totalVesting.add(_value);

        emit NewVest(_msgSender(), _to, _value);
    }

    function unlock() public {
        require(startTime != 0, "TokensVesting: Vesting Not Started Yet!");
        Vest storage vested = vests[_msgSender()];
        require(vested.value != 0,"Error: No Record Found!!");
        require(block.timestamp >= vested.nextvest,"Error: Cann't Unlock the Token Now!!");

        uint percentage = unlockSequence[vested.vestCount];
        uint transferable = ( vested.value * percentage ) / 100;

        if(vested.transferred >= vested.value) {
            revert("Error: All Token Unlocked!!");
        }

        vested.nextvest += phaseSequence;
        vested.vestCount++;
        
        vested.transferred += transferable;
        totalVesting = totalVesting.sub(transferable);
        
        Carbon12.transfer(_msgSender(), transferable);

        emit UnlockVest(_msgSender(), transferable);

    }

    //add vesting record from private sale
    function addVestor(address[] calldata _address, uint256[] calldata _tokens) public onlyOwner {
        require(startTime != 0, "TokensVesting: Vesting Not Started Yet!");
        require(_address.length == _tokens.length,"Length Mismatch!!");
        
        uint Subtokens;
        address account = msg.sender;

        for(uint i=0; i < _tokens.length; i++){
            require(_tokens[i] != 0,"Invalid Token Amount!!");
            Subtokens += _tokens[i];
        }

        Carbon12.transferFrom(account,address(this),Subtokens);

        for (uint j=0; j < _address.length; j++) {

            require(_address[j] != address(0),"Invalid Address!!");  

            address _to = _address[j]; 
            uint _value = _tokens[j];   
            
            if (vests[_to].value == 0) {
                vests[_to] = Vest({
                    value: 0,
                    transferred: 0,
                    vestCount: 0,
                    nextvest: firstUnlock     
                });
                vesters.push(_to);
            }

            vests[_to].value += _value;

            totalVesting = totalVesting.add(_value);

            emit NewVest(_msgSender(), _to, _value);
        } 
    }

    function setCrowdsaleAddress(address _crowdsaleAddress) public onlyOwner {
        require(
            _crowdsaleAddress != address(0),
            "TokenVestings: invalid zero address for crowdsale"
        );
        crowdsaleAddress = _crowdsaleAddress;
    }

    function startTheVesting(uint256 _firstUnlock) public onlyCrowdsale {
        require(startTime == 0, "TokensVesting: already started!");
        startTime = block.timestamp;
        firstUnlock = _firstUnlock;     //1670428762;    //unix time 7 dec 2022
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getUnlockToken(address account) public view returns (uint256){
        
        if(vests[account].value == 0) return 0;
        if(block.timestamp < vests[account].nextvest) return 0;

        uint percentage = unlockSequence[vests[account].vestCount];
        uint transferable = ( vests[account].value * percentage ) / 100;  
        if(vests[account].transferred >= vests[account].value) {
            return 0;
        }

        return transferable;
    }

    function totalVestor() public view returns (uint) {
        return vesters.length;
    }

}