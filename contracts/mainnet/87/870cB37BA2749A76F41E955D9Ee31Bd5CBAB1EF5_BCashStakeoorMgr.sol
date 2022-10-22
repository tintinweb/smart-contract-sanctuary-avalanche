/**
 *Submitted for verification at snowtrace.io on 2022-10-22
*/

// SPDX-License-Identifier: MIT
// Butterfly Cash Stakoor Manager by xrpant

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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


interface IBCash {
    function balanceOf(address account) external view returns (uint256);
}

interface IBCashStakoor {
	function stake() external;
    function unStake() external;
    function bCashTransfer(address _to, uint256 _amount) external;
}

pragma solidity ^0.8.0;

contract BCashStakeoorMgr is Ownable, KeeperCompatibleInterface {
    uint256 public _cooldown = 86400;
    uint256 public _timestamp = 0;
    uint256 public _minTransfer = 5000 ether;

    bool public paused = false;

    IBCash _bc;

    address[29] public stakoors;
    mapping(address => address) public stakoorToPayee;
    mapping(address => bool) public excludeAddress;

    constructor() {
        _bc = IBCash(0x4BA16DaF8ed418deD920C66e45cc3eaFFDE53Ac7);
        // Exclude stakoor 1 as it will be a hold address for the contributors fund
        excludeAddress[0x6198d3f701645DF383C19766C50D939d1aA7B6Ae] = true;
        // Add all stakoors to the stakoors array
        stakoors[0] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoors[1] = 0xAF11c8336f4b0d6A91eb96Db58f5fa1783fce26E;
        stakoors[2] = 0x11bc52a5B56817b8962E919eB5451f32C696cFC1;
        stakoors[3] = 0x1b322cc442543796851cAF045849903315Add199;
        stakoors[4] = 0x5ef50cC88Db3e6cc5Cd0b7D865aBE30Ff9beE10f;
        stakoors[5] = 0x5cE163646a36B7fBfA702D56211691F695DcCCc9;
        stakoors[6] = 0x18Afa29c73E685590609D3f1d5Bd375AaD9CD6A6;
        stakoors[7] = 0xb77677b4a5a3C2B5D533c61c33cb3BCD78Fb9951;
        stakoors[8] = 0x655541Fe4d9E21B9039720FCa8ee2750Ee1dC96D;
        stakoors[9] = 0xb7F2D765728a4383b2492E7a6EB0542498701161;
        stakoors[10] = 0xA8f3ba358d92Aa5A6428A4AfC7a293A013109fBe;
        stakoors[11] = 0xF7fC6CD91A39a945CB95aCe30c2f990E2D727297;
        stakoors[12] = 0x9B6c5efC97D4C7735e83E7724B20519997Aa4aDD;
        stakoors[13] = 0xA01dB74a897183Ecf7a9c350c0AB5278F26274ec;
        stakoors[14] = 0xE2e08dA26a2668019fC6f791BB32583212388BD9;
        stakoors[15] = 0xcAcA417700e0eD56424003D2D6e6d1367C471700;
        stakoors[16] = 0xF223e10A40717b705EF060fc8aF3b0E9eE4e2E6E;
        stakoors[17] = 0x199271a8e94f693A316b1534D1A0AE39180B39B8;
        stakoors[18] = 0xeCaF031Bbc664ac2DF917019Ba76c7FFA8112015;
        stakoors[19] = 0x6a5E1cf2Fc4eAd0DC673D0E7bB63467abCCDf97e;
        stakoors[20] = 0xeEA6E71BbEB5E9869EB5b598D019C20eb6D238ba;
        stakoors[21] = 0xF960259fa9e88936573422Ddb6d69fB88994e37C;
        stakoors[22] = 0xd01255450E39D081Cd8645f18C4998908b61291E;
        stakoors[23] = 0x186cEEbff3390c47EaeE35f7D6221E427efE7E66;
        stakoors[24] = 0xceAcBA1F445Fd56AE6D77F8f76FBd1a0Aec4c742;
        stakoors[25] = 0x168a93436E9b3813578527f70947DB14eb9C85C3;
        stakoors[26] = 0xF364705eFCe1f1e502fBeA43675b648Ca95D94a6;
        stakoors[27] = 0x7BD504417FC499B54C8f2aAC5966285D435a105f;
        stakoors[28] = 0x523a25F504A56286940FdDFc8fCbf8E39d19cc06;
        // Assign where stakoor proceeds should be sent
        // At time of deploy, stakoors index 1-13 are sent to stakoor 1 (Index 0)
        stakoorToPayee[stakoors[1]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[2]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[3]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[4]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[5]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[6]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[7]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[8]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[9]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[10]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[11]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[12]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        stakoorToPayee[stakoors[13]] = 0x6198d3f701645DF383C19766C50D939d1aA7B6Ae;
        //At time of deploy stakoors index 14-28 are sent to the single-sided staking pool (sbCASH)
        stakoorToPayee[stakoors[14]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[15]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[16]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[17]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[18]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[19]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[20]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[21]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[22]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[23]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[24]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[25]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[26]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[27]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
        stakoorToPayee[stakoors[28]] = 0xa090463090EE99b8AbbBF8E6d0480CB5FDDDD1C6;
    }

    // Keepers Functions
    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;

        if (!paused &&
            block.timestamp > (_timestamp + _cooldown)) {
            upkeepNeeded = true;
        }

        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        require(!paused, "Contract paused!");
        
        for(uint i = 0; i < stakoors.length; i++) {
            address _stakoor  = stakoors[i];
            uint256 _balance = _bc.balanceOf(_stakoor);
            if (!excludeAddress[_stakoor] && _balance > _minTransfer) {
                IBCashStakoor s = IBCashStakoor(_stakoor);
                s.bCashTransfer(stakoorToPayee[_stakoor], _balance);
            }
        }
        _timestamp = block.timestamp;
    }

    // View Functions
    function getStakoors() public view returns(address[29] memory) {
        return stakoors;
    }

    function timeUntilNextTransfer() public view returns(uint) {
        if (_timestamp + _cooldown > block.timestamp) {
            return (_timestamp + _cooldown) - block.timestamp;
        } else {
            return 0;
        }
    }

    // Admin Functions

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function setCooldown(uint256 _newAmount) public onlyOwner {
        _cooldown = _newAmount;
    }

    function setTimestamp(uint256 _newAmount) public onlyOwner {
        _timestamp = _newAmount;
    }

    function setMinTransfer(uint256 _newAmount) public onlyOwner {
        _minTransfer = _newAmount;
    }

    function setPayee(address _stakoor, address _payee) public onlyOwner {
        stakoorToPayee[_stakoor] = _payee;
    }

    function setExcluded(address _stakoor, bool _excluded) public onlyOwner {
        excludeAddress[_stakoor] = _excluded;
    }

    function manualTransfer(address _stakoor, address _to, uint256 _amount) public onlyOwner {
        IBCashStakoor s = IBCashStakoor(_stakoor);
        s.bCashTransfer(_to, _amount);
    }

    function manualTransferAll(address _stakoor, address _to) public onlyOwner {
        IBCashStakoor s = IBCashStakoor(_stakoor);
        uint256 _amount = _bc.balanceOf(_stakoor);
        s.bCashTransfer(_to, _amount);
    }

}