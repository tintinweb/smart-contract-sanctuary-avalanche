// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

/// @title Potion Run Badges
/// @author Memepanze
/** @notice Badges contract for Plague Game.
* Player can Mint 1 ERC1155 badge if he makes an achievement in the game.
*/

contract PotionRunBadges is ERC1155, ERC1155Supply, ReentrancyGuard, Ownable {
    using Strings for uint256;

    constructor() ERC1155(""){
        name = "Potion Run Badges";
        symbol = "PRB";
        _uriBase = "ipfs://bafybeidt3utae2ccqdcvirhcph5rnif2jxu33k2szovgpvrechyfcjdht4/"; // IPFS base for ChadSports collection
    }

    /// @notice The Name of collection 
    string public name;
    /// @notice The Symbol of collection 
    string public symbol;
    /// @notice The URI Base for the metadata of the collection 
    string public _uriBase;

    /// @notice royalties recipient address
    address public _recipient;

    address[] public tournamentContracts;

    // E V E N T S
    /// @notice Emitted on withdrawBalance() 
    event BalanceWithdraw(address to, uint amount);

    // E R R O R S

    error PR__Unauthorized();

    error PR__NotInTheMitingPeriod();

    error PR__TransferFailed();

    // M I N T

    /// @notice Mint function
    /// @param _playerAddress.
    function mint(address _playerAddress, uint _badgeId) external
    {   
        int indexOfContract = indexOfAddresses(tournamentContracts, msg.sender);
        require(indexOfContract > -1, "Not allowed contract");
            _mint(_playerAddress, _badgeId, 1, "");
    }

    /// @notice add a tournament contract to the array of contracts
    function addTournamentContract(address _contract) external onlyOwner {
        tournamentContracts.push(_contract);
    }

    /// @notice remove a tournament contract from the array of contracts
    function removeTournamentContract(address _contract) external onlyOwner {
        int _index = indexOfAddresses(tournamentContracts, _contract);
        if(_index>-1){
            for(uint i = uint256(_index); i < tournamentContracts.length-1; i++){
                tournamentContracts[i] = tournamentContracts[i+1];
            }
            tournamentContracts.pop();
        }
        
    }

    /// @notice Checks the index of a value in an array.
    /// @param arr The array of values to check.
    /// @param searchFor The value to search for inside of the array.
    /// @return The index of the value inside of the array, if the value doesn't exist it returns "-1".
    function indexOf(uint256[] memory arr, uint256 searchFor) internal pure returns (int256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return int(i);
            }
        }
        return -1; // not found
    }

    /// @notice Checks the index of a value in an array.
    /// @param arr The array of values to check.
    /// @param searchFor The value to search for inside of the array.
    /// @return The index of the value inside of the array, if the value doesn't exist it returns "-1".
    function indexOfAddresses(address[] memory arr, address searchFor) internal pure returns (int256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return int(i);
            }
        }
        return -1; // not found
    }

    /// @notice Set the new base URI for the collection.
    function setUriBase(string memory _newUriBase) external onlyOwner {
        _uriBase = _newUriBase;
    }

    /// @notice URI override for OpenSea traits compatibility.
    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_uriBase, tokenId.toString(), ".json"));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    

    /// @notice Withdraw the contract balance to the contract owner
    /// @param _to Recipient of the withdrawal
    function withdrawBalance(address _to) external onlyOwner nonReentrant {
        uint amount = address(this).balance;
        bool sent;

        (sent, ) = _to.call{value: amount}("");
        if (!sent) {
            revert PR__TransferFailed();
        }

        emit BalanceWithdraw(_to, amount);
    }

    /// @notice withdraw ERC20
    function withdrawToken(address _tokenContract, address _to) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint amount = tokenContract.balanceOf(address(this));
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(_to, amount);
    }

}