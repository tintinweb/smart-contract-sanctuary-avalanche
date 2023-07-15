// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract HopeExchange is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Address of Hope
    address public hope;

    // Fee charged for each swap of Grave Yard
    uint256 public fee;

    // Balance of Hope for each user
    mapping(address => UserBalances) public balances;

    // Mapping of Grave Yard variants to their addresses
    mapping(address => GraveYard) public graveYards;

    // Struct of Grave yard details
    struct GraveYard {
        address variantAddress;
        uint256 exchangeRate;
        uint256 vestingSchedule;
    }

    // Struct of User balances
    struct UserBalances {
        uint256 balance;
        uint256 claimedAmount;
        uint256 vestingSchedule;
        uint256 vestingStartTime;
        uint256 lastClaimTime;
    }

    // Event triggered when a user swaps Grave Yard
    event Swap(address indexed user, address variant, uint256 amount);

    // Event triggered when a user claims their vested Hope
    event Claim(address indexed user, uint256 amount);

    // Event triggered when a Grave Yard variant is added
    event GraveYardAdded(
        address indexed graveYard,
        uint256 exchangeRate,
        uint256 vestingSchedule
    );

    // Event triggered when a Grave Yard variant is updated
    event GraveYardUpdated(
        address indexed graveYard,
        uint256 exchangeRate,
        uint256 vestingSchedule
    );

    constructor(address _hope, uint256 _fee) {
        hope = _hope;
        fee = _fee;
    }

    /**
     * @dev Swap Grave Yard and receive Hope in return
     */
    function swap(address variant, uint256 amount) external payable {
        GraveYard storage graveYard = graveYards[variant];
        IERC20 variantToken = IERC20(graveYard.variantAddress);
        require(graveYard.variantAddress != address(0), "Variant does not exist"); 
        require(variantToken.balanceOf(msg.sender) >= amount, "Not enough balance");

        if (fee > 0) {
            require(msg.value >= fee, "Insufficient balance to cover the fee");
        }

        variantToken.safeTransferFrom(msg.sender, address(this), amount); 
        uint256 exchangeRate = graveYard.exchangeRate; 
        uint256 graveYardDecimals = ERC20(graveYard.variantAddress).decimals();
        uint256 hopeDecimals = ERC20(hope).decimals();
        uint256 graveYardAmount = amount.mul(10**hopeDecimals).div(10**graveYardDecimals);
        uint256 hopeReceived = graveYardAmount.mul(exchangeRate).div(10**hopeDecimals);
 
        UserBalances storage userBalance = balances[msg.sender];
        uint256 vestedAmount = getVestedAmount(msg.sender);
        userBalance.balance = userBalance.balance.add(hopeReceived); 
        userBalance.vestingSchedule = graveYard.vestingSchedule;
        userBalance.vestingStartTime = block.timestamp;
        userBalance.lastClaimTime = block.timestamp;

        if (vestedAmount > 0) {
            userBalance.balance = userBalance.balance.sub(vestedAmount);
            userBalance.claimedAmount = userBalance.claimedAmount.add(vestedAmount);
            IERC20(hope).safeTransfer(msg.sender, vestedAmount);
            emit Claim(msg.sender, vestedAmount);
        }

        emit Swap(msg.sender, variant, amount);
    }

    /**
     * @dev Claim vested Hope
     */
    function claim() external {
        UserBalances storage userBalance = balances[msg.sender];
        uint256 vestedAmount = getVestedAmount(msg.sender);
        require(vestedAmount > 0, "No vested amount to claim");

        userBalance.balance = userBalance.balance.sub(vestedAmount);
        userBalance.claimedAmount = userBalance.claimedAmount.add(vestedAmount);
        userBalance.lastClaimTime = block.timestamp;

        IERC20(hope).safeTransfer(msg.sender, vestedAmount);
        emit Claim(msg.sender, vestedAmount);
    }

    /**
     * @dev Calculate vested amount of Hope for a user
     */
    function getVestedAmount(address user) public view returns (uint256) {
        UserBalances storage userBalance = balances[user];
        uint256 vestingSchedule = userBalance.vestingSchedule;
        uint256 userBalanceAmount = userBalance.balance;

        if (vestingSchedule > 0 && userBalanceAmount > 0) {
            uint256 vestingStartTime = userBalance.lastClaimTime;
            uint256 currentTime = block.timestamp;

            if (currentTime > vestingStartTime.add(vestingSchedule)) {
                // User's balance is fully vested
                return userBalanceAmount;
            } else {
                // Calculate vested amount based on time elapsed
                uint256 timeElapsed = currentTime.sub(vestingStartTime);
                return userBalanceAmount.mul(timeElapsed).div(vestingSchedule);
            }
        }

        return 0;
    }

    // Withdraws all the Token stored in this contract to the owner's address.
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Withdraws a specified token from this contract to the owner's address.
    function withdrawToken(address token) external onlyOwner {
        IERC20 tokenInstance = IERC20(token);
        uint256 balance = tokenInstance.balanceOf(address(this));
        tokenInstance.safeTransfer(owner(), balance);
    }

    // Allows the owner to add a new variant of Grave Yard to the contract.
    function addGraveYard(
        address graveYard,
        uint256 exchangeRate,
        uint256 vestingSchedule
    ) external onlyOwner {
        require(graveYard != address(hope), "Grave Yard variant cannot be the same as Hope");
        require(graveYards[graveYard].variantAddress == address(0), "Grave Yard variant already exists");
        uint256 graveYardDecimals = ERC20(graveYard).decimals();
        require(exchangeRate > 1 * (10**graveYardDecimals), "Exchange rate must be greater than 1");
        require(vestingSchedule > 0, "Vesting schedule cannot be empty");

        graveYards[graveYard] = GraveYard({
            variantAddress: graveYard,
            exchangeRate: exchangeRate,
            vestingSchedule: vestingSchedule
        });

        emit GraveYardAdded(graveYard, exchangeRate, vestingSchedule);
    }

    // Allows the owner to update the exchange rate and vesting schedule of a Grave Yard variant.
    function updateGraveYard(
        address graveYard,
        uint256 exchangeRate,
        uint256 vestingSchedule
    ) external onlyOwner {
        require(graveYard != address(hope), "Grave Yard variant cannot be the same as Hope");
        require(graveYards[graveYard].variantAddress != address(0), "Grave Yard variant does not exist");
        uint256 graveYardDecimals = ERC20(graveYard).decimals();
        require(exchangeRate > 1 * (10**graveYardDecimals), "Exchange rate must be greater than 1");
        require(vestingSchedule > 0, "Vesting schedule cannot be empty");

        graveYards[graveYard].exchangeRate = exchangeRate;
        graveYards[graveYard].vestingSchedule = vestingSchedule;

        emit GraveYardUpdated(graveYard, exchangeRate, vestingSchedule);
    }

    // Allows the owner to update the swap fee.
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
}