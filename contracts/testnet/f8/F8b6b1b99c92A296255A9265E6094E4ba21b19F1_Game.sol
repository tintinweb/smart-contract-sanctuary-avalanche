//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ISmartTestCoin is IERC20 {
    function legendaryTotalIncome(address address_) external view returns (uint256);

    function epicTotalIncomePerAddress(address address_) external view returns (uint256);

    function legendaryForClaim(address address_) external view returns (uint256);

    function epicForClaim(address address_) external view returns (uint256);

    function resetClaimableFor(address address_) external;
}

interface InvestmentsNFT is IERC721 {
    function totalToken() external view returns (uint256);
}

interface NodesNFT is IERC721 {
    function nodeBalanceOf(address address_) external view returns (uint256);

    function increment(uint256 amount) external;

    function decrement(uint256 amount) external;
}

contract Game {
    using SafeMath for uint256;

    address private _contractOwner;

    mapping(address => uint256) private _sNodes;
    mapping(address => uint256) private _sNodesClaimTime;

    mapping(address => uint256) private _bNodes;
    mapping(address => uint256) private _bNodesClaimTime;

    mapping(address => uint256) private _internalBalance;

    uint256 private _nodesCount;
    uint256 private _sNodesCount;
    uint256 private _bNodesCount;

    uint256 private _sNodeBR = 7;
    uint256 private _bNodeBR = 210;

    ISmartTestCoin private _coinContract;
    InvestmentsNFT private _epicNFTContract;
    InvestmentsNFT private _legendaryNFTContract;
    NodesNFT private _smallNodesContract;
    NodesNFT private _bigNodesContract;
    IERC721 private _goldNFTContract;
    IERC721 private _silverNFTContract;
    IERC721 private _bronzeNFTContract;

    constructor (
        ISmartTestCoin coinContract,
        InvestmentsNFT legendaryNFTContract,
        InvestmentsNFT epicNFTContract,
        NodesNFT smallNodesContract,
        NodesNFT bigNodesContract,
        IERC721 goldNFTContract,
        IERC721 silverNFTContract,
        IERC721 bronzeNFTContract
    ) {
        _contractOwner = msg.sender;

        _coinContract = coinContract;

        _legendaryNFTContract = legendaryNFTContract;
        _epicNFTContract = epicNFTContract;

        _smallNodesContract = smallNodesContract;
        _bigNodesContract = bigNodesContract;

        _goldNFTContract = goldNFTContract;
        _silverNFTContract = silverNFTContract;
        _bronzeNFTContract = bronzeNFTContract;
    }

    function _sPriceForIndex(uint256 idx_) private pure returns (uint256) {
        if (idx_ > 0 && idx_ <= 5) {
            return 20;
        } else if (idx_ > 5 && idx_ <= 10) {
            return 22;
        } else if (idx_ > 10 && idx_ <= 15) {
            return 24;
        } else if (idx_ > 15 && idx_ <= 20) {
            return 26;
        } else if (idx_ > 20 && idx_ <= 25) {
            return 28;
        } else if (idx_ > 25 && idx_ <= 30) {
            return 30;
        } else if (idx_ > 30 && idx_ <= 35) {
            return 32;
        } else if (idx_ > 35 && idx_ <= 40) {
            return 34;
        } else if (idx_ > 40 && idx_ <= 45) {
            return 36;
        } else if (idx_ > 45 && idx_ <= 50) {
            return 38;
        } else if (idx_ > 50 && idx_ <= 55) {
            return 40;
        } else if (idx_ > 55 && idx_ <= 60) {
            return 42;
        } else if (idx_ > 60 && idx_ <= 65) {
            return 44;
        } else if (idx_ > 65 && idx_ <= 70) {
            return 46;
        } else if (idx_ > 70 && idx_ <= 75) {
            return 48;
        } else {
            return 50;
        }
    }

    function _bPriceForIndex(uint256 idx_) private pure returns (uint256) {
        return idx_ * 10 + 10;
    }

    function _bsPriceForIndex(uint256 idx_) private pure returns (uint256) {
        if (idx_ == 1) {
            return 20;
        } else if (idx_ == 2) {
            return 22;
        } else if (idx_ == 3) {
            return 24;
        } else if (idx_ == 4) {
            return 26;
        } else if (idx_ == 5) {
            return 28;
        } else if (idx_ == 6) {
            return 30;
        } else if (idx_ == 7) {
            return 32;
        } else if (idx_ == 8) {
            return 34;
        } else if (idx_ == 9) {
            return 36;
        } else if (idx_ == 10) {
            return 38;
        } else {
            return 40;
        }
    }

    function _sPrice(address address_, uint256 amount_) public view returns (uint256){
        uint256 price = 0;

        uint256 currentBalance = _smallNodesContract.nodeBalanceOf(address_);

        for (uint256 i = currentBalance + 1; i < (currentBalance + amount_ + 1); i++) {
            price += _sPriceForIndex(i);
        }

        return price * (10 ** 8);
    }

    function createSNode(uint256 amount_) public {
        uint256 amount = _sPrice(msg.sender, amount_);

        require(_internalBalance[msg.sender] >= amount, "Not enough coins for this type of node. Please recharge internal balance");

        _internalBalance[msg.sender] -= amount;

        _smallNodesContract.increment(amount_);

        if (_sNodes[msg.sender] == 0) {
            _sNodesClaimTime[msg.sender] = block.timestamp;
        }

        _sNodes[msg.sender] += amount_;
        _sNodesCount += amount_;
        _nodesCount += amount_;
    }

    function createBNode() public {
        uint256 idx = _bNodes[msg.sender] + 1;
        uint256 coinAmount = _bPriceForIndex(idx);
        uint256 sNodesAmount = _bsPriceForIndex(idx);

        require(_internalBalance[msg.sender] >= coinAmount, "Not enough coins for this type of node. Please recharge internal balance");
        require(_sNodes[msg.sender] >= sNodesAmount, "Not enough sNodes for create bNode. Please create more sNodes");

        _internalBalance[msg.sender] -= coinAmount;

        _smallNodesContract.decrement(sNodesAmount);
        _bigNodesContract.increment(1);

        if (_bNodes[msg.sender] == 0) {
            _bNodesClaimTime[msg.sender] = block.timestamp;
        }

        _sNodes[msg.sender] -= sNodesAmount;
        _sNodesCount -= sNodesAmount;
        _bNodes[msg.sender] += 1;
        _bNodesCount += 1;
        _nodesCount -= (sNodesAmount - 1);
    }

    function rechargeBalance(uint256 amount_) public {
        uint256 coinBalance = _coinContract.balanceOf(msg.sender);
        uint256 amount = amount_ * (10 ** 8);

        require(coinBalance >= amount, "Not enough coins");

        uint256 allowForTransfer = _coinContract.allowance(msg.sender, address(this));
        require(allowForTransfer >= amount, "ERC20: Please approve more coins for this contract");

        _coinContract.transferFrom(msg.sender, address(this), amount);

        _internalBalance[msg.sender] += amount;
    }

    function withdrawBalance(uint256 amount_) public {
        require(_internalBalance[msg.sender] > 0, "Not enough coins on internal balance");

        uint256 amount = amount_.mul(10 ** 8);
        uint256 fee = amount.div(100).mul(15);
        uint256 actualAmount = amount - fee;

        _coinContract.transferFrom(address(this), msg.sender, actualAmount);
    }

    function sNodesWorkingTime(address address_) public view returns (uint256) {
        uint256 time = block.timestamp.sub(_sNodesClaimTime[address_]);

        if (time > 86400 * 3) {
            time = 86400 * 3;
        }

        return time;
    }

    function bNodesWorkingTime(address address_) public view returns (uint256) {
        uint256 time = block.timestamp.sub(_bNodesClaimTime[address_]);

        if (time > 86400 * 3) {
            time = 86400 * 3;
        }

        return time;
    }

    function epicClaimValue(address address_) public view returns (uint256) {
        return _coinContract.epicForClaim(address_);
    }

    function legendaryClaimValue(address address_) public view returns (uint256) {
        return _coinContract.legendaryForClaim(address_);
    }

    function _goldClaim(address address_, uint256 bNodesClaim) private view returns (uint256) {
        uint256 higherRate = 0;
        uint256 normalRate = _bNodes[address_];
        if (_bNodes[address_] > 5) {
            higherRate = 5;
            normalRate = _bNodes[address_] - 5;
        } else {
            higherRate = _bNodes[address_];
            normalRate = 0;
        }

        uint256 subValue = 0;

        if (higherRate > 0) {
            uint256 hClaim = bNodesClaim.mul(higherRate);
            uint256 hPercent = hClaim.div(100);
            subValue += hClaim.add(hClaim.mul(hPercent.mul(20)));
        }

        if (normalRate > 0) {
            uint256 nClaim = bNodesClaim.mul(normalRate);
            subValue += nClaim;
        }

        return subValue;
    }

    function _silverClaim(address address_, uint256 bNodesClaim) private view returns (uint256) {
        uint256 higherRate = 0;
        uint256 normalRate = _bNodes[address_];
        if (_bNodes[address_] > 1) {
            higherRate = 1;
            normalRate = _bNodes[address_] - 1;
        } else {
            higherRate = _bNodes[address_];
            normalRate = 0;
        }

        uint256 subValue = 0;

        if (higherRate > 0) {
            uint256 hClaim = bNodesClaim.mul(higherRate);
            uint256 hPercent = hClaim.div(100);
            subValue += hClaim.add(hClaim.mul(hPercent.mul(15)));
        }

        if (normalRate > 0) {
            uint256 nClaim = bNodesClaim.mul(normalRate);
            subValue += nClaim;
        }

        return subValue;
    }

    function _bronzeClaim(address address_, uint256 sNodesClaim) private view returns (uint256) {
        uint256 higherRate = 0;
        uint256 normalRate = _sNodes[address_];
        if (_sNodes[address_] > 2) {
            higherRate = 2;
            normalRate = _sNodes[address_] - 2;
        } else {
            higherRate = _sNodes[address_];
            normalRate = 0;
        }

        uint256 subValue = 0;

        if (higherRate > 0) {
            uint256 hClaim = sNodesClaim.mul(higherRate);
            uint256 hPercent = hClaim.div(100);
            subValue += hClaim.add(hClaim.mul(hPercent.mul(15)));
        }

        if (normalRate > 0) {
            uint256 nClaim = sNodesClaim.mul(normalRate);
            subValue += nClaim;
        }

        return subValue;
    }

    function _bNodeClaimValue(address address_) private view returns (uint256) {
        uint256 value = 0;

        if (_bNodes[address_] > 0) {
            uint256 bNodesClaim = _bNodeBR.mul(10 ** 8).div(864000);
            uint256 bNodesWorkingTime_ = bNodesWorkingTime(address_);
            bNodesClaim = bNodesClaim.mul(bNodesWorkingTime_);

            if (_goldNFTContract.balanceOf(address_) > 0 || _silverNFTContract.balanceOf(address_) > 0) {
                if (_goldNFTContract.balanceOf(address_) > 0) {
                    value += _goldClaim(address_, bNodesClaim);
                }

                if (_silverNFTContract.balanceOf(address_) > 0) {
                    value += _silverClaim(address_, bNodesClaim);
                }
            } else {
                value += (bNodesClaim.mul(_bNodes[address_]));
            }
        }

        return value;
    }

    function _sNodeClaimValue(address address_) private view returns (uint256) {
        uint256 value = 0;

        uint256 sNodesClaim = _sNodeBR.mul(10 ** 8).div(864000);
        uint256 sNodesWorkingTime_ = sNodesWorkingTime(address_);
        sNodesClaim = sNodesClaim.mul(sNodesWorkingTime_);

        if (_bronzeNFTContract.balanceOf(address_) > 0) {
            value += _bronzeClaim(address_, sNodesClaim);
        } else {
            value += (sNodesClaim.mul(_sNodes[address_]));
        }

        return value;
    }

    function claimValue(address address_) public view returns (uint256) {
        uint256 value_ = 0;

        value_ += _sNodeClaimValue(address_);

        value_ += _bNodeClaimValue(address_);

        value_ += epicClaimValue(address_);
        value_ += legendaryClaimValue(address_);

        return value_;
    }

    function internalBalance(address address_) public view returns (uint256) {
        return _internalBalance[address_];
    }

    function claim() public {
        uint256 forClaim = claimValue(msg.sender);
        require(forClaim > 0, "Not enough coins for claim");

        _internalBalance[msg.sender] += forClaim;
        _coinContract.resetClaimableFor(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}