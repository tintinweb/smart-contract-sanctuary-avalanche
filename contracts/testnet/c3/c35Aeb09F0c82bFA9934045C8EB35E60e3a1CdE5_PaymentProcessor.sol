//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./LandInfoData.sol";
import "./TestUSDC.sol";
import "./CO2E.sol";
import "./LandRegistryContractInterface.sol";

contract PaymentProcessor is Ownable, LandInfoData {
    TestUSDC public testUSDC;
    CO2E public co2e;
    LandRegistryContractInterface private landRegistryContract;

    uint256 [] parameters;
    string [] parameterNames;
    address [] public users;
    //index 0: areaIndex
    //index 1: treeIndex
    //index 2: areaMultiplier
    //index 3: percentMultipler
    //index 4: numOfClasses
    //index 5: treeEmissionsFactor
    //index 6: platformFee


    // uint areaIndex = 0;
    // uint treeIndex = 8;
    // int areaMultiplier = 10000;
    // int percentMultipler = 1e9;
    // uint numOfClasses = 9;
    // int treeEmissionsFactor = 4000; // 4000 tonnes of CO2e per sq km per year
    // //source: https://cbmjournal.biomedcentral.com/articles/10.1186/s13021-018-0110-8
    // int platformFee = 10; // 10% platform fee

    struct Commitment {
        uint256 amount;
        uint256 price;
        address payer;
    }

    function setParameters(uint256 [] memory _parameters, string [] memory _parameterNames) public onlyOwner {
        parameters = _parameters;
        parameterNames = _parameterNames;
    }

    function getParameters() public view returns (uint256 [] memory, string [] memory) {
        return (parameters, parameterNames);
    }

    //mapping for USDC and CO2E balances
    mapping(address => uint256) public userUSDCBalances;
    mapping(address => uint256) public userCO2EBalances;
    mapping(uint256 => uint256) public landCO2EBalances;
    mapping(uint256 => Commitment []) public offsetPurchaseCommitments;

    // events for deposit and withdrawals of usdc and co2e
    event DepositUSDCEvent(address indexed from, uint256 amount);
    event WithdrawUSDCEvent(address indexed to, uint256 amount);
    event WithdrawCO2EEvent(uint256 id, address indexed to, uint256 amount);
    event DepositCO2EEvent(address indexed from, uint256 amount);
    event CO2EMintedEvent(address indexed from, uint256 amount);
    event CommitmentSettled(uint256 indexed id, address indexed payer, uint256 co2eAmount, uint256 usdcAmount);
    event CommitmentMade(uint256 indexed id, address indexed payer, uint256 usdcAmount, uint256 price);
    event LandRegistryAddressSetEvent(address indexed from, address indexed landRegistryAddress);
    event EmissionsCalculationEvent(uint256 indexed id, int256 indexed co2eAmount, string message);

    address public landRegistryContractAddress;

    constructor(address _testUSDCAddress, address _co2eAddress) {
        testUSDC = TestUSDC(_testUSDCAddress);
        co2e = CO2E(_co2eAddress);
    }

    function withdrawUSDC(uint256 _amount) public {
        require(userUSDCBalances[msg.sender] >= _amount, "Insufficient USDC balance");
        testUSDC.transfer(msg.sender, _amount);
        userUSDCBalances[msg.sender] -= _amount;
        emit WithdrawUSDCEvent(msg.sender, _amount);
    }

    function depositUSDC(uint256 _amount) public {
        testUSDC.transferFrom(msg.sender, address(this), _amount);
        userUSDCBalances[msg.sender] += _amount;
        users.push(msg.sender);
        emit DepositUSDCEvent(msg.sender, _amount);
    }

    function withdrawCO2E(uint256 _amount) public {
        require(userCO2EBalances[msg.sender] >= _amount, "Insufficient CO2E balance");
        co2e.transfer(msg.sender, _amount);
        userCO2EBalances[msg.sender] -= _amount;
        emit WithdrawCO2EEvent(0, msg.sender, _amount);
    }

    function mintCO2E(address _user, uint256 _amount) public onlyOwner {
        co2e.mint(_user, _amount);
        emit CO2EMintedEvent(_user, _amount);
    }

    function depositCO2E(uint256 _amount) public payable {
        co2e.transferFrom(msg.sender, address(this), _amount);
        userCO2EBalances[msg.sender] += _amount;
        emit DepositCO2EEvent(msg.sender, _amount);
    }

    function commit(uint256 _id, uint256 _amount, uint256 _price) public {
        if (userUSDCBalances[msg.sender] < _amount) {
            depositUSDC(_amount - userUSDCBalances[msg.sender]);
        }
        userUSDCBalances[msg.sender] -= _amount;
        userUSDCBalances[address(this)] += _amount * parameters[6] / 100;

        //accoungting for the fees
        Commitment memory newCommitment = Commitment((_amount * (100-parameters[6]))/100, _price, msg.sender);
        Commitment[] storage commitments = offsetPurchaseCommitments[_id];

        if (commitments.length == 0) {
            commitments.push(newCommitment);
            emit CommitmentMade(_id, msg.sender, _amount, _price);
            return;
        }

        uint256 index = binarySearch(commitments, _price);
        commitments.push(commitments[commitments.length - 1]);
        for (uint256 i = commitments.length - 2; i > index; i--) {
            commitments[i] = commitments[i - 1];
        }
        commitments[index] = newCommitment;
        emit CommitmentMade(_id, msg.sender, _amount, _price);
    }

    function binarySearch(Commitment[] storage commitments, uint256 price) internal view returns (uint256) {
        if (commitments.length == 0) {
            return 0;
        }

        uint256 left = 0;
        uint256 right = commitments.length - 1;

        while (left < right) {
            uint256 mid = left + (right - left) / 2;
            if (commitments[mid].price < price) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        return (commitments[left].price < price) ? left + 1 : left;
    }

    function setLandRegistryContractAddress(address _landRegistryContractAddress) public onlyOwner {
        address oldAddress = landRegistryContractAddress;
        landRegistryContractAddress = _landRegistryContractAddress;
        landRegistryContract = LandRegistryContractInterface(_landRegistryContractAddress);
        emit LandRegistryAddressSetEvent(oldAddress, _landRegistryContractAddress);
    }

    function getLandRegistryContractAddress() public view returns (address) {
        return landRegistryContractAddress;
    }

    function getOffsetPurchaseCommitments(uint256 _id) public view returns (Commitment [] memory) {
        return offsetPurchaseCommitments[_id];
    }

    function triggerLandStatsRequest(uint256 _id) public {
        landRegistryContract.requestLandStats(_id, block.timestamp);
    }

    function getLandStats(uint256 _id) public view returns (LandRegistration memory) {
        return landRegistryContract.returnLandStats(_id);
    }

    function calculateEmissionsImpact(uint256 _id) public {
        int256 emissionsImpact = 0;
        LandRegistration memory landRegistration = landRegistryContract.returnLandStats(_id);
        require(msg.sender == landRegistration.owner, "Only the land owner can trigger CO2E minting");
        if (landRegistration.nextSamplingTime == 0) {
            triggerLandStatsRequest(_id);
            emit EmissionsCalculationEvent(_id, emissionsImpact, "Carbon impact not calculated yet. Triggered an update request.  Check back in a few minutes.");
            return;
        }
        if (landRegistration.nextSamplingTime <= block.timestamp || landRegistration.firstMintEvent == false) {
            int area = int(landRegistration.landStats[parameters[0]]); //area is sq kms * 10000 (whatever area multiplier is)
            int treeCover_percent_latest_year = int(landRegistration.landStats[parameters[1]]); //tree cover is in % * 10000 (whatever percent multiplier is)
            int treeCover_percent_previous_year = int(landRegistration.landStats[parameters[1]+parameters[4]]); //tree cover is in % * 10000 (whatever percent multiplier is)
            //not dividing by 10000 because we are going to calculate the emissions impact on each pixel, which is 10x10m
            emissionsImpact = area * (treeCover_percent_latest_year - treeCover_percent_previous_year) * int(parameters[5]) / (int(parameters[3]) * 100);
            landRegistryContract.updateCO2EStats(_id, emissionsImpact);
            if (emissionsImpact > 0) {
                co2e.mint(address(this), uint256(emissionsImpact));
                landCO2EBalances[_id] += uint256(emissionsImpact);
                emit EmissionsCalculationEvent(_id, emissionsImpact, "Carbon impact calculated and CO2E minted");
            } else {
                emit EmissionsCalculationEvent(_id, emissionsImpact, "Carbon impact is negative, no CO2E minted");
        }
        } else {
            emit EmissionsCalculationEvent(_id, emissionsImpact, "Carbon impact already calculated for this land registration ID less than a year ago");
        }
    }

    function payOut(uint256 _id, uint256 _amount, uint tokentype) public {
        require(_amount > 0, "Amount requested for withdrawal must be greater than 0");
        LandRegistration memory landRegistration = landRegistryContract.returnLandStats(_id);
        require(msg.sender == landRegistration.owner, "Only the land owner can withdraw the CO2E balance");
        uint256 landCO2EBalance = landCO2EBalances[_id];
        require(landCO2EBalance >= _amount, "Amount requested for withdrawal greater than balance for this land");

        if (tokentype == 0) {
            co2e.transfer(landRegistration.owner, _amount);
            emit WithdrawCO2EEvent(_id, landRegistration.owner, _amount);
            landCO2EBalances[_id] -= _amount;
        } else if (tokentype == 1) {
            Commitment[] storage commitments = offsetPurchaseCommitments[_id];
            require(commitments.length > 0, "No offset purchase commitments for this land");

            uint256 i = commitments.length;
            uint256 usdcTransferAmount = 0;
            while (_amount > 10000 && i > 0) {
                i--;
                uint256 commitmentAmount = commitments[i].amount;
                uint256 commitmentPrice = commitments[i].price;
                uint256 tokensToSell = (commitmentAmount/commitmentPrice < _amount) ? commitmentAmount/commitmentPrice : _amount;

                // Transfer tokens to the buyer
                landCO2EBalances[_id] -= tokensToSell;
                userCO2EBalances[commitments[i].payer] += tokensToSell;

                // Transfer USDC to the landowner
                uint256 usdcAmount = tokensToSell * commitmentPrice;
                emit CommitmentSettled(_id, commitments[i].payer, tokensToSell, usdcAmount);
                usdcTransferAmount += usdcAmount;

                _amount -= tokensToSell;
                commitments[i].amount -= usdcAmount;

                if (commitments[i].amount < 10000) {
                    userUSDCBalances[commitments[i].payer] += commitments[i].amount;
                    userUSDCBalances[address(this)] -= commitments[i].amount;
                    commitments.pop();
                }
            }

            testUSDC.transfer(landRegistration.owner, usdcTransferAmount);
        }
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestUSDC is ERC20, Ownable {

    constructor(uint256 initialSupply) ERC20("Test USDC", "tUSDC") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./LandInfoData.sol";

abstract contract LandRegistryContractInterface is LandInfoData {

    mapping (uint256 => LandRegistration) public idToRegInfo;
    uint256 [] public activeRegistrations;
    
    function callBack(uint256 requestId, uint256 [] memory values, string [] memory strings) public virtual;
    function requestLandStats(uint256 _id, uint256 _time) public virtual;
    function getLandCoords(uint256 _id) public view virtual returns (int256 [][] memory);
    function returnLandStats(uint256 _id) public view virtual returns (LandRegistration memory);
    function updateCO2EStats(uint256 _id, int256 _newCO2EStats) public virtual;

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract LandInfoData {
    // Define the struct that will hold the registration information
    struct LandRegistration {
        address registeringAuthority;
        address owner;
        uint256 registrationTime;
        uint256 nextSamplingTime;
        string landName;
        int256 [][] landCoords;
        uint256 [] landStats;
        string [] landStatsAddlInfo;
        int256 totalCO2EMinted;
        int256 totalCO2EMintedLastYear;
        bool firstMintEvent;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CO2E is ERC20, Ownable {

    constructor(uint256 initialSupply) ERC20("CO2E Offset", "CO2E") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 4;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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