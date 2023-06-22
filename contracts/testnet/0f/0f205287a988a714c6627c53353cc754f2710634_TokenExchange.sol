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

    // Exchange rate of each Token B variant to Token A
    mapping(address => uint256) public exchangeRates;

    // Vesting schedule for each Token B variant
    mapping(address => uint256) public vestingSchedules;

    // Address of Token A
    address public tokenA;

    // Fee charged for each deposit of Token B
    uint256 public fee;

    // Mapping of Token B variants to their addresses
    mapping(string => address) public variantAddresses;

    // Balance of Token A for each user
    mapping(address => uint256) public balances;

    // Start time for vesting of Token A for each user
    mapping(address => uint256) public vestingStartTimes;

    // Mapping of Token B variants to their addresses
    mapping(address => TokenBVariant) public tokenBVariants;

    struct TokenBVariant {
        uint256 exchangeRate;
        uint256[] vestingSchedule;
    }

    // Event triggered when a user deposits Token B
    event Deposit(address indexed user, string variant, uint256 amount);

    // Event triggered when a user claims their vested Token A
    event Claim(address indexed user, uint256 amount);

    // Event triggered when a TokenB variant is added
    event TokenBVariantAdded(
        address indexed tokenB,
        uint256 exchangeRate,
        uint256[] vestingSchedule
    );

    // Event triggered when a TokenB variant is updated
    event TokenBVariantUpdated(
        address indexed tokenB,
        uint256 exchangeRate,
        uint256[] vestingSchedule
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
     * @dev Add a new variant of Token B to the contract
     */
    function addVariant(
        string memory variant,
        address variantAddress,
        uint256 exchangeRate,
        uint256 vestingSchedule
    ) public onlyOwner {
        variantAddresses[variant] = variantAddress;
        exchangeRates[variantAddress] = exchangeRate;
        vestingSchedules[variantAddress] = vestingSchedule;
    }

    /**
     * @dev Deposit Token B and receive Token A in return
     */
    function deposit(string memory variant, uint256 amount) public payable {
        // Verify that variant exists
        address variantAddress = variantAddresses[variant];
        require(variantAddress != address(0), "Variant does not exist");

        // Verify that user has enough balance of Token B
        IERC20 variantToken = IERC20(variantAddress);
        uint256 userBalance = variantToken.balanceOf(msg.sender);
        require(userBalance >= amount, "Not enough balance");

        // Transfer Token B from user to contract
        variantToken.safeTransferFrom(msg.sender, address(this), amount);

        // Calculate amount of Token A to be credited to user
        uint256 exchangeRate = exchangeRates[variantAddress];
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
        balances[msg.sender] = balances[msg.sender].add(tokenAReceived);

        // Set vesting start time for user's balance
        vestingStartTimes[msg.sender] = block.timestamp;

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
        balances[msg.sender] = balances[msg.sender].sub(vestedAmount);

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
        uint256 vestingSchedule = vestingSchedules[tokenA];
        uint256 userBalance = balances[user];

        if (vestingSchedule > 0 && userBalance > 0) {
            uint256 vestingStartTime = vestingStartTimes[user];
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
        uint256[] memory vestingSchedule
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
        require(
            vestingSchedule.length > 0,
            "Vesting schedule cannot be empty."
        );
        require(
            vestingSchedule[0] > block.timestamp,
            "Vesting start time must be in the future."
        );

        tokenBVariants[tokenB] = TokenBVariant({
            exchangeRate: exchangeRate,
            vestingSchedule: vestingSchedule
        });

        emit TokenBVariantAdded(tokenB, exchangeRate, vestingSchedule);
    }

    // Allows the owner to update the exchange rate and vesting schedule of a Token B variant.
    function updateTokenBVariant(
        address tokenB,
        uint256 exchangeRate,
        uint256[] memory vestingSchedule
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
        require(
            vestingSchedule.length > 0,
            "Vesting schedule cannot be empty."
        );
        require(
            vestingSchedule[0] > block.timestamp,
            "Vesting start time must be in the future."
        );

        tokenBVariants[tokenB].exchangeRate = exchangeRate;
        tokenBVariants[tokenB].vestingSchedule = vestingSchedule;

        emit TokenBVariantUpdated(tokenB, exchangeRate, vestingSchedule);
    }
}