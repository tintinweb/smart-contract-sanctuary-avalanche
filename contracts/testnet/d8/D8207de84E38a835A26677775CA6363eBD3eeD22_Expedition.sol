// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IHeroesToken.sol";

contract Expedition is Ownable, Pausable {
  using Address for address;
  using SafeERC20 for IERC20;

  uint256 public constant CAMPAIGN_DURATION = 4 hours;
  uint256 public constant WINDOW_DURATION = 20 minutes;

  IERC20 public immutable honToken;
  IERC20 public immutable hrmToken;
  IHeroesToken public immutable nft;

  // count of current campaigns
  uint256 public currentCampaigns;

  // count of total campaigns
  uint256 public totalCampaigns;

  mapping(address => uint256[]) public joinedCampaigns;

  /// @dev entry fee
  uint256[] public honFee = [
    44e16, 48e16, 52e16, 57e16, 62e16, 67e16, 72e16, 78e16, 84e16, 90e16,
    98e16, 105e16, 114e16, 123e16, 132e16, 143e16, 154e16, 166e16, 180e16, 194e16,
    209e16, 225e16, 242e16, 260e16, 280e16, 301e16, 323e16, 346e16, 371e16, 398e16,
    425e16, 455e16, 486e16, 518e16, 552e16, 588e16, 626e16, 666e16, 707e16, 750e16,
    796e16, 843e16, 892e16, 944e16, 998e16, 1053e16, 1112e16, 1172e16, 1235e16, 1300e16
  ];
  uint256[] public hrmFee = [
    44e18, 48e18, 52e18, 57e18, 62e18, 67e18, 72e18, 78e18, 84e18, 90e18,
    98e18, 105e18, 114e18, 123e18, 132e18, 143e18, 154e18, 166e18, 180e18, 194e18,
    209e18, 225e18, 242e18, 260e18, 280e18, 301e18, 323e18, 346e18, 371e18, 398e18,
    425e18, 455e18, 486e18, 518e18, 552e18, 588e18, 626e18, 666e18, 707e18, 750e18,
    796e18, 843e18, 892e18, 944e18, 998e18, 1053e18, 1112e18, 1172e18, 1235e18, 1300e18
  ];
  uint constant LENGTH = 5;
  uint256 public penaltyAmountBp = 1000;
  uint256 public boostAmountBp = 1000;

  /// @dev start timestamp of the campaign
  /// @dev reward amount
  /// @dev maker
  /// @dev ambusher
  /// @dev area
  struct Campaign {
    uint256 startTimestamp;
    uint256 tier; // 0 - 4
    address maker;
    address ambusher;
    uint area; // gunslinger 0 | mystic 1 | warrior 2 | neutral
    uint256[] reinforceTimestamps;
    uint256[] attackNFTs;
    uint256[] defenseNFTs;
    uint256 defensePoint;
    uint256 attackPoint;
  }

  Campaign[] public campaigns;

  constructor(address _honToken, address _hrmToken, address _nft) {
    //TODO: require(_token.isContract(), "The token address must be a deployed contract");
    honToken = IERC20(_honToken);
    hrmToken = IERC20(_hrmToken);
    nft = IHeroesToken(_nft);
  }

  function getFirstActiveCampaignId() external view returns (uint256) {
    uint256 id = totalCampaigns - 1;
    uint256 startId = totalCampaigns;
    while (id >= 0) {
      Campaign storage campaign = campaigns[id];
      if (campaign.startTimestamp + CAMPAIGN_DURATION > block.timestamp) {
        startId --;
      } else {
        break;
      }
      id --;
    }

    return startId;
  }

  function participate(uint256 _id, uint256[] calldata _tokenIds) public whenNotPaused {
    require(_id < totalCampaigns, "campaign does not exist");
    require(_tokenIds.length == LENGTH, "invalid _tokenIds length");

    Campaign storage campaign = campaigns[_id];
    require(campaign.ambusher == address(0) || campaign.maker == address(0), "not able to join");

    // create a ref
    require(campaign.startTimestamp + CAMPAIGN_DURATION > block.timestamp, "campaign has been ended");
    bool isMaker = true;
    if (campaign.maker == address(0)) {
      campaign.maker = msg.sender;
    } else if (campaign.ambusher == address(0) && msg.sender != campaign.maker) {
      require(campaign.startTimestamp + 1 hours > block.timestamp, "cannot make an ambush after 1 hour");
      campaign.ambusher = msg.sender;
      isMaker = false;
    } else {
      return;
    }

    for (uint256 i = 0; i < LENGTH; i++) {
      require(nft.getLevel(_tokenIds[i]) >= campaign.tier * 10, "invalid nft level");
      campaign.reinforceTimestamps.push(block.timestamp);
      nft.transferFrom(msg.sender, address(this), _tokenIds[i]);
      if (isMaker) {
        campaign.defenseNFTs.push(_tokenIds[i]);
        campaign.defensePoint += nft.getDefense(_tokenIds[i]) + nft.getEndurance(_tokenIds[i]);
      } else {
        campaign.attackNFTs.push(_tokenIds[i]);
        campaign.attackPoint += nft.getAttack(_tokenIds[i]) + nft.getEndurance(_tokenIds[i]);
      }
    }
    joinedCampaigns[msg.sender].push(_id);
  }

  function reinforceAttack(uint256 _id, uint256 _tokenId) external whenNotPaused {
    require(_id < totalCampaigns, "campaign does not exist");

    // create a ref
    Campaign storage campaign = campaigns[_id];

    require(campaign.startTimestamp < block.timestamp, "campaign has not been started yet");
    require(campaign.startTimestamp + CAMPAIGN_DURATION > block.timestamp, "campaign has been ended");
    require(campaign.ambusher == msg.sender, "invalid ambusher");
    // require(campaign.reinforceTimestamps.length % 2 == 0, "invalid turn");
    require(campaign.defenseNFTs.length == campaign.attackNFTs.length + 1, "invalid turn");

    if (campaign.reinforceTimestamps.length > 0) {
      uint256 lastTimestamp = campaign.reinforceTimestamps[campaign.reinforceTimestamps.length - 1];
      require(lastTimestamp + WINDOW_DURATION >= block.timestamp, "not proper timing");
    }

    campaign.reinforceTimestamps.push(block.timestamp);
    campaign.attackNFTs.push(_tokenId);
    nft.transferFrom(msg.sender, address(this), _tokenId);
    uint256 reinforcePercent = 10000;
    if (nft.getLevel(_tokenId) < campaign.tier * 10) {
      reinforcePercent = 10000 - penaltyAmountBp;
    }
    if (nft.getClass(_tokenId) == campaign.tier) {
      reinforcePercent += boostAmountBp;
    }
    campaign.attackPoint += (nft.getAttack(_tokenId) + nft.getEndurance(_tokenId)) * reinforcePercent / 10000;
  }

  function reinforceDefense(uint256 _id, uint256 _tokenId) external whenNotPaused {
    require(_id < totalCampaigns, "campaign does not exist");

    // create a ref
    Campaign storage campaign = campaigns[_id];
    require(campaign.startTimestamp < block.timestamp, "campaign has not been started yet");
    require(campaign.startTimestamp + CAMPAIGN_DURATION > block.timestamp, "campaign has been ended");
    require(campaign.maker == msg.sender, "invalid maker");
    require(campaign.defenseNFTs.length == campaign.attackNFTs.length ,"invalid turn");
    
    if (campaign.reinforceTimestamps.length > 0) {
      uint256 lastTimestamp = campaign.reinforceTimestamps[campaign.reinforceTimestamps.length - 1];
      require(lastTimestamp + WINDOW_DURATION >= block.timestamp, "not proper timing");
    }

    campaign.reinforceTimestamps.push(block.timestamp);
    campaign.defenseNFTs.push(_tokenId);
    nft.transferFrom(msg.sender, address(this), _tokenId);
    uint256 reinforcePercent = 10000;
    if (nft.getLevel(_tokenId) < campaign.tier * 10) {
      reinforcePercent = 10000 - penaltyAmountBp;
    }
    if (nft.getClass(_tokenId) == campaign.tier) {
      reinforcePercent += boostAmountBp;
    }
    campaign.defensePoint += (nft.getAttack(_tokenId) + nft.getEndurance(_tokenId)) * reinforcePercent / 10000;
  }

  function finishCampaign(uint256 _id) external whenNotPaused {
    Campaign storage campaign = campaigns[_id];
    require(campaign.startTimestamp + CAMPAIGN_DURATION <= block.timestamp, "Not able to finish");
    // require(msg.sender == campaign.maker || msg.sender == campaign.ambusher, "no permission");
    require(msg.sender == campaign.maker, "no permission");

    address winner = campaign.maker;
    address loser = campaign.maker;
    bool isDefenseWinner = campaign.defensePoint >= campaign.attackPoint; //checkCampaignerWin(_id);
    uint256 aveLevel = 0;
    if (isDefenseWinner) {
      loser = campaign.ambusher;
      for (uint256 i = 0; i < campaign.defenseNFTs.length; i++) {
        aveLevel += campaign.defenseNFTs[i];
      }
      aveLevel /= campaign.defenseNFTs.length;
    } else {
      winner = campaign.ambusher;
      for (uint256 i = 0; i < campaign.attackNFTs.length; i++) {
        aveLevel += campaign.attackNFTs[i];
      }
      aveLevel /= campaign.attackNFTs.length;
    }

    if (isDefenseWinner) {
      honToken.safeTransfer( winner, honFee[aveLevel]);
      hrmToken.safeTransfer( winner, hrmFee[aveLevel]);
    } else {
      honToken.safeTransfer( winner, honFee[aveLevel] * 70 / 100);
      hrmToken.safeTransfer( winner, hrmFee[aveLevel] * 70 / 100);
      honToken.safeTransfer( loser, honFee[aveLevel] * 30 / 100);
      hrmToken.safeTransfer( loser, hrmFee[aveLevel] * 30 / 100);
    }

    // for (uint256 i = 0; i < campaign.attackNFTs.length; i++) {
    //   nft.transferFrom(address(this), campaign.ambusher, campaign.attackNFTs[i]);
    // }
    for (uint256 i = 0; i < campaign.defenseNFTs.length; i++) {
      nft.transferFrom(address(this), campaign.maker, campaign.defenseNFTs[i]);
    }
  }

  function createSingleCampaign(uint256 _tier) internal {
    totalCampaigns ++;

    uint256[] memory emptyArray = new uint256[](0);
    campaigns.push(
      Campaign({
        startTimestamp: block.timestamp, tier: _tier, maker: address(0), ambusher: address(0), area: random(4, 0),
        reinforceTimestamps: emptyArray, attackNFTs: emptyArray, defenseNFTs: emptyArray,
        attackPoint: 0, defensePoint: 0
      })
    );
  }

  function createAndParticipateCampaign(uint256 _tier, uint256[] calldata _tokenIds) external whenNotPaused {
    createSingleCampaign(_tier);
    participate(totalCampaigns - 1, _tokenIds);
  }

  function changeFee(uint256[] calldata _honFee, uint256[] calldata _hrmFee) external onlyOwner {
    require(_honFee.length == 50, "_honFee array sizes should be 5");
    require(_hrmFee.length == 50, "_hrmFee array sizes should be 5");

    for (uint256 i = 0; i < 50; i++) {
      honFee[i] = _honFee[i];
      hrmFee[i] = _hrmFee[i];
    }
  }

  function setpenaltyAmountBp(uint256 _penaltyAmountBp) public onlyOwner {
    penaltyAmountBp = _penaltyAmountBp;
  }

  function setBoostAmountBp(uint256 _boostAmountBp) public onlyOwner {
    boostAmountBp = _boostAmountBp;
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
    honToken.transferFrom(msg.sender, address(this), honToken.balanceOf(address(this)));
    honToken.transferFrom(msg.sender, address(this), honToken.balanceOf(address(this)));
  }

  function random(uint module, uint param) private view returns (uint) {
    uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) + param ;
    return randomHash % module;
  }

  function unlockAttackNFTs(uint256 _campaignId) external {
    require(_campaignId < totalCampaigns, "campaign does not exist");
    Campaign storage campaign = campaigns[_campaignId];
    require(campaign.ambusher == msg.sender, "!ambusher");
    uint256 reinforceAttackLength = campaign.attackNFTs.length;
    require(campaign.reinforceTimestamps[reinforceAttackLength * 2 - 1] + 1 hours < block.timestamp, "!try later");

    for (uint256 i = 0; i < reinforceAttackLength; i++) {
      nft.transferFrom(address(this), msg.sender, campaign.defenseNFTs[i]);
    }
  }

  /// @dev Pause the oprations
  function pause() public onlyOwner whenNotPaused {
    _pause();
  }

  /// @dev Unpause
  function unpause() public onlyOwner whenPaused {
    _unpause();
  }

  // function for testing
  function emergencyWithdrawNFT(uint256 _tokenId) external onlyOwner {
    nft.transferFrom(address(this), msg.sender, _tokenId);
  }

  function getNFTLevel(uint256 _tokenId) public view returns(uint256) {
    return nft.getLevel(_tokenId);
  }

  function getNFTAttack(uint256 _tokenId) public view returns(uint256) {
    return nft.getAttack(_tokenId);
  }

  function getNFTDefense(uint256 _tokenId) public view returns(uint256) {
    return nft.getDefense(_tokenId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IHeroesToken is IERC721{
    function getLevel(uint256 _tokenId) external view returns (uint256);

    function getAttack(uint256 _tokenId) external view returns (uint256);

    function getDefense(uint256 _tokenId) external view returns (uint256);

    function getEndurance(uint256 _tokenId) external view returns (uint256);

    function getClass(uint256 _tokenId) external view returns (uint256);

    function pause() external;

    function unpause() external;
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