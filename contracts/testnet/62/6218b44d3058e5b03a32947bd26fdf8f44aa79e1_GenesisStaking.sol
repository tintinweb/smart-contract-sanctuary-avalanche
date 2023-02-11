// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover
/// may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 private constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /// @dev `bytes4(keccak256(bytes("NewOwnerIsZeroAddress()")))`.
    uint256 private constant _NEW_OWNER_IS_ZERO_ADDRESS_ERROR_SELECTOR = 0x7448fbae;

    /// @dev `bytes4(keccak256(bytes("NoHandoverRequest()")))`.
    uint256 private constant _NO_HANDOVER_REQUEST_ERROR_SELECTOR = 0x6f5e8818;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally choosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, _NEW_OWNER_IS_ZERO_ADDRESS_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will be automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, _NO_HANDOVER_REQUEST_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    function ownershipHandoverValidFor() public view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solady/auth/Ownable.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IStratosphere.sol";

error GenesisStaking__ClaimsDisabled();
error GenesisStaking__DepositsDisabled();
error GenesisStaking__InvalidAddress();
error GenesisStaking__InvalidAmount();
error GenesisStaking__NotEnoughVPNDToDeposit();
error GenesisStaking__NoVAPEToClaim();
error GenesisStaking__OnlyStratosphereMembers();
error GenesisStaking__VAPEAlreadyUpdated();

/// @title GenesisStaking
/// @author mektigboy
/// @notice Genesis Staking contract
/// @dev Utilizes 'Ownable', 'IERC20', 'IStratosphere'
contract GenesisStaking is Ownable {
    //////////////
    /// EVENTS ///
    //////////////

    event VAPEUpdated(address vape);

    event FeeCollectorUpdated(address oldFeeCollector, address newFeeCollector);

    event Deposit(address indexed account, uint256 amount);

    event Claim(address indexed account, uint256 amount);

    event Retrieve(uint256 vpndAmount, uint256 vapeAmount);

    ///////////////////////
    /// PRIVATE STORAGE ///
    ///////////////////////

    IERC20 immutable s_vpnd;

    IERC20 immutable s_vape;

    IStratosphere immutable s_stratosphere;

    address constant BURN_WALLET = 0x000000000000000000000000000000000000dEaD;

    address s_feeCollector;

    uint256 s_tvl;

    mapping(address => uint256) s_depositOf;

    //////////////////////
    /// PUBLIC STORAGE ///
    //////////////////////

    uint256 public immutable deployment;

    uint256 public immutable depositsStartAt;

    uint256 public immutable depositsEndAt;

    uint256 public immutable claimsStartAt;

    ////////////////
    /// CONSTANS ///
    ////////////////

    uint256 public constant VAPE_TO_DISTRIBUTE = 420000 * 1e18;

    /////////////////
    /// MODIFIERS ///
    /////////////////

    /// @dev Mark function as only callable with a valid address
    /// @param _address The address to check
    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) revert GenesisStaking__InvalidAddress();

        _;
    }

    /// @dev Mark function as only callable by a Stratosphere member
    modifier onlyStratosphereMembers() {
        if (s_stratosphere.tokenIdOf(msg.sender) == 0) revert GenesisStaking__OnlyStratosphereMembers();

        _;
    }

    /// @dev Mark function as only callable when deposits are enabled
    modifier depositsEnabled() {
        if (block.timestamp < depositsStartAt || block.timestamp > depositsEndAt)
            revert GenesisStaking__DepositsDisabled();

        _;
    }

    /// @dev Mark function as only callable when claims are enabled
    modifier claimsEnabled() {
        if (block.timestamp < claimsStartAt) revert GenesisStaking__ClaimsDisabled();

        _;
    }

    ///////////////////
    /// CONSTRUCTOR ///
    ///////////////////

    constructor(address _vpnd, address _vape, address _stratosphere, address _feeCollector) {
        if (_vpnd == address(0) || _vape == address(0) || _stratosphere == address(0))
            revert GenesisStaking__InvalidAddress();

        _initializeOwner(msg.sender);

        deployment = block.timestamp;
        depositsStartAt = 1673625600;
        depositsEndAt = depositsStartAt + 4 hours;
        claimsStartAt = depositsEndAt;

        s_vpnd = IERC20(_vpnd);
        s_vape = IERC20(_vape);
        s_stratosphere = IStratosphere(_stratosphere);
        s_feeCollector = _feeCollector;
    }

    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Deposit VPND to stake
    /// @param _vpndAmount The amount of VPND to deposit
    function deposit(uint256 _vpndAmount) external onlyStratosphereMembers depositsEnabled {
        if (_vpndAmount == 0) revert GenesisStaking__InvalidAmount();
        if (_vpndAmount > s_vpnd.balanceOf(msg.sender)) revert GenesisStaking__NotEnoughVPNDToDeposit();

        (uint256 vpndFee, uint256 vpndAmountAfterFee) = calculateDepositFee(_vpndAmount);

        unchecked {
            s_depositOf[msg.sender] += vpndAmountAfterFee;
            s_tvl += vpndAmountAfterFee;
        }

        s_vpnd.transferFrom(msg.sender, BURN_WALLET, vpndFee);
        s_vpnd.transferFrom(msg.sender, address(this), vpndAmountAfterFee);

        emit Deposit(msg.sender, vpndAmountAfterFee);
    }

    /// @notice Claim all the earned VAPE of an account
    function claim() external claimsEnabled {
        uint256 vpndAmount = s_depositOf[msg.sender];

        if (vpndAmount == 0) revert GenesisStaking__NoVAPEToClaim();

        uint256 vapeAmount = _calculateEarnedVAPE(vpndAmount);

        unchecked {
            s_depositOf[msg.sender] -= vpndAmount;
        }

        (uint256 vapeFee, uint256 vapeAmountAfterFee) = calculateClaimFee(vapeAmount);

        s_vape.transfer(s_feeCollector, vapeFee);
        s_vape.transfer(msg.sender, vapeAmountAfterFee);

        emit Claim(msg.sender, vapeAmountAfterFee);
    }

    /// @notice Retrieve all the tokens locked inside this contract
    /// @param _to Recipient
    /// @dev Only owner can call this function, only use in case of emergency
    function retrieve(address _to) external onlyOwner {
        if (_to == address(0)) revert GenesisStaking__InvalidAddress();

        uint256 vpndAmount = s_vpnd.balanceOf(address(this));
        s_vpnd.transfer(_to, s_vpnd.balanceOf(address(this)));

        uint256 vapeAmount = s_vape.balanceOf(address(this));
        s_vape.transfer(_to, vapeAmount);

        emit Retrieve(vpndAmount, vapeAmount);
    }

    ////////////////////
    /// PUBLIC LOGIC ///
    ////////////////////

    /// @notice Calculate the deposit fee and the VPND amount after the fee is applied
    /// @param _vpndAmount The amount of VPND
    function calculateDepositFee(
        uint256 _vpndAmount
    ) public pure returns (uint256 vpndFee, uint256 vpndAmountAfterFee) {
        assembly {
            vpndFee := div(mul(_vpndAmount, 1), 100)
            vpndAmountAfterFee := sub(_vpndAmount, vpndFee)
        }
    }

    /// @notice Calculate the claim fee and the VAPE amount after the fee is applied
    /// @param _vapeAmount The amount of VAPE
    function calculateClaimFee(uint256 _vapeAmount) public pure returns (uint256 vapeFee, uint256 vapeAmountAfterFee) {
        assembly {
            vapeFee := div(mul(_vapeAmount, 3), 100)
            vapeAmountAfterFee := sub(_vapeAmount, vapeFee)
        }
    }

    //////////////////////
    /// INTERNAL LOGIC ///
    //////////////////////

    /// @notice Calculate the amount of VAPE earned by an account
    function _calculateEarnedVAPE(uint256 _vpndAmount) internal view returns (uint256) {
        if (_vpndAmount == 0) return 0;

        return (_vpndAmount * VAPE_TO_DISTRIBUTE) / s_tvl;
    }

    ////////////////
    /// SETTINGS ///
    ////////////////

    /// @notice Update the address of the fee collector
    /// @param _feeCollector The new address of the fee collector
    function updateFeeCollector(address _feeCollector) external onlyOwner onlyValidAddress(_feeCollector) {
        address oldFeeCollector = s_feeCollector;

        s_feeCollector = _feeCollector;

        emit FeeCollectorUpdated(oldFeeCollector, s_feeCollector);
    }

    ///////////////
    /// GETTERS ///
    ///////////////

    /// @notice Get the address of VPND
    function vpnd() external view returns (address) {
        return address(s_vpnd);
    }

    /// @notice Get the address of VAPE
    function vape() external view returns (address) {
        return address(s_vape);
    }

    /// @notice Get the address of Stratosphere
    function stratosphere() external view returns (address) {
        return address(s_stratosphere);
    }

    /// @notice Get the address of the burn wallet
    function burnWallet() external pure returns (address) {
        return BURN_WALLET;
    }

    /// @notice Get the address of the fee collector
    function feeCollector() external view returns (address) {
        return s_feeCollector;
    }

    /// @notice Get the amount of VAPE to distribute
    function vapeToDistribute() external view returns (uint256) {
        return s_vape.balanceOf(address(this));
    }

    /// @notice Get the total value locked of VPND
    function tvl() external view returns (uint256) {
        return s_tvl;
    }

    /// @notice Get the VPND balance of an account
    /// @param _account The account to check
    function vpndAccountBalance(address _account) external view returns (uint256) {
        return s_depositOf[_account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC20
/// @author mektigboy
interface IERC20 {
    //////////////
    /// EVENTS ///
    //////////////

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /////////////
    /// LOGIC ///
    /////////////

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IStratosphere
/// @author mektigboy
interface IStratosphere {
    /////////////
    /// LOGIC ///
    /////////////

    function tokenIdOf(address account) external view returns (uint256);
}