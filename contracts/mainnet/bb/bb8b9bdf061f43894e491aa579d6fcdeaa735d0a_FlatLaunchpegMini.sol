/**
 *Submitted for verification at snowtrace.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT

/*
 * Subset of required Flat NFT functionality for bot testing.
 */

pragma solidity ^0.8.4;

/// @title FlatLaunchpeg
/// @author Trader Joe
/// @notice Implements a simple minting NFT contract with an allowlist and public sale phase.
contract FlatLaunchpegMini {
    /// @notice Price of one NFT for people on the mint list
    /// @dev allowlistPrice is scaled to 1e18
    uint256 public allowlistPrice;

    /// @notice Price of one NFT during the public sale
    /// @dev salePrice is scaled to 1e18
    uint256 public salePrice;

    // state variable for allowlist start
    uint256 public allowlistStartTime;

    // state variable for sales price
    uint256 public publicSaleStartTime;

    // datatype for different mint phases
    enum Phase {
        NotStarted,
        DutchAuction,
        Allowlist,
        PublicSale
    }

    /// @dev Emitted on initializePhases()
    /// @param allowlistStartTime Allowlist mint start time in seconds
    /// @param publicSaleStartTime Public sale start time in seconds
    /// @param allowlistPrice Price of the allowlist sale in Avax
    /// @param salePrice Price of the public sale in Avax
    event Initialized(
        uint256 allowlistStartTime,
        uint256 publicSaleStartTime,
        uint256 allowlistPrice,
        uint256 salePrice
    );

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // copied function to check balance
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    // state variable for allowlist amounts per user
    mapping(address => uint256) public allowlist;

    // helper function for setting allowlist
    function setAllowlist(address[] calldata users, uint256 quantity) external {
        for (uint i=0; i<users.length; i++) {
            allowlist[users[i]]=quantity;
        }
    }

    modifier atPhase(Phase _phase) {
        if (currentPhase() != _phase) {
            revert("wrong_phase");
        }
        _;
    }

    /// @notice Initialize the two phases of the sale
    /// @dev Can only be called once
    /// @param _allowlistStartTime Allowlist mint start time in seconds
    /// @param _publicSaleStartTime Public sale start time in seconds
    /// @param _allowlistPrice Price of the allowlist sale in Avax
    /// @param _salePrice Price of the public sale in Avax
    function initializePhases(
        uint256 _allowlistStartTime,
        uint256 _publicSaleStartTime,
        uint256 _allowlistPrice,
        uint256 _salePrice
    ) external { // atPhase(Phase.NotStarted), onlyOwner removed for re-testing
        if (_allowlistStartTime < block.timestamp) {
            revert("Launchpeg__InvalidStartTime");
        }
        if (_publicSaleStartTime < _allowlistStartTime) {
            revert("Launchpeg__PublicSaleBeforeAllowlist");
        }
        if (_allowlistPrice > _salePrice) {
            revert("Launchpeg__InvalidAllowlistPrice");
        }

        salePrice = _salePrice;
        allowlistPrice = _allowlistPrice;

        allowlistStartTime = _allowlistStartTime;
        publicSaleStartTime = _publicSaleStartTime;

        emit Initialized(
            allowlistStartTime,
            publicSaleStartTime,
            allowlistPrice,
            salePrice
        );
    }

    /// @dev Verifies that enough AVAX has been sent by the sender and refunds the extra tokens if any
    /// @param _price The price paid by the sender for minting NFTs
    function _refundIfOver(uint256 _price) internal {
        if (msg.value < _price) {
            revert("Launchpeg__NotEnoughAVAX");
        }
        if (msg.value > _price) {
            (bool success, ) = msg.sender.call{value: msg.value - _price}("");
            if (!success) {
                revert("Launchpeg__TransferFailed");
            }
        }
    }

    /// @notice Mint NFTs during the allowlist mint
    /// @param _quantity Quantity of NFTs to mint
    function allowlistMint(uint256 _quantity)
        external
        payable
        atPhase(Phase.Allowlist)
    {
        if (_quantity > allowlist[msg.sender]) { // bot only able to mint one NFT so irrelevant check
            revert("Launchpeg__NotEligibleForAllowlistMint");
        }
        /*if ( // maxSupply is not relevant for testing
            totalSupply() + _quantity > collectionSize ||
            amountMintedDuringAllowlist + _quantity > amountForAllowlist
        ) {
            revert ("Launchpeg__MaxSupplyReached");
        }*/
        allowlist[msg.sender] -= _quantity;
        uint256 totalCost = allowlistPrice * _quantity;

        _balances[msg.sender] += 1; // replacing: _mint(msg.sender, _quantity, "", false);
        // amountMintedDuringAllowlist += _quantity; // irrelevant
        /*emit Mint( // not incorporated in minting bot
            msg.sender,
            _quantity,
            allowlistPrice,
            _totalMinted() - _quantity
        );*/
        _refundIfOver(totalCost);
    }

    /// @notice Returns the current phase
    /// @return phase Current phase
    function currentPhase() public view returns (Phase) {
        if (
            allowlistStartTime == 0 ||
            publicSaleStartTime == 0 ||
            block.timestamp < allowlistStartTime
        ) {
            return Phase.NotStarted;
        } else if (
            block.timestamp >= allowlistStartTime &&
            block.timestamp < publicSaleStartTime
        ) {
            return Phase.Allowlist;
        }
        return Phase.PublicSale;
    }

}