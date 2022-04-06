// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IOptionsDEX.sol";

/*
Options DEX smart contract
*/
contract OptionsDEX is IOptionsDEX {

    struct Option {
        // Address of ERC20 asset
        address asset;
        // Right to buy token at strikePrice (in Wei)
        uint96 strikePrice;
        // Address of option writer
        address writer;
        // Premium per token (in Wei)
        uint96 premium;
        // Address of option holder
        address holder;
        // Expiration block #
        uint96 blockExpiration;
        // Holder's sell price (if existent) (in Wei)
        uint128 holderSellPrice;
        // Writer's sell price (if existent) (in Wei)
        uint128 writerSellPrice;
    }

    // Hash of option to option
    mapping(bytes32 => Option) private openOptions;
    // Address to nonce
    mapping(address => uint256) private addressNonce;
    // Hash of option to approved new holder
    mapping(bytes32 => address) private approvedHolderAddress;
    // Hash of option to approved new writer
    mapping(bytes32 => address) private approvedWriterAddress;

    // Mapping of approved asset addresses
    mapping (address => bool) private approvedAssets;

    // Event detailing creation of new option
    event OptionCreated(address indexed seller, bytes32 indexed optionHash);

    // Event detailing purchase of an option either by a holder or writer
    event OptionExchanged(bytes32 indexed optionHash);

    // Constructor sets the addresses of approved option assets. There are 10 approved assets that utilize 18 decimals.
    // TO NOT BE RESTRICTED BY ASSETS, REMOVE CONSTRUCTOR AND ANY LINES OF CODE THAT CONTAINS A (*) IN THE LINE ABOVE IT
    constructor() {
        // Setting addresses of approved assets
        // Wrapped AVAX
        approvedAssets[0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7] = true;
        // Shiba Inu
        approvedAssets[0x02D980A0D7AF3fb7Cf7Df8cB35d9eDBCF355f665] = true;
        // Chainlink Token
        approvedAssets[0x5947BB275c521040051D82396192181b413227A3] = true;
        // Maker Token
        approvedAssets[0x88128fd4b259552A9A1D457f435a6527AAb72d42] = true;
        // Uniswap Token
        approvedAssets[0x8eBAf22B6F053dFFeaf46f4Dd9eFA95D89ba8580] = true;
        // Graph Token
        approvedAssets[0x8a0cAc13c7da965a312f08ea4229c37869e85cB9] = true;
        // AAVE Token
        approvedAssets[0x63a72806098Bd3D9520cC43356dD78afe5D386D9] = true;
        // CurveDAO Token
        approvedAssets[0x249848BeCA43aC405b8102Ec90Dd5F22CA513c06] = true;
        // Sushi Token
        approvedAssets[0x37B608519F91f70F2EeB0e5Ed9AF4061722e4F76] = true;
        // Spell Token
        approvedAssets[0xCE1bFFBD5374Dac86a2893119683F4911a2F7814] = true;
    }

    /*
    Function that creates an option. 

    Parameters: 
        _asset: the contract address of the underlying asset, must be approved
        _premium: the premium per token of the option
        _strikePrice: the assigned price of the underlying asset
        _blockExpiration: the expiration of the option (in terms of block number), must be less than 2^96-1 and greater than the current block number
    */
    function createOption(address _asset, uint96 _premium, uint96 _strikePrice, uint96 _blockExpiration) public override {
        // Enforce preconditions
        // Check that _blockExpiration is for future block
        require(_blockExpiration > block.number, "Invalid block expiration!");
        // Check that _premium is a valid number
        require(_premium > 0, "Invalid premium!");
        // Check that _strikePrice is a valid number
        require(_strikePrice > 0, "Invalid strike price!");
        // (*) Check that asset is allowed
        require(approvedAssets[_asset], "Asset is not allowed!");

        // Create option
        Option memory _option = Option(_asset, _strikePrice, msg.sender, _premium, address(0), _blockExpiration, 0, 0);
        // Create hash for option
        bytes32 _optionHash = keccak256(abi.encode(_option, addressNonce[msg.sender], msg.sender));
        // Add option to mapping
        openOptions[_optionHash] = _option;
        // Increment account nonce
        addressNonce[msg.sender] += 1;

        // Create interface
        IERC20 _token = IERC20(_asset);
        // Check that user has enough tokens to cover option
        require(_token.balanceOf(msg.sender) >= 10 ** 20, "Not enough tokens to cover option!");
        // Transfer 100 tokens to smart contract
        _token.transferFrom(msg.sender, address(this), 10 ** 20);

        // Emit new option
        emit OptionCreated(msg.sender, _optionHash);
    }

    /*
    Function that allows an account to purchase the rights to an option
    Parameters:
        _optionHash: the hash of the option being purchased
    The correct amount of AVAX must be sent with this transaction, otherwise the transaction will revert!
    */
    function buyOption(bytes32 _optionHash) payable public override {
        // Fetch option from storage
        Option memory _option = openOptions[_optionHash];
        // Check that option exists
        require(_option.blockExpiration != 0, "This option does not exist!");
        // Check premium * 100 is equal to eth sent
        require(msg.value == _option.premium * 100, "Incorrect amount sent!");
        // Check option does not already have holder
        require(_option.holder == address(0), "This option has already been bought!");

        // Set holder directly in storage
        openOptions[_optionHash].holder = msg.sender;
        // Send eth to writer
        (bool sent, ) = _option.holder.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        // Emit option buy
        emit OptionExchanged(_optionHash);
    }

    /*
    Function that approves the next holder of an option
    Parameters:
        _optionHash: the hash of the option being purchased
        _newBuyer: the address of the approved next holder
        _price: the price at which the next holder will purchase the option at
    */
    function approveOptionTransferHolder(bytes32 _optionHash, address _newBuyer, uint128 _price) public override {
        // Fetch option from storage
        Option memory _option = openOptions[_optionHash];
        // Check that option exists
        require(_option.blockExpiration != 0, "This option does not exist!");
        // Check that current holder is calling this option
        require(msg.sender == _option.holder, "You are not the current holder!");

        // Set holderSellPrice for option
        openOptions[_optionHash].holderSellPrice = _price;
        // Add _newBuyer to approved addresses
        approvedHolderAddress[_optionHash] = _newBuyer;
    }

    /*
    Function that allows the approved next holder to obtain the rights to an option
    Parameters:
        _optionHash: the hash of the option being transferred
    The correct amount of AVAX must be sent with this transaction, otherwise the transaction will revert!
    */
    function transferOptionHolder(bytes32 _optionHash) public payable override {
        // Check that msg.sender has permission
        require(approvedHolderAddress[_optionHash] == msg.sender, "You are not authorized!");
        // Fetch option from storage
        Option memory _option = openOptions[_optionHash];
        // Check that option exists
        require(_option.blockExpiration != 0, "This option does not exist!");
        // Check that msg.value is equal to holder's sell price
        require(_option.holderSellPrice == msg.value, "Incorrect amount sent!");

        // Change option holder
        openOptions[_optionHash].holder = msg.sender;
        // Delete approved address
        delete approvedHolderAddress[_optionHash];

        // Send ETH to past holder
        (bool sent, ) = _option.holder.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

    }

    /*
    Function that approves the next writer of an option.
    Parameters:
        _optionHash: the hash of the particular option
        _newWriter: the address of the next writer
        _price: the price whicht the next writer will purchase the option at
    */
    function approveOptionTransferWriter(bytes32 _optionHash, address _newWriter, uint128 _price) public override {
         // Fetch option from storage
        Option memory _option = openOptions[_optionHash];
        // Check that option exists
        require(_option.blockExpiration != 0, "This option does not exist!");
        // Check that current holder is calling this option
        require(msg.sender == _option.writer, "You are not the current holder!");

        // Set holderSellPrice for option
        openOptions[_optionHash].writerSellPrice = _price;
        // Add _newBuyer to approved addresses
        approvedWriterAddress[_optionHash] = _newWriter;
    }

    /*
    Function that allows the approved next writer of an option to purchase the option.
    Parameters:
        _optionHash: the hash of the particular option
    The correct amount of AVAX must be sent with this transaction, otherwise the transaction will revert! In addition, the approved next writer must have already approved for OptionsDEX to transfer their tokens to the smart contract, otherwise the transaction will revert
    */
    function transferOptionWriter(bytes32 _optionHash) public payable override {
        // Check that msg.sender has permission
        require(approvedWriterAddress[_optionHash] == msg.sender, "You are not authorized!");
        // Fetch option from storage
        Option memory _option = openOptions[_optionHash];
        // Check that option exists
        require(_option.blockExpiration != 0, "This option does not exist!");
        // Check that msg.value is equal to holder's sell price
        require(_option.writerSellPrice == msg.value, "Incorrect amount sent!");
        // Check that msg.sender has enough assets to cover option
        // Create interface
        IERC20 _token = IERC20(_option.asset);
        // Check that msg.sender has enough tokens
        require(_token.balanceOf(msg.sender) >= 10 ** 20, "You do not have the assets necessary to cover this call");

        // Send tokens back to original writer
        _token.transfer(_option.writer, 10 ** 20);
        // Get tokens from msg.sender
        _token.transferFrom(msg.sender, address(this), 10 ** 20);

        // Change option writer
        openOptions[_optionHash].writer = msg.sender;
        // Delete approved address
        delete approvedWriterAddress[_optionHash];

        // Send ETH to past writer
        (bool sent, ) = _option.writer.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    /*
    Function that allows the current holder of an option to exercise their rights to an option
    Parameters: 
        _optionHash: the hash of the option being exercised
    The correct amount of AVAX must be sent with this transaction, otherwise the transaction will revert!
    */
    function exerciseOption(bytes32 _optionHash) public payable override {
        // Fetch option from storage
        Option memory _option = openOptions[_optionHash];
        // Check that option exists
        require(_option.blockExpiration != 0, "This option does not exist!");
        // Check that msg.sender is current holder
        require(_option.holder == msg.sender, "You are not the holder!");
        // Check that eth sent = strikePrice * 100
        require(msg.value == _option.strikePrice * 100, "Incorrect amount sent!");

        // Send tokens to msg.sender
        IERC20 _token = IERC20(_option.asset);
        _token.transfer(msg.sender, 10 ** 20);

        // Delete option
        delete openOptions[_optionHash];
        // Delete approvals
        delete approvedHolderAddress[_optionHash];
        delete approvedWriterAddress[_optionHash];
        // Send ETH to writer
        (bool sent, ) = _option.holder.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    /*
    Function that allows the writer of an option to 'cancel' their option if either a buyer has not been assigned or the option is past its expiration date
    Parameters:
        _optionHash: the hash of the particular option
    */
    function refund(bytes32 _optionHash) public override {
        // Fetch option from storage and check if it is valid
        Option memory _option = openOptions[_optionHash]; 
        // Check that option is past block expiration or that no buyer has been assigned
        require(block.number > _option.blockExpiration || _option.holder == address(0), "You are not able to be refunded!");
        // Check that msg.sender is the option writer
        require(msg.sender == _option.writer, "You are not the option writer!");

        // Send 100 tokens back to seller
        IERC20 _token = IERC20(_option.asset);
        _token.transfer(msg.sender, 10 ** 20);

        // Delete option from storage
        delete openOptions[_optionHash];
        delete approvedHolderAddress[_optionHash];
        delete approvedWriterAddress[_optionHash];
    }

    /*
    Function that returns information about a particular option in the form of a tuple
    Parameters:
        _optionHash: the hash of the option being querried
    */
    function getOptionDetails(bytes32 _optionHash) public view override returns(address, uint96, address, uint96, address, uint96, uint128, uint128) {
        // Fetch option from storage
        Option memory _option = openOptions[_optionHash];
        // Return option as tuple
        return (_option.asset, _option.strikePrice, _option.writer, _option.premium, _option.holder, _option.blockExpiration, _option.holderSellPrice, _option.writerSellPrice);
    }

    /*
    Function that returns the current approved next holder of an option
    Parameters:
        _optionHash: the hash of the option being queried
    */
    function viewHolderApproval(bytes32 _optionHash) external view override returns (address) {
        return approvedHolderAddress[_optionHash];
    }

    /*
    Function that returns the current approved next writer of an option
    Parameters:
        _optionHash: the hash of the option being queried
    */
    function viewWriterApproval(bytes32 _optionHash) external view override returns (address) {
        return approvedWriterAddress[_optionHash];
    }

    /*
    Function that returns a boolean representing whether if a smart contract address is an approved underlying asset for options on OptionsDEX
    Parameters:
        _asset: the address of the asset being queried
    */
    function isApprovedAsset(address _asset) external view override returns(bool) {
        return approvedAssets[_asset];
    }

    receive() external payable override {}
}