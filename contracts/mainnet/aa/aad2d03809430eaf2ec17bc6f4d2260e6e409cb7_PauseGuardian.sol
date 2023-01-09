/**
 *Submitted for verification at snowtrace.io on 2023-01-09
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/AutomationBase.sol


pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/AutomationCompatible.sol


pragma solidity ^0.8.0;



abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PauseGuardian.sol

pragma solidity ^0.8;



interface Comptroller {
    function getAllMarkets() external view returns (address[] memory);
    function mintGuardianPaused(address market) external view returns (bool);
    function borrowGuardianPaused(address market) external view returns (bool);
    function _setMintPaused(address qiToken, bool state) external returns (bool);
    function _setBorrowPaused(address qiToken, bool state) external returns (bool);
    function _setTransferPaused(bool state) external returns (bool);
    function _setSeizePaused(bool state) external returns (bool);
}

interface ProofOfReserveFeed {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

interface QiToken {
    function underlying() external view returns (address);
}

interface UnderlyingToken {
    function totalSupply() external view returns (uint);
}

contract PauseGuardian is Ownable, AutomationCompatible {
    Comptroller public constant comptroller = Comptroller(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);

    address[] public markets;
    mapping(address => address) public proofOfReserveFeeds;

    constructor() {
        transferOwnership(0x30d62267874DdA4D32Bb28ddD713f77d1aa99159);

        // BTC.b
        _setProofOfReserveFeed(0x89a415b3D20098E6A6C8f7a59001C67BD3129821, 0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9);

        // DAI.e
        _setProofOfReserveFeed(0x835866d37AFB8CB8F8334dCCdaf66cf01832Ff5D, 0x976D7fAc81A49FA71EF20694a3C56B9eFB93c30B);

        // LINK.e
        _setProofOfReserveFeed(0x4e9f683A27a6BdAD3FC2764003759277e93696e6, 0x943cEF1B112Ca9FD7EDaDC9A46477d3812a382b6);

        // WBTC.e
        _setProofOfReserveFeed(0xe194c4c5aC32a3C9ffDb358d9Bfd523a0B6d1568, 0xebEfEAA58636DF9B20a4fAd78Fad8759e6A20e87);

        // WETH.e
        _setProofOfReserveFeed(0x334AD834Cd4481BB02d09615E7c11a00579A7909, 0xDDaf9290D057BfA12d7576e6dADC109421F31948);
    }

    function pauseMintingAndBorrowingForAllMarkets() external onlyOwner {
        _pauseMintingAndBorrowingForAllMarkets();
    }

    function _pauseMintingAndBorrowingForAllMarkets() internal {
        address[] memory allMarkets = comptroller.getAllMarkets();
        uint marketCount = allMarkets.length;

        for (uint i; i < marketCount; ++i) {
            comptroller._setMintPaused(allMarkets[i], true);
            comptroller._setBorrowPaused(allMarkets[i], true);
        }
    }

    function pauseMintingAndBorrowingForMarket(address qiToken) external onlyOwner {
        comptroller._setMintPaused(qiToken, true);
        comptroller._setBorrowPaused(qiToken, true);
    }

    function pauseMinting(address qiToken) external onlyOwner {
        comptroller._setMintPaused(qiToken, true);
    }

    function pauseBorrowing(address qiToken) external onlyOwner {
        comptroller._setBorrowPaused(qiToken, true);
    }

    function pauseTransfers() external onlyOwner {
        comptroller._setTransferPaused(true);
    }

    function pauseLiquidations() external onlyOwner {
        comptroller._setSeizePaused(true);
    }

    function proofOfReservesPause() public {
        require(_canPause(), "Proof of reserves are OK");

        _pauseMintingAndBorrowingForAllMarkets();
    }

    function _canPause() internal view returns (bool) {
        uint marketCount = markets.length;

        for (uint i; i < marketCount; ++i) {
            address qiTokenAddress = markets[i];
            ProofOfReserveFeed proofOfReserveFeed = ProofOfReserveFeed(proofOfReserveFeeds[qiTokenAddress]);

            uint underlyingTokenTotalSupply = UnderlyingToken(QiToken(qiTokenAddress).underlying()).totalSupply();
            (, int256 proofOfReserveAnswer, , ,) = proofOfReserveFeed.latestRoundData();

            if (underlyingTokenTotalSupply > uint256(proofOfReserveAnswer)) {
                return true;
            }
        }

        return false;
    }

    function canPause() external view returns (bool) {
        return _canPause();
    }

    function _areAllMarketsPaused() internal view returns (bool) {
        address[] memory allMarkets = comptroller.getAllMarkets();
        uint marketCount = allMarkets.length;

        for (uint i; i < marketCount; ++i) {
            if (!comptroller.mintGuardianPaused(allMarkets[i]) || !comptroller.borrowGuardianPaused(allMarkets[i])) {
                return false;
            }
        }

        return true;
    }

    function areAllMarketsPaused() external view returns (bool) {
        return _areAllMarketsPaused();
    }

    function setProofOfReserveFeed(address qiToken, address feed) external onlyOwner {
        _setProofOfReserveFeed(qiToken, feed);
    }

    function _setProofOfReserveFeed(address qiToken, address feed) internal {
        if (proofOfReserveFeeds[qiToken] == address(0)) {
            markets.push(qiToken);
        }

        proofOfReserveFeeds[qiToken] = feed;
    }

    function removeProofOfReserveFeed(address qiToken) external onlyOwner {
        delete proofOfReserveFeeds[qiToken];

        uint marketCount = markets.length;
        for (uint i; i < marketCount; ++i) {
            if (markets[i] == qiToken) {
                if (i != marketCount - 1) {
                    markets[i] = markets[marketCount - 1];
                }

                markets.pop();
                break;
            }
        }
    }

    function checkUpkeep(bytes calldata) external view returns (
        bool upkeepNeeded,
        bytes memory performData
    ) {
        upkeepNeeded = _canPause() && !_areAllMarketsPaused();
        performData = new bytes(0);
    }

    function performUpkeep(bytes calldata) external {
        proofOfReservesPause();
    }
}