// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract TokenExchange is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
  
    // Address of Token A
    address public tokenA;

    // Fee charged for each deposit of Token B
    uint256 public fee;

    // Balance of Token A for each user
    mapping(address => UserBalances) public balances;

    // Mapping of Token B variants to their addresses
    mapping(address => TokenBVariant) public tokenBVariants;

    struct TokenBVariant {
        address variantAddress;
        uint256 exchangeRate;
        uint256 vestingSchedule;
    }

    struct UserBalances {
        uint256 balance;
        uint256 vestingSchedule;
        uint256 vestingStartTime;
    }

    // Event triggered when a user deposits Token B
    event Deposit(address indexed user, address variant, uint256 amount);

    // Event triggered when a user claims their vested Token A
    event Claim(address indexed user, uint256 amount);

    // Event triggered when a TokenB variant is added
    event TokenBVariantAdded(
        address indexed tokenB,
        uint256 exchangeRate,
        uint256 vestingSchedule
    );

    // Event triggered when a TokenB variant is updated
    event TokenBVariantUpdated(
        address indexed tokenB,
        uint256 exchangeRate,
        uint256 vestingSchedule
    );

    constructor(address _tokenA, uint256 _fee) {
        tokenA = _tokenA;
        fee = _fee;
    }

    /**
     * @dev Update fee value.
     */
    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    /**
     * @dev Deposit Token B and receive Token A in return
     */
    function deposit(address variant, uint256 amount) public payable {
        // Verify that variant exists
        address variantAddress = tokenBVariants[variant].variantAddress;
        uint256 vestingSchedule = tokenBVariants[variant]
            .vestingSchedule;
        require(variantAddress != address(0), "Variant does not exist");

        // Verify that user has enough balance of Token B
        IERC20 variantToken = IERC20(variantAddress);
        uint256 userBalance = variantToken.balanceOf(msg.sender);
        require(userBalance >= amount, "Not enough balance");

        // Transfer Token B from user to contract
        variantToken.safeTransferFrom(msg.sender, address(this), amount);

        // Calculate amount of Token A to be credited to user
        uint256 exchangeRate = tokenBVariants[variant].exchangeRate;
        uint256 tokenADecimals = ERC20(tokenA).decimals();
        uint256 tokenBDecimals = ERC20(variantAddress).decimals();
        uint256 tokenAReceived = amount
            .mul(exchangeRate)
            .mul(10**tokenADecimals)
            .div(10**tokenBDecimals);

        // Transfer fee amount from user to contract
        if (fee > 0) {
            require(msg.value >= fee, "Insufficient balance to cover the fee");
            payable(owner()).transfer(fee);
        }

        // Credit user's balance with Token A
        balances[msg.sender] = UserBalances({
            balance: balances[msg.sender].balance.add(tokenAReceived),
            vestingSchedule: vestingSchedule,
            vestingStartTime: block.timestamp
        });

        emit Deposit(msg.sender, variant, amount);
    }

    /**
     * @dev Claim vested Token A
     */
    function claim() public {
        // Calculate vested amount of Token A
        uint256 vestedAmount = getVestedAmount(msg.sender);
        require(vestedAmount >= 0, "Reward is not vested!");

        // Transfer vested Token A to user
        IERC20(tokenA).safeTransfer(msg.sender, vestedAmount);

        // Reduce user's balance with a claimed amount
        balances[msg.sender].balance = balances[msg.sender].balance.sub(
            vestedAmount
        );

        emit Claim(msg.sender, vestedAmount);
    }

    /**
     * @dev Calculate vested amount of Token A for a user
     */
    function getVestedAmount(address user)
        public
        view
        returns (uint256 vestedAmount)
    {
        uint256 vestingSchedule = balances[user].vestingSchedule;
        uint256 userBalance = balances[user].balance.mul(1000);

        if (vestingSchedule > 0 && userBalance > 0) {
            uint256 vestingStartTime = balances[user].vestingStartTime;
            uint256 currentTime = block.timestamp;

            if (currentTime > vestingStartTime.add(vestingSchedule)) {
                // User's balance is fully vested
                vestedAmount = userBalance;
            } else {
                // Calculate vested amount based on time elapsed
                uint256 timeElapsed = currentTime.sub(vestingStartTime);
                vestedAmount = userBalance.mul(timeElapsed).div(
                    vestingSchedule
                );
            }
        }

        return vestedAmount;
    }

    // Withdraws all the Token stored in this contract to the owner's address.
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Withdraws a specified token from this contract to the owner's address.
    function withdrawToken(address token) public onlyOwner {
        IERC20 tokenInstance = IERC20(token);
        uint256 balance = tokenInstance.balanceOf(address(this));
        tokenInstance.safeTransfer(owner(), balance);
    }

    // Allows the owner to add a new variant of Token B to the contract.
    function addTokenBVariant(
        address tokenB,
        uint256 exchangeRate,
        uint256 vestingSchedule
    ) public onlyOwner {
        require(
            tokenB != address(tokenA),
            "Token B variant cannot be the same as Token A."
        );
        require(
            tokenBVariants[tokenB].exchangeRate == 0,
            "Token B variant already exists."
        );
        require(exchangeRate > 0, "Exchange rate must be greater than 0.");
        require(vestingSchedule > 0, "Vesting schedule cannot be empty.");

        tokenBVariants[tokenB] = TokenBVariant({
            variantAddress: tokenB,
            exchangeRate: exchangeRate,
            vestingSchedule: vestingSchedule
        });

        emit TokenBVariantAdded(tokenB, exchangeRate, vestingSchedule);
    }

    // Allows the owner to update the exchange rate and vesting schedule of a Token B variant.
    function updateTokenBVariant(
        address tokenB,
        uint256 exchangeRate,
        uint256 vestingSchedule
    ) public onlyOwner {
        require(
            tokenB != address(tokenA),
            "Token B variant cannot be the same as Token A."
        );
        require(
            tokenBVariants[tokenB].exchangeRate > 0,
            "Token B variant does not exist."
        );
        require(exchangeRate > 0, "Exchange rate must be greater than 0.");
        require(vestingSchedule > 0, "Vesting schedule cannot be empty.");

        tokenBVariants[tokenB].exchangeRate = exchangeRate;
        tokenBVariants[tokenB].vestingSchedule = vestingSchedule;

        emit TokenBVariantUpdated(tokenB, exchangeRate, vestingSchedule);
    }
}