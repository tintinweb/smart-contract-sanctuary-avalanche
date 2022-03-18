/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-18
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.10;

/*
  VaultFactory.sol
  @notice Manages vault pools. A vault is a yield pool that pays rewards in the deposited token.
  @dev Explanation of algorithm:
    - users deposit ERC20 tokens into vaults
    - a deposit fee is subtracted and paid into the vault treasury
    - users can withdraw at any time, but 'mature' to their maximum every 24 hours
    - maximum daily rewards are calculated as:
        user.maxRewardsPending = treasuryBalance / treasuryRewardBP / user.shareOfPoolPercent
*/

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}
/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract VaultFactory is Auth(msg.sender, Authority(address(0))), ReentrancyGuard {
  event CreateVault(address indexed token);
  event Deposit(address indexed from, uint16 vaultId, uint256 amount, uint256 depositFee);
  event Withdraw(address indexed from, uint16 vaultId, uint256 amount);
  event Claim(address indexed from, uint16 vaultId, uint256 amount, uint256 claimFee);

	address public feeAddress; // fee wallet (for claims)

	/// @notice Info of each user that stakes LP tokens.
	struct UserInfo {
		uint256 depositBalance; // balance the user has staked in the vault
		uint256 lastClaimTime; // timestamp of last payout
	}

	/// @notice Map of each address that deposited tokens.
	mapping(uint16 => mapping(address => UserInfo)) public userInfo;

	/// @notice contains deposit and treasury amounts for each user
	struct VaultInfo {
		IERC20 depositedToken; // address of deposit token
		uint16 depositFeeBP; // deposit fee (goes to treasury) in basis points
		uint16 claimFeeBP; // claim fee (goes to devWallet) in basis points
		uint16 treasuryRewardBP; // reward percent accumulated after one period, divided amongst stakers (suggested ~20%)
    uint256 treasuryBalance; // treasury for paying rewards out
		uint256 depositBalance; // total user deposits (using balanceOf would be a security issue)
	}
	VaultInfo[] public vaultInfo; // this is an array so we can iterate (without danger of a large iteration)

	constructor(address _feeAddress) {
		feeAddress = _feeAddress;
	}

	/// create a new vault for a token
	function createVault(
		IERC20 _token,
		uint16 _depositFeeBP,
		uint16 _claimFeeBP,
		uint16 _treasuryRewardBP
	) public requiresAuth {
		require(
			_depositFeeBP < 10000 && _depositFeeBP > 0,
			"deposit fee must be between 0% and 100%"
		);

		require(
			_treasuryRewardBP <= 10000 && _treasuryRewardBP >= 0,
			"reward fee must be between 0% and 100%"
		);

		vaultInfo.push(
			VaultInfo({
				depositedToken: IERC20(_token),
				depositFeeBP: _depositFeeBP,
				claimFeeBP: _claimFeeBP,
				treasuryRewardBP: _treasuryRewardBP,
				treasuryBalance: 0,
				depositBalance: 0
			})
		);

    emit CreateVault(address(_token));
	}

	function deposit(uint16 _vaultId, uint256 _amount) public nonReentrant {
		require(_amount > 0, "cannot deposit 0 funds");
		require(_vaultId < vaultInfo.length, "no such vault");

		VaultInfo storage vault = vaultInfo[_vaultId];
		UserInfo storage user = userInfo[_vaultId][msg.sender];

		uint256 rewardDebt = pendingReward(_vaultId, address(msg.sender));

		// deposit token (minus fee) into vault
		vault.depositedToken.transferFrom(
			address(msg.sender),
			address(this),
			_amount
		);

		// calculate deposit fee (* 10000 to deal with basis points)
		uint256 depositFee = (_amount * vault.depositFeeBP) / 10000;

		user.lastClaimTime = block.timestamp;

    // place the deposit fee into the treasury
		vault.treasuryBalance += depositFee;

    uint256 depositBalance = _amount - depositFee;

		// subtract fee from users deposit amount
		user.depositBalance += depositBalance;
		vault.depositBalance += depositBalance;

    // pay any outstanding reward debts
    // paid here at the end to avoid re-entrancy attacks
    if (rewardDebt > 0) {
      if (vault.claimFeeBP > 0) {
        uint256 claimFee = (rewardDebt * vault.claimFeeBP) / 10000;

        // transfer the fee to the feeAddress
        vault.depositedToken.transfer(
          address(feeAddress),
          claimFee
        );

        rewardDebt -= claimFee;

        emit Claim(address(msg.sender), _vaultId, rewardDebt, claimFee);
      } else {
        emit Claim(address(msg.sender), _vaultId, rewardDebt, 0);
      }

      vault.depositedToken.transfer(
        address(msg.sender),
        rewardDebt
      );
    }

    emit Deposit(address(msg.sender), _vaultId, depositBalance, depositFee);
	}

	/// calculates the users share of a vault as a percentage BP
	function userVaultShareBP(uint16 _vaultId, address _address) public view returns (uint256) {
		require(_vaultId < vaultInfo.length, "no such vault");
		VaultInfo storage vault = vaultInfo[_vaultId];
		UserInfo storage user = userInfo[_vaultId][_address];

		if (user.depositBalance == 0) {
			return 0;
		}

		return (user.depositBalance * 10000) / vault.depositBalance;
	}

  /// returns vault reward pending for a user
	function pendingReward(uint16 _vaultId, address _address) public view returns (uint256) {
		require(_vaultId < vaultInfo.length, "no such vault");

		VaultInfo memory vault = vaultInfo[_vaultId];

		if (vault.treasuryBalance == 0) {
			return 0;
		}

		uint256 maxVaultPayout = (vault.treasuryBalance * vault.treasuryRewardBP) / 10000;
		if (maxVaultPayout == 0) {
			return 0;
		}

    uint256 maxUserPayout = (maxVaultPayout * userVaultShareBP(_vaultId, _address)) / 10000;

		UserInfo memory user = userInfo[_vaultId][_address];
    if(block.timestamp > user.lastClaimTime + 24 hours) {
      // 24 hours have passed since last claim, show max claim
      return maxUserPayout;
    }
	
    uint256 deltaSinceClaim = block.timestamp - user.lastClaimTime;
    return maxUserPayout * deltaSinceClaim / 24 hours;
	}

	function withdraw(uint16 _vaultId, uint256 _amount) public nonReentrant {
		require(_amount > 0, "cannot withdraw 0 funds");
		require(_vaultId < vaultInfo.length, "no such vault");

		VaultInfo storage vault = vaultInfo[_vaultId];
		UserInfo storage user = userInfo[_vaultId][msg.sender];

		require(_amount <= user.depositBalance, "attempt to overdraw funds");

		user.depositBalance -= _amount;
		vault.depositBalance -= _amount;

		vault.depositedToken.transfer(address(msg.sender), _amount);

    emit Withdraw(address(msg.sender), _vaultId, _amount);
	}

	function claim(uint16 _vaultId) public nonReentrant returns (uint256) {
		require(_vaultId < vaultInfo.length, "no such vault");

		VaultInfo storage vault = vaultInfo[_vaultId];
		UserInfo storage user = userInfo[_vaultId][msg.sender];

    // // user cannot claim until 24 hours has passed
		// require(
		// 	user.lastClaimTime <= (block.timestamp - 1 days),
		// 	"no rewards to claim yet"
		// );

		// uint256 rewardDebt = user.rewardDebt;
		uint256 rewardDebt = pendingReward(_vaultId, address(msg.sender));

    if (rewardDebt == 0) {
      return 0;
    }

		// take the debt from the treasury
		vault.treasuryBalance -= rewardDebt;

		// collect a claim fee if there is one.
		if (vault.claimFeeBP > 0) {
			// calculate fee (* 10000 to deal with basis points)
			uint256 claimFee = (rewardDebt * vault.claimFeeBP) / 10000;

			// transfer the fee to the feeAddress
			vault.depositedToken.transfer(
				address(feeAddress),
				claimFee
			);

			// remove the fee from the amount owed to user
			rewardDebt -= claimFee;

      emit Claim(address(msg.sender), _vaultId, rewardDebt, claimFee);
		} else {
      emit Claim(address(msg.sender), _vaultId, rewardDebt, 0);
    }

		user.lastClaimTime = block.timestamp;
		vault.depositedToken.transfer(
			address(msg.sender),
			rewardDebt
		);

		return rewardDebt;
	}

  /// EMERGENCY ONLY!!! - abandons pending rewards!!!
	function emergencyWithdraw(uint16 _vaultId) public nonReentrant {
		require(_vaultId < vaultInfo.length, "no such vault");

		VaultInfo storage vault = vaultInfo[_vaultId];
		UserInfo storage user = userInfo[_vaultId][msg.sender];

    uint256 userBalance = user.depositBalance;
		user.depositBalance = 0;
		vault.depositBalance -= userBalance;

		vault.depositedToken.transfer(address(msg.sender), userBalance);
	}
}