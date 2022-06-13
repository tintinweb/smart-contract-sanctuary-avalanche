/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


/**
*
*    ██╗   ██╗███████╗███████╗ █████╗     ███████╗███████╗████████╗ █████╗ ████████╗███████╗
*    ██║   ██║██╔════╝██╔════╝██╔══██╗    ██╔════╝██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝
*    ██║   ██║█████╗  ███████╗███████║    █████╗  ███████╗   ██║   ███████║   ██║   █████╗  
*    ╚██╗ ██╔╝██╔══╝  ╚════██║██╔══██║    ██╔══╝  ╚════██║   ██║   ██╔══██║   ██║   ██╔══╝  
*     ╚████╔╝ ███████╗███████║██║  ██║    ███████╗███████║   ██║   ██║  ██║   ██║   ███████╗
*      ╚═══╝  ╚══════╝╚══════╝╚═╝  ╚═╝    ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝
*
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/*===================================================
    Vesa Estate Contract
=====================================================*/

contract VesaEstate is Context, Ownable {
    address usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public feeAddress;
    address public treasuryAddress;

    uint256 private feePercent = 500;
    uint256 private feeTVLPercent = 200;
    uint256 private feeTreasuryPercent = 300;
    uint256 private referralPercent = 500;

    uint256 public divisor = 10000;

    bool private initialized = false;

    struct ModuleConfig {
        uint256 price;          // module price
        uint256 rewardPercent;  // daily reward percent
    }

    ModuleConfig[] public moduleTypes;

    struct UserModule {
        uint256 moduleIndex;
        uint256 startTime;
    }

    struct User {
        UserModule[] modules;
        uint256 lastActionTime;
        uint256 leftReward;
		address referrer;
		uint256 refBonus;
		uint256 refCount;
	}

    mapping (address => User) private users;

    constructor(address _feeAddr, address _treasuryAddr) {
        feeAddress = _feeAddr;
        treasuryAddress = _treasuryAddr;

        createInitialModules();
    }
    
    /**
    * @notice Create 4 types of modules.
    * @dev Create 4 types of modules, function is called in contructor.
    */
    function createInitialModules() internal {
        addModule(150, 15);
        addModule(500, 75);
        addModule(750, 100);
        addModule(1000, 150);
    }

    /**
    * @notice Add module with price and reward percent.
    * @dev Add module config.
    * @param _price Module price.
    * @param _rewardPercent Daily reward percent of module.
    */
    function addModule(uint32 _price, uint256 _rewardPercent) public onlyOwner {
        require(
            _price > 0,
            "price must be greater than zero"
        );

        require(
            _rewardPercent > 0,
            "reward percent must be greater than zero"
        );

        moduleTypes.push(
            ModuleConfig({
                price: _price * 10**6,
                rewardPercent: _rewardPercent
            })
        );
    }

    /**
    * @notice Buy modules with rewards.
    * @dev Compound with rewards.
    */
    function compound(uint256 _index, address _ref) public {
        checkState();
        
        uint256 rewards = getRewards(msg.sender);
        uint256 amount = moduleTypes[_index].price;
        require(rewards >= amount, "err: not enough rewards");

        uint256 fee = amount * 2 / 100;
        // uint256 tvlfee = calculateTVLFee(amount);
        uint256 treasuryfee = amount * 2 / 100;
        ERC20(usdc).transfer(feeAddress, fee);
        ERC20(usdc).transfer(treasuryAddress, treasuryfee);

        // uint256 totalFee = fee + tvlfee + treasuryfee;
        users[msg.sender].leftReward = rewards - amount;
        users[msg.sender].lastActionTime = block.timestamp;

        users[msg.sender].modules.push(
            UserModule({
                moduleIndex: _index,
                startTime: block.timestamp
            })
        );

        if (_ref != address(0))
        {
            uint256 referralFee = amount * referralPercent / divisor;
            users[_ref].refBonus += referralFee;
        }
    }
    
    /**
    * @dev Collect rewards.
    */
    function collect() public {
        checkState();

        uint256 amount = getRewards(msg.sender);

        uint256 fee = calculateFee(amount);
        uint256 tvlfee = calculateTVLFee(amount);
        uint256 treasuryfee = calculateTreasuryFee(amount);
        ERC20(usdc).transfer(feeAddress, fee);
        ERC20(usdc).transfer(treasuryAddress, treasuryfee);
        
        uint256 totalFee = fee + tvlfee + treasuryfee;
        ERC20(usdc).transfer(address(msg.sender), amount - totalFee);
        
        users[msg.sender].lastActionTime = block.timestamp;
        users[msg.sender].leftReward = 0;
    }
    
    /**
    * @dev Invest on modules.
    */
    function invest(address _ref, uint256 _index) public {
        require(initialized, "err: not started");

        uint256 amount = moduleTypes[_index].price;
        ERC20(usdc).transferFrom(address(msg.sender), address(this), amount);

        uint256 fee = calculateFee(amount);
        // uint256 tvlfee = calculateTVLFee(amount);
        uint256 treasuryfee = calculateTreasuryFee(amount);
        ERC20(usdc).transfer(feeAddress, fee);
        ERC20(usdc).transfer(treasuryAddress, treasuryfee);

        // uint256 totalFee = fee + tvlfee + treasuryfee;

        users[msg.sender].modules.push(
            UserModule({
                moduleIndex: _index,
                startTime: block.timestamp
            })
        );

        // referral
        if(_ref == msg.sender) {
            _ref = address(0);
        }
        
        if(users[msg.sender].referrer == address(0) && users[msg.sender].referrer != msg.sender) {
            users[msg.sender].referrer = _ref;
        }

        if (users[msg.sender].referrer != address(0))
        {
            uint256 referralFee = amount * referralPercent / divisor;
            users[users[msg.sender].referrer].refBonus += referralFee;
            users[users[msg.sender].referrer].refCount += 1;
        }
    }

    /**
    * @dev Collect rewards.
    */
    function withdrawRef() public {
        require(initialized, "err: not started");
        require(users[msg.sender].refBonus > 0, "err: zero amount");

        ERC20(usdc).transfer(address(msg.sender), users[msg.sender].refBonus);
        users[msg.sender].refBonus = 0;
        users[msg.sender].refCount = 0;
    }

    /**
    * @dev Check it is on going or not.
    */
    function checkState() internal view {
        require(initialized, "err: not started");
    }
    
    /**
    * @dev Calculate marketing and dev fee.
    */
    function calculateFee(uint256 amount) private view returns(uint256) {
        return amount * feePercent / divisor;
    }
    
    /**
    * @dev Calculate TVL fee.
    */
    function calculateTVLFee(uint256 amount) private view returns(uint256) {
        return amount * feeTVLPercent / divisor;
    }

    /**
    * @dev Calculate treasury fee.
    */
    function calculateTreasuryFee(uint256 amount) private view returns(uint256) {
        return amount * feeTreasuryPercent / divisor;
    }

    /**
    * @dev Start platform.
    */
    function start() public onlyOwner {
        require(initialized == false, "err: already started");
        initialized=true;
    }
    
    /**
    * @dev Get USDC balance of contract.
    */
    function getContractBalance() public view returns(uint256) {
        return ERC20(usdc).balanceOf(address(this));
    }

    /**
    * @dev Get USDC balance of treasury.
    */
    function getTreasuryBalance() public view returns(uint256) {
        return ERC20(usdc).balanceOf(treasuryAddress);
    }

    /**
    * @dev Get user referral bonus.
    */
	function getUserReferralBonus(address addr) public view returns(uint256) {
		return users[addr].refBonus;
	}

    /**
    * @dev Get user modules.
    */
	function getUserModules(address addr) public view returns(UserModule[] memory) {
		return users[addr].modules;
	}

    /**
    * @dev Get rewards.
    */
    function getRewards(address addr) public view returns(uint256) {
        uint256 rewards = 0;
        for (uint256 i = 0; i < users[addr].modules.length; i++) {
            uint256 startTime = users[addr].modules[i].startTime;
            if (block.timestamp - startTime > 86400 * 365) {
                continue;
            }
            uint256 moduleIndex = users[addr].modules[i].moduleIndex;
            uint256 lastActionTime = max(users[addr].lastActionTime, startTime);

            uint256 price = moduleTypes[moduleIndex].price;
            uint256 rewardPercent = moduleTypes[moduleIndex].rewardPercent;
            
            rewards += (price * rewardPercent / divisor) * (block.timestamp - lastActionTime) / 86400;
        }
        return rewards + users[addr].leftReward;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
    * @dev Set address of marketing and dev fee.
    */
    function setFeeAddress(address addr) public onlyOwner {
        require(addr != address(0));
        feeAddress = addr;
    }
    
    /**
    * @dev Set treasury address.
    */
    function setTreasuryAddress(address addr) public onlyOwner {
        require(addr != address(0));
        treasuryAddress = addr;
    }

    /**
    * @dev Set mark/dev fee percent.
    */
    function setFeePercent(uint256 percent) public onlyOwner {
        require(percent > 0);
        feePercent = percent;
    }

    /**
    * @dev Set TVL fee percent.
    */
    function setTVLFeePercent(uint256 percent) public onlyOwner {
        feeTVLPercent = percent;
    }

    /**
    * @dev Set referral percent.
    */
    function setReferralPercent(uint256 percent) public onlyOwner {
        require(percent > 500);
        referralPercent = percent;
    }
}