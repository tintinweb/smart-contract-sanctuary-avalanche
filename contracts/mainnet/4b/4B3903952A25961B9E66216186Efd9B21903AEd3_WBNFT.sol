//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Whitelist.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract WBNFT is Whitelist, ERC721, ERC721Enumerable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter = Counters.Counter({_value: 9999});
    mapping(uint256 => string) private tokenURIs;
    string private baseURI;
    address payable private feeCollector;
    address private subContract;

    event MintedAction(
        string group,
        uint256 price,
        address to,
        uint256 amount,
        Item itemType
    );
    event MintedID(
        Item group,
        uint256 price,
        address to,
        uint256 tokenId,
        string tokenURI
    );

    // Address of the royalties recipient
    address payable private _royaltiesReceiver;

    // Percentage of each sale to pay as royalties, will be divided by 1000
    uint256 public constant ROYALTIES_PERCENTAGE = 35;

    // Mapping for minted token
    mapping(uint256 => bool) private _isMinted;

    /**
     * @notice Initiate Wynd and Rider as product and whitelist, for their qty is immutable
     * @param _feeCollector Address to receive feeCollector
     * @param __royaltiesReceiver Address to receive royalty
     * @param _initBaseURI URI to retrieve metadata
     */
    constructor(
        address _feeCollector,
        address __royaltiesReceiver,
        string memory _initBaseURI
    ) ERC721("WyndBlast NFT", "WBNFT") {
        // add allocation for presales
        addWhitelist(
            "WYND-PRESALES",
            Item.WyndGenesis,
            900000000000000000,
            500,
            5,
            false,
            true
        );
        addWhitelist(
            "RIDER-PRESALES",
            Item.RiderGenesis,
            500000000000000000,
            500,
            5,
            false,
            true
        );

        // add allocation for airdrop or free mint
        addWhitelist("WYND-AIRDROP", Item.WyndGenesis, 0, 80, 1, false, true);
        addWhitelist("RIDER-AIRDROP", Item.RiderGenesis, 0, 80, 1, false, true);

        // add Breeding and Recruiting whitelists
        addWhitelist("WYND-BREEDING", Item.WyndBreeding, 0, 10, 5, false, true);
        addWhitelist(
            "RIDER-RECRUITING",
            Item.RiderRecruiting,
            0,
            10,
            5,
            false,
            true
        );

        // add allocation for public sales
        addWhitelist(
            "WYND-SALES",
            Item.WyndGenesis,
            1500000000000000000,
            3920,
            5,
            true,
            false
        );
        addWhitelist(
            "RIDER-SALES",
            Item.RiderGenesis,
            1000000000000000000,
            3920,
            5,
            true,
            false
        );

        feeCollector = payable(_feeCollector);
        baseURI = _initBaseURI;

        /// set default royalties receiver
        _royaltiesReceiver = payable(__royaltiesReceiver);
    }

    modifier isSubContract() {
        require(msg.sender == subContract, "Invalid address");
        _;
    }

    /**
     * @notice Mint product
     * @param _group Group to identify whitelist
     * @param _tokenURI Extended uri to retrieve metadata
     * @param _amount Amount minted
     * @dev CALLED BY FRONTEND
     */
    function mint(
        string memory _group,
        string memory _tokenURI,
        uint256 _amount
    ) external payable returns (uint256) {
        // Get whitelist data first to define all required variables
        // See Whitelist.sol for details
        (
            Item itemType,
            uint256 itemPrice,
            uint256 itemQty,
            uint256 maxQty,
            uint256 consumedQty,
            ,
            bool isPublic,
            bool isActive
        ) = getWhitelist(_group);

        // This function is not meant to mint for breeding and recruiting and forging
        require(
            itemType != Item.WyndBreeding,
            "Cannot used to mint non genesis"
        );
        require(
            itemType != Item.RiderRecruiting,
            "Cannot used to mint non genesis"
        );
        require(itemType != Item.Forging, "Cannot used to mint non genesis");

        // Check if whitelist status is active or not
        require(isActive, string(abi.encodePacked(_group, " stage is closed")));

        // Check if whitelist is public or not
        // Public status indicates that member checks is not required and it's used by Airdrop/Free Mint program
        if (isPublic == false) {
            (bool _success, string memory _msgText) = _canConsume(
                _group,
                msg.sender,
                _amount
            );
            require(_success, _msgText);
        }

        // Check if there's enough available nft in this whitelist group
        require(
            uint256(consumedQty + _amount) <= uint256(itemQty),
            "ALL ITEM MINTED"
        );

        require(_amount <= maxQty, "Exceeds max amount per mint");
        require((itemPrice * _amount) <= msg.value, "Insufficent Funds");

        // SEND TO COLLECTOR
        (bool success, ) = feeCollector.call{value: msg.value}("");
        require(success, "Could not send");

        // If all passes, conduct minting
        uint256 id;

        for (uint256 i; i < _amount; i++) {
            tokenIdCounter.increment();
            id = tokenIdCounter.current();
            _mint(msg.sender, id);
            _setTokenURI(
                id,
                string(abi.encodePacked(_tokenURI, id.toString()))
            );
            string memory newTokenURI = tokenURI(id);
            emit MintedID(itemType, itemPrice, msg.sender, id, newTokenURI);
        }

        // If all success, consume allocation for the user on this whitelist group
        consume(_group, msg.sender, _amount);

        // If all success, emit event
        emit MintedAction(_group, itemPrice, msg.sender, _amount, itemType);

        return id;
    }

    /**
     * @notice Mint product from subContract
     * @param _group Group to identify whitelist
     * @param _tokenURI Extended uri to retrieve metadata
     * @param _amount Amount minted
     * @param _to Caller of subContract Address
     */
    function safeMint(
        string memory _group,
        string memory _tokenURI,
        uint256 _amount,
        address _to
    ) external isSubContract returns (uint256) {
        // Get whitelist data first to define all required variables
        // See Whitelist.sol for details
        (
            Item itemType,
            uint256 itemPrice,
            ,
            uint256 maxQty,
            ,
            ,
            bool isPublic,
            bool isActive
        ) = getWhitelist(_group);

        // This function is not meant to mint for Genesis
        require(itemType != Item.WyndGenesis, "Cannot be used to mint genesis");
        require(
            itemType != Item.RiderGenesis,
            "Cannot be used to mint genesis"
        );
        require(itemType != Item.Equipment, "Cannot be used to mint genesis");

        // Check if whitelist status is active or not
        require(isActive, string(abi.encodePacked(_group, " stage is closed")));

        // Check if whitelist is public or not
        // Public status indicates that member checks is not required and it's used by Airdrop/Free Mint program
        if (isPublic == false) {
            (bool _success, string memory _msgText) = _canConsume(
                _group,
                _to,
                _amount
            );
            require(_success, _msgText);
        }

        // Check if exceeding maxQty
        require(_amount <= maxQty, "Exceeds max amount per mint");

        // If all passes, conduct minting
        uint256 id;

        for (uint256 i; i < _amount; i++) {
            tokenIdCounter.increment();
            id = tokenIdCounter.current();
            _mint(_to, id);
            _setTokenURI(
                id,
                string(abi.encodePacked(_tokenURI, id.toString()))
            );
            string memory newTokenURI = tokenURI(id);
            emit MintedID(itemType, itemPrice, _to, id, newTokenURI);
        }

        // If all success, emit event
        emit MintedAction(_group, itemPrice, _to, _amount, itemType);

        return id;
    }

    /**
     * @notice Add member to whitelist from subContract
     * @param _group Whitelist group
     * @param _member Member address
     * @param _multiplier Amount to add into reservedQty
     */
    function safeAddMember(
        string memory _group,
        address _member,
        uint256 _multiplier
    ) external isSubContract {
        _addMember(_group, _member, _multiplier);
    }

    /**
     * @notice Set subContract
     * @param _subContract new subcontract address
     */
    function setSubContract(address _subContract) external onlyOwner {
        subContract = _subContract;
    }

    /**
     * @notice The following functions are overrides required due to the inavailability of conventional _setTokenURI
     * see https://forum.openzeppelin.com/t/declarationerror-undeclared-identifier-error-when-using-setbaseuri/6947/4
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), "Nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        string memory _tokenURI = tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
     * @notice The following functions are overrides required by Solidity.
     * Hook that is called before any token transfer. This includes minting
     * and burning.
     * @param from Address from
     * @param to address to
     * @param tokenId Token Id
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    ///--------------------------------- ROYALTIES SUPPORT ---------------------------------

    /**
     * @notice Getter function for _royaltiesReceiver
     * @return the address of the royalties recipient
     */
    function royaltiesReceiver() external view returns (address) {
        return _royaltiesReceiver;
    }

    /**
     * @notice Changes the royalties' recipient address (in case rights are transferred for instance)
     * @param newRoyaltiesReceiver - address of the new royalties recipient
     */
    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
        external
        onlyOwner
    {
        require(
            newRoyaltiesReceiver != _royaltiesReceiver,
            "Same royalties receiver"
        );
        _royaltiesReceiver = payable(newRoyaltiesReceiver);
    }

    /**
     * @notice Called with the sale price to determine how much royalty is owed and to whom
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _value sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Nonexistent token");
        uint256 _royalties = (_salePrice * ROYALTIES_PERCENTAGE) / 1000;
        return (_royaltiesReceiver, _royalties);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title This contract helps to manage whitelist as well
 * @author WyndBlast Developer Team
 */
contract Whitelist is Ownable {
    uint256 public constant WYND_GENESIS_SUPPLY = 4500;
    uint256 public constant RIDER_GENESIS_SUPPLY = 4500;

    /**
     * @notice Type of items
     */
    enum Item {
        WyndGenesis,
        RiderGenesis,
        Equipment,
        WyndBreeding,
        RiderRecruiting,
        Forging
    }

    /**
     * @notice Structure of member data with following states:
     * - members: Member data containing information on the MemberData struct
     * - itemType: Item type
     */
    struct MemberData {
        uint256 reservedQty;
        uint256 consumedQty;
    }

    /**
     * @notice Structure of whitelist data with following states:
     * - members: Member data containing information on the MemberData struct
     * - memberCount: Members total
     * - itemType: Item type
     * - itemPrice: Item price
     * - itemQty: Item quantity allocated for this whitelist
     * - maxQty: Maximum quantity on each requesting(summon) process
     * - consumedQty: Total of quantity that consumed by all members in this whitelist
     * - isPublic: Allow whitelist without any members in it
     * - isActive: Active status
     */
    struct WhitelistData {
        mapping(address => MemberData) members;
        Item itemType;
        uint256 memberCount;
        uint256 itemPrice;
        uint256 itemQty;
        uint256 maxQty;
        uint256 consumedQty;
        bool isPublic;
        bool isActive;
    }

    string[] private _whitelistArray;
    mapping(string => WhitelistData) private _whitelists;

    event WhitelistMemberAdded(
        string group,
        address member,
        address sender,
        uint256 qty
    );
    event WhitelistMemberRemoved(string group, address member, address sender);
    event WhitelistPriceUpdated(string group, uint256 price, address sender);
    event WhitelistQuantityUpdated(string group, uint256 qty, address sender);

    modifier isAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    modifier nonZero(uint256 _number) {
        require(_number > 0, "Require non zero number");
        _;
    }

    /**
     * @notice Get whitelist count
     * @return itemType
     * @return itemPrice
     * @return itemQty
     * @return maxQty
     * @return consumedQty
     * @return memberCount
     * @return isPublic
     * @return isActive
     */
    function getWhitelist(string memory _group)
        public
        view
        returns (
            Item itemType,
            uint256 itemPrice,
            uint256 itemQty,
            uint256 maxQty,
            uint256 consumedQty,
            uint256 memberCount,
            bool isPublic,
            bool isActive
        )
    {
        WhitelistData storage whitelist = _whitelists[_group];

        return (
            whitelist.itemType,
            whitelist.itemPrice,
            whitelist.itemQty,
            whitelist.maxQty,
            whitelist.consumedQty,
            whitelist.memberCount,
            whitelist.isPublic,
            whitelist.isActive
        );
    }

    /**
     * @notice Get member data
     * @return reservedQty
     * @return consumedQty
     */
    function getWhitelistMemberData(string memory _group, address _account)
        public
        view
        returns (uint256 reservedQty, uint256 consumedQty)
    {
        uint256 reservedQty_ = _whitelists[_group]
            .members[_account]
            .reservedQty;
        uint256 consumedQty_ = _whitelists[_group]
            .members[_account]
            .consumedQty;

        return (reservedQty_, consumedQty_);
    }

    /**
     * @notice Add whitelist
     * @param _group Whitelist group
     * @param _itemType Whitelist item type
     * @param _itemPrice Whitelist item price
     * @param _itemQty Whitelist allocation quantity
     * @param _maxQty Whitelist max quantity per mint request
     * @param _isPublic Is public
     * @param _isActive Is active
     */
    function addWhitelist(
        string memory _group,
        Item _itemType,
        uint256 _itemPrice,
        uint256 _itemQty,
        uint256 _maxQty,
        bool _isPublic,
        bool _isActive
    ) public onlyOwner nonZero(_itemQty) nonZero(_maxQty) {
        require(!_isWhitelistExists(_group), "Whitelist is exists");

        // Check quantity for Genesis Minting
        uint256 totalQty = totalOfItem(_itemType);

        if (_itemType == Item.WyndGenesis) {
            require(
                totalQty + _itemQty <= WYND_GENESIS_SUPPLY,
                "New total must not exceed 4500"
            );
        } else if (_itemType == Item.RiderGenesis) {
            require(
                totalQty + _itemQty <= RIDER_GENESIS_SUPPLY,
                "New total must not exceed 4500"
            );
        }

        WhitelistData storage _whitelist = _whitelists[_group];

        _whitelist.memberCount = 0;
        _whitelist.itemType = _itemType;
        _whitelist.itemPrice = _itemPrice;
        _whitelist.itemQty = _itemQty;
        _whitelist.maxQty = _maxQty;
        _whitelist.consumedQty = 0;
        _whitelist.isPublic = _isPublic;
        _whitelist.isActive = _isActive;

        _whitelistArray.push(_group);
    }

    /**
     * @notice Remove whitelist group
     * @dev This action will destroys all data with this group
     * @param _group Whitelist group
     */
    function removeWhitelist(string memory _group) external onlyOwner {
        delete _whitelists[_group];
        uint256 _index = _indexOfWhitelist(_group);
        if (_index < _whitelistArray.length) {
            _whitelistArray[_index] = _whitelistArray[
                _whitelistArray.length - 1
            ];
            _whitelistArray.pop();
        }
    }

    /**
     * @dev Find index number of given group
     * @param _group Whitelist group
     * @return Index number
     */
    function _indexOfWhitelist(string memory _group)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < _whitelistArray.length; i++) {
            if (
                keccak256(abi.encodePacked(_whitelistArray[i])) ==
                keccak256(abi.encodePacked(_group))
            ) {
                return i;
            }
        }

        // return index number outside from _whitelistArray
        return _whitelistArray.length;
    }

    /**
     * @notice Set whitelist status
     * @param _group Whitelist group
     * @param _status Whitelist status
     */
    function setStatus(string memory _group, bool _status) external onlyOwner {
        _whitelists[_group].isActive = _status;
    }

    /**
     * @dev Get whitelist status
     * @param _group Whitelist group
     * @return Boolean
     */
    function getStatus(string memory _group) public view returns (bool) {
        return _whitelists[_group].isActive;
    }

    /**
     * @dev Set item price based on whitelist
     * @param _group Whitelist group
     * @param _price Item price
     */
    function setPrice(string memory _group, uint256 _price) external onlyOwner {
        _whitelists[_group].itemPrice = _price;

        emit WhitelistPriceUpdated(_group, _price, msg.sender);
    }

    /**
     * @dev Set item qty based on whitelist
     * @param _group Whitelist group
     * @param _qty Item quantity
     */
    function setQuantity(string memory _group, uint256 _qty)
        external
        onlyOwner
    {
        (Item _itemType, , uint256 itemQty, , , , , ) = getWhitelist(_group);

        // Check quantity for Genesis Minting
        uint256 totalQty = totalOfItem(_itemType);

        if (_itemType == Item.WyndGenesis) {
            require(
                (totalQty - itemQty) + _qty <= WYND_GENESIS_SUPPLY,
                "New total must not exceed 4500"
            );
        } else if (_itemType == Item.RiderGenesis) {
            require(
                (totalQty - itemQty) + _qty <= RIDER_GENESIS_SUPPLY,
                "New total must not exceed 4500"
            );
        }

        WhitelistData storage _whitelist = _whitelists[_group];
        require(_qty > _whitelist.consumedQty, "Cannot be less than consumed");
        _whitelist.itemQty = _qty;

        emit WhitelistQuantityUpdated(_group, _qty, msg.sender);
    }

    /**
     * @notice Add member to whitelist
     * @param _group Whitelist group
     * @param _member Member address
     * @param _multiplier Amount to add into reservedQty
     */
    function addMember(
        string memory _group,
        address _member,
        uint256 _multiplier
    ) external isAddress(_member) {
        WhitelistData storage _whitelist = _whitelists[_group];

        if (_whitelist.members[_member].reservedQty > 0) {
            _whitelist.members[_member].reservedQty += _multiplier;
        } else {
            _whitelist.members[_member].reservedQty = _multiplier;
            _whitelist.members[_member].consumedQty = 0;
            _whitelist.memberCount += 1;
        }

        emit WhitelistMemberAdded(_group, _member, msg.sender, _multiplier);
    }

    /**
     * @notice Add member to whitelist
     * @param _group Whitelist group
     * @param _member Member address
     * @param _multiplier Amount to add into reservedQty
     */
    function _addMember(
        string memory _group,
        address _member,
        uint256 _multiplier
    ) internal isAddress(_member) {
        WhitelistData storage _whitelist = _whitelists[_group];

        if (_whitelist.members[_member].reservedQty > 0) {
            _whitelist.members[_member].reservedQty += _multiplier;
        } else {
            _whitelist.members[_member].reservedQty = _multiplier;
            _whitelist.members[_member].consumedQty = 0;
            _whitelist.memberCount += 1;
        }

        emit WhitelistMemberAdded(_group, _member, msg.sender, _multiplier);
    }

    /**
     * @notice Add batch member
     * @param _group Whitelist group
     * @param _members Array of member addresses
     * @param _multiplier Amount to add into reservedQty
     */
    function addBatchMember(
        string memory _group,
        address[] memory _members,
        uint256 _multiplier
    ) external onlyOwner {
        require(_members.length > 0, "Invalid address");

        for (uint256 i; i < _members.length; i++) {
            address _member = _members[i];

            WhitelistData storage _whitelist = _whitelists[_group];

            if (_whitelist.members[_member].reservedQty > 0) {
                _whitelist.members[_member].reservedQty += _multiplier;
            } else {
                // // new member only
                _whitelist.members[_member].reservedQty = _multiplier;
                _whitelist.members[_member].consumedQty = 0;
                _whitelist.memberCount += 1;
            }

            emit WhitelistMemberAdded(_group, _member, msg.sender, _multiplier);
        }
    }

    /**
     * @notice Remove member from whitelist
     * @param _group Whitelist group
     * @param _member Member address
     */
    function removeMember(string memory _group, address _member)
        external
        isAddress(_member)
    {
        WhitelistData storage _whitelist = _whitelists[_group];
        delete _whitelist.members[_member];
        _whitelist.memberCount -= 1;

        emit WhitelistMemberRemoved(_group, _member, msg.sender);
    }

    /**
     * @notice Check if member is whitelisted
     * @param _group Whitelist group
     * @param _member Member address
     * @return Boolean
     */
    function isWhitelisted(string memory _group, address _member)
        public
        view
        isAddress(_member)
        returns (bool)
    {
        WhitelistData storage _whitelist = _whitelists[_group];

        if (!_whitelist.isPublic && _whitelist.isActive) {
            return _whitelist.members[_member].reservedQty > 0;
        }

        return _whitelist.isActive;
    }

    /**
     * @notice Consume quantity by increasing consumed quantity
     * @dev Call this function from inside of _mint() function
     * @param _group Whitelist group
     * @param _member Member address
     * @param _qty Consumed quantity
     */
    function consume(
        string memory _group,
        address _member,
        uint256 _qty
    ) public {
        require(msg.sender == _member, "Can't consume another member");

        (Item _itemType, , , , , , , ) = getWhitelist(_group);

        (bool success, string memory _message) = _canConsume(
            _group,
            _member,
            _qty
        );
        require(success, _message);

        WhitelistData storage _whitelist = _whitelists[_group];

        // Dont need to consume if _itemType > 2
        if (_itemType == Item.WyndGenesis || _itemType == Item.RiderGenesis) {
            _whitelist.consumedQty += _qty;
            _whitelist.members[_member].consumedQty += _qty;
        }
    }

    /**
     * @notice Can consume check for local purpose
     * @param _group Whitelist group
     * @param _member Member address
     * @param _qty Quantity
     * @return Boolean
     * @return _msgText Description about return
     */
    function canConsume(
        string memory _group,
        address _member,
        uint256 _qty
    ) external view returns (bool, string memory _msgText) {
        (bool success, string memory _message) = _canConsume(
            _group,
            _member,
            _qty
        );
        return (success, _message);
    }

    /**
     * @notice Get consumed quantity of member
     * @param _group Whitelist group
     * @param _member Member address
     * @return Consumed quantity
     */
    function getConsumed(string memory _group, address _member)
        external
        view
        returns (uint256)
    {
        WhitelistData storage _whitelist = _whitelists[_group];
        return _whitelist.members[_member].consumedQty;
    }

    /**
     * @dev Can consume check for local purpose
     * @param _group Whitelist group
     * @param _account Member address
     * @param _qty Quantity
     * @return Boolean
     */
    function _canConsume(
        string memory _group,
        address _account,
        uint256 _qty
    ) internal view nonZero(_qty) returns (bool, string memory _message) {
        WhitelistData storage _whitelist = _whitelists[_group];

        // Whitelist is not active
        if (_whitelist.isActive == false) {
            return (
                false,
                string(abi.encodePacked(_group, " stage is closed"))
            );
        }

        // All allocation quantity in the whitelist are sold out
        if (_whitelist.itemQty == _whitelist.consumedQty) {
            return (false, "Item sold out");
        }

        if (_whitelist.isPublic == false) {
            MemberData storage _member = _whitelist.members[_account];

            // Member doesn't have allocated quantity
            // Or they are not whitelisted

            if (_member.reservedQty == 0) {
                return (false, "You are not whitelisted");
            }

            if (_member.reservedQty < _qty) {
                return (false, "Quantity exceeds Max Allowance");
            }

            // There is still remaining quantity
            if (
                SafeMath.sub(_member.reservedQty, _member.consumedQty) >= _qty
            ) {
                return (true, "Good Luck");
            } else {
                return (false, "Qty exceeds Max Allowance");
            }
        } else {
            return (true, "Good Luck");
        }
    }

    /**
     * @notice Private function to check whitelist existence
     * @param _group Whitelist group
     * @return Boolean
     */
    function _isWhitelistExists(string memory _group)
        internal
        view
        returns (bool)
    {
        bool _result = false;

        for (uint256 i = 0; i < _whitelistArray.length; i++) {
            if (
                keccak256(abi.encodePacked(_whitelistArray[i])) ==
                keccak256(abi.encodePacked(_group))
            ) {
                _result = true;
                break;
            }
        }

        return _result;
    }

    /**
     * @notice Get total of item for the given item type
     * @param _itemType Number of item type
     * @return Total allocated quantity
     */
    function totalOfItem(Item _itemType) public view returns (uint256) {
        uint256 _totalQty = 0;

        for (uint256 i = 0; i < _whitelistArray.length; i++) {
            WhitelistData storage _whitelist = _whitelists[_whitelistArray[i]];

            if (_whitelist.itemType == _itemType) {
                _totalQty += _whitelist.itemQty;
            }
        }

        return _totalQty;
    }

    /**
     * @notice Get total of consumed item for the given item type
     * @param _itemType Number of item type
     * @return Total allocated quantity
     */
    function totalOfConsumedQty(Item _itemType) public view returns (uint256) {
        uint256 _totalConsumedQty = 0;

        for (uint256 i = 0; i < _whitelistArray.length; i++) {
            WhitelistData storage _whitelist = _whitelists[_whitelistArray[i]];

            if (_whitelist.itemType == _itemType) {
                _totalConsumedQty += _whitelist.consumedQty;
            }
        }

        return _totalConsumedQty;
    }

    /**
     * @notice Get whitelist count
     * @return Whitelist total
     */
    function getWhitelistCount() public view returns (uint256) {
        return _whitelistArray.length;
    }

    /**
     * @notice Get whitelist array
     * @return Array of whitelist group
     */
    function getWhitelistArray() public view returns (string[] memory) {
        return _whitelistArray;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";