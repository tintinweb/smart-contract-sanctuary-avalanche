/**
 *Submitted for verification at snowtrace.io on 2022-05-01
*/

// File: contracts/PropertyTypeLib.sol


pragma solidity ^0.8.0;

library PropertyTypeLib {
    using PropertyTypeLib for propertyTypes;

    struct precesionValues {
        uint256[] values;
        uint256[] timestamps;
    }

    struct propertyType {
        string name; // name of property type
        uint256 price; // Price of the proerty in NEIBR
        precesionValues dailyRewards; // Daily rewards updated over time.
        uint256 maxDailyReward; // Max daily reward that an property can reach
        uint256 monthlyTax; // Monthly tax that user have to pay(proerty tax)
    }

    struct propertyTypes {
        propertyType[] array;
    }

    event PropertyTypeUpdated(
        uint256 indexed propertyTypeIndex,
        address indexed creator
    );

    // Method to check if property type exists
    /**
     * @dev Method to check if property type exists.
     * @notice This method let's you check if property tyep exists.
     * @param _propertyTypeIndex Index of Property type to check existance.
     * @return Bool, True if property type exists else false.
     */
    function exists(propertyTypes storage self, uint256 _propertyTypeIndex)
        internal
        view
        returns (bool)
    {
        return _propertyTypeIndex < self.array.length;
    }

    /**
     * @dev Method to check if property type exists.
     * @notice This method let's you check if property tyep exists.
     * @param _propertyTypeIndex Index of Property type to check existance.
     * @return Bool, True if property type exists else false.
     */
    function get(propertyTypes storage self, uint256 _propertyTypeIndex)
        internal
        view
        propertyTypeExists(self, _propertyTypeIndex)
        returns (propertyType storage)
    {
        return self.array[_propertyTypeIndex];
    }

    // Modfier to check if property exists or not
    modifier propertyTypeExists(
        propertyTypes storage self,
        uint256 _propertyTypeIndex
    ) {
        require(
            self.exists(_propertyTypeIndex),
            "The Property: The Property type doesn't exists."
        );
        _;
    }

    /**
     * @dev This function will return length of property to loop and get all property types.
     * @notice This method returns you number of property types.
     * @return length of proerty types.
     */
    function length(propertyTypes storage self)
        internal
        view
        returns (uint256)
    {
        return self.array.length;
    }

    /**
     * @dev Method will return if name already present.
     * @notice This method let's you check if it's already in property type.
     * @param _name Name of Property type to check existance.
     * @return Bool, True if name exists else false.
     */
    function nameExists(propertyTypes storage self, string memory _name)
        internal
        view
        returns (bool)
    {
        for (uint256 index = 0; index < self.array.length; index++) {
            if (
                keccak256(abi.encodePacked(self.array[index].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Public method to create new propery type, allowed only to contract Owner.
     * @notice Let's you create new property type if you're contract Admin.
     * @param _name Name of new category.
     * @param _dailyReward Daily reward in NEIBR.
     * @param _maxDailyReward Maximum daily reward in NEIBR that a propery can have.
     * @param _monthlyTax Property tax user have to pay per month in dollers(wei).
     */
    function create(
        propertyTypes storage self,
        string memory _name,
        uint256 _price,
        uint256 _dailyReward,
        uint256 _maxDailyReward,
        uint256 _monthlyTax
    ) public {
        // Check if name is avaialable.
        require(
            !self.nameExists(_name),
            "The Furnitures: Name already in use."
        );

        // Create furnitureCategory memory struct.
        propertyType memory _propertyType;
        _propertyType.name = _name;
        _propertyType.price = _price;
        _propertyType.maxDailyReward = _maxDailyReward;
        _propertyType.monthlyTax = _monthlyTax;

        // Create new furniture category.
        self.array.push(_propertyType);

        // Update daily reward
        self.array[self.array.length - 1].dailyRewards.values.push(
            _dailyReward
        );
        self.array[self.array.length - 1].dailyRewards.timestamps.push(
            block.timestamp
        );

        emit PropertyTypeUpdated(self.array.length - 1, msg.sender);
    }

    /**
     * @dev Method to udate price of Property, Allowed or owner only.
     * @notice This method let's you change the price of property if you're owner of contract.
     * @param _price New Price of the Proerty type in wei
     * @param _propertyTypeIndex Index of property type
     */
    function setPrice(
        propertyTypes storage self,
        uint256 _price,
        uint256 _propertyTypeIndex
    ) internal propertyTypeExists(self, _propertyTypeIndex) {
        self.array[_propertyTypeIndex].price = _price;
        emit PropertyTypeUpdated(self.array.length - 1, msg.sender);
    }

    /**
     * @dev Method to udate daily reward of Property, Allowed or owner only.
     * @notice This method let's you change the daily reward of property if you're owner of contract.
     * @param _dailyReward Daily reward in NEIBR.
     * @param _propertyTypeIndex Index of property type
     */
    function setDailyReward(
        propertyTypes storage self,
        uint256 _dailyReward,
        uint256 _propertyTypeIndex
    ) internal propertyTypeExists(self, _propertyTypeIndex) {
        self.array[_propertyTypeIndex].dailyRewards.values.push(_dailyReward);
        self.array[_propertyTypeIndex].dailyRewards.timestamps.push(
            block.timestamp
        );
        emit PropertyTypeUpdated(self.array.length - 1, msg.sender);
    }

    /**
     * @dev Method to udate maxDailyReward of Property, Allowed or owner only.
     * @notice This method let's you change the maxDailyReward of property if you're owner of contract.
     * @param _maxDailyReward Maximum daily reward in NEIBR that a propery can have.
     * @param _propertyTypeIndex Index of property type
     */
    function setMaxDailyReward(
        propertyTypes storage self,
        uint256 _maxDailyReward,
        uint256 _propertyTypeIndex
    ) internal propertyTypeExists(self, _propertyTypeIndex) {
        self.array[_propertyTypeIndex].maxDailyReward = _maxDailyReward;
        emit PropertyTypeUpdated(self.array.length - 1, msg.sender);
    }

    /**
     * @dev Method to udate monthlyTax of Property, Allowed or owner only.
     * @notice This method let's you change the monthlyTax of property if you're owner of contract.
     * @param _monthlyTax Property tax user have to pay per month in dollers(wei)
     * @param _propertyTypeIndex Index of property type
     */
    function setMothlyTax(
        propertyTypes storage self,
        uint256 _monthlyTax,
        uint256 _propertyTypeIndex
    ) internal propertyTypeExists(self, _propertyTypeIndex) {
        self.array[_propertyTypeIndex].monthlyTax = _monthlyTax;
        emit PropertyTypeUpdated(self.array.length - 1, msg.sender);
    }

    function getDailyRewardFrom(
        propertyTypes storage self,
        uint256 propertyTypeIndex,
        uint256 timestamp
    ) internal view returns (uint256, uint256) {
        propertyType memory _propertyType = self.get(propertyTypeIndex);

        for (uint256 i = 0; i < _propertyType.dailyRewards.values.length; i++) {
            if (i + 1 == _propertyType.dailyRewards.values.length) {
                return (_propertyType.dailyRewards.values[i], block.timestamp);
            } else if (
                _propertyType.dailyRewards.timestamps[i + 1] > timestamp
            ) {
                return (
                    _propertyType.dailyRewards.values[i],
                    _propertyType.dailyRewards.timestamps[i + 1]
                );
            }
        }
        return (0, 0);
    }

}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/interfaces/ITheFurniture.sol


pragma solidity ^0.8.0;



interface ITheFurniture is IERC721Enumerable, IERC721Metadata {
    // Strcture to store Furniture category
    struct furnitureCategory {
        string name; // Name of Furniture category, ie. Bronze, Silver, Gold, Platinum
        uint256[] dailyRewards; // daily rewards in NEIBR of all time.
        uint256[] timestamps; // APY updation timestamps.
    }

    function furnitureCategories(uint256 index)
        external
        view
        returns (furnitureCategory memory);

    // Struct to store furniture details except tokenURI.
    struct furniture {
        uint256 furnitureCategoryIndex; // Index of frunitureCategory.
        string tokenURI; // String to store token metadata
        uint256 propertyId; // tokenId of propery from property contract, 0 means not allocated
    }

    // get furniture details
    function getFurniture(uint256 tokenId)
        external
        view
        returns (furniture memory);

    function getFurnitureCategory(uint256 tokenId)
        external
        view
        returns (furnitureCategory memory);

    // Method to allocate the furniture to property
    function allocateToProperty(
        uint256[] memory tokenIds,
        uint256 _propertyId,
        address propertyOwner
    ) external returns (bool);
    
    // Method to deallocate the furniture from property
    function deallocateFromProperty(uint256[] memory tokenIds)
        external
        returns (bool);


    // Special method to allow property to be transferred from owner to another user.
    function transferFromByProperty(
        address from,
        address to,
        uint256 tokenId
    ) external;
 
    // Special method to allow property to be transferred from owner to another user.
    function transferFromByPropertyBatch(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external returns (bool);

    // Method to get APY and timestamp for furniture.
    function getBoostFrom(uint256 tokenId, uint256 timestamp)
        external
        view
        returns (uint256, uint256);
}

// File: contracts/PropertyLib.sol


pragma solidity ^0.8.0;



library PropertyLib {
    using PropertyLib for properties;

    struct precesionValues {
        uint256[] values;
        uint256[] timestamps;
    }

    struct property {
        string name; //Name of property
        uint256 propertyTypeIndex; // Property type index.
        uint256 createdOn; // Timestamp when Propery was created.
        precesionValues furnitureIndices; // Furniture indices and allocation times.
        uint256 lastTaxDeposited; // Time then the last tax was deposted.
        uint256 lastRewardCalculated; // Timestamp when the reward was calculated.
        uint256 unclaimedDetachedReward; // Unclaimed reward that have no record in contract.
        string tokenURI;
    }

    struct properties {
        property[] array;
        uint256 taxDueAllowed;
        uint256 rewardCalculationTime;
        address furniture;
    }

    uint256 constant monthtime = 30 days;

    function setFurniture(properties storage self, address _newAddress)
        internal
    {
        self.furniture = _newAddress;
    }

    //////////////////////// Core features ////////////////////////////////////

    function length(properties storage self) internal view returns (uint256) {
        return self.array.length;
    }

    function create(
        properties storage self,
        uint256 _propertyTypeIndex,
        string memory _name,
        string memory _tokenURI
    ) public returns (uint256) {
        property memory _property;
        _property.propertyTypeIndex = _propertyTypeIndex;
        _property.name = _name;
        _property.createdOn = block.timestamp;
        _property.lastTaxDeposited = block.timestamp;
        _property.lastRewardCalculated = block.timestamp;
        _property.tokenURI = _tokenURI;

        self.array.push(_property);
        return self.length() - 1;
    }

    function get(properties storage self, uint256 tokenId)
        internal
        view
        propertyExists(self, tokenId)
        returns (property memory)
    {
        return self.array[tokenId];
    }

    function exists(properties storage self, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return self.array[tokenId].createdOn != 0;
    }

    function remove(properties storage self, uint256 tokenId) public {
        if (self.exists(tokenId)) {
            delete self.array[tokenId];
        }
    }

    modifier propertyExists(properties storage self, uint256 tokenId) {
        require(self.exists(tokenId), "TheProperty: Property doesn't exists.");
        _;
    }

    //////////////////////// Tax Features ////////////////////////////////////

    // Method to check if the tax is cleared.
    function isTaxCleared(properties storage self, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        if (self.get(tokenId).lastTaxDeposited + monthtime >= block.timestamp) {
            return true;
        }
        return false;
    }

    // Method to check if proerty is locked due to insufficient tax payment.
    function isPropertyLocked(properties storage self, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        if (
            self.get(tokenId).lastTaxDeposited +
                monthtime +
                self.taxDueAllowed <
            block.timestamp
        ) {
            return true;
        }
        return false;
    }

    // function to get time till tax is cleared.
    function getTaxClearedTime(properties storage self, uint256 tokenId)
        internal
        view
        propertyExists(self, tokenId)
        returns (uint256)
    {
        return self.get(tokenId).lastTaxDeposited + monthtime;
    }

    // Method to accept tax
    function acceptTax(
        properties storage self,
        uint256 tokenId,
        uint256 months
    ) public propertyExists(self, tokenId) {
        // update the tax by months.
        self.array[tokenId].lastTaxDeposited += (monthtime * months);
    }

    // Method to get upcoming due date for tax payment.
    function getUpcomingTaxDue(properties storage self, uint256 tokenId)
        internal
        view
        propertyExists(self, tokenId)
        returns (uint256)
    {
        return self.get(tokenId).lastTaxDeposited + monthtime;
    }

    // Method to get upcoming due date for tax payment.
    function getLastDate(properties storage self, uint256 tokenId)
        internal
        view
        propertyExists(self, tokenId)
        returns (uint256)
    {
        return
            self.get(tokenId).lastTaxDeposited + monthtime + self.taxDueAllowed;
    }

    function setTaxDueAllowed(properties storage self, uint256 _newValue)
        internal
    {
        self.taxDueAllowed = _newValue;
    }

    //////////////////////// Furniture section ////////////////////////////////
    // Method to check if furniture is allocated in property
    function isFurnitureAllocated(
        properties storage self,
        uint256 tokenId,
        uint256 _furnitureId
    ) internal view returns (bool) {
        for (
            uint256 index = 0;
            index < self.get(tokenId).furnitureIndices.values.length;
            index++
        ) {
            if (
                self.get(tokenId).furnitureIndices.values[index] == _furnitureId
            ) {
                return true;
            }
        }
        return false;
    }

    // Method to allocate furniture in property
    function allocateFurniture(
        properties storage self,
        uint256 tokenId,
        uint256 _furnitureId
    ) public propertyExists(self, tokenId) {
        require(
            !self.isFurnitureAllocated(tokenId, _furnitureId),
            "The Property: The Furniture is already allocated"
        );
        self.array[tokenId].furnitureIndices.values.push(_furnitureId);
        self.array[tokenId].furnitureIndices.timestamps.push(block.timestamp);
    }

    // Method to deallocate furniture
    function deallocateFurniture(
        properties storage self,
        uint256 tokenId,
        uint256 _furnitureId
    ) public {
        require(
            self.isFurnitureAllocated(tokenId, _furnitureId),
            "The Property: The Furniture is not allocated to property."
        );
        // Loop through all furnitures.
        for (
            uint256 index = 0;
            index < self.array[tokenId].furnitureIndices.values.length;
            index++
        ) {
            // Chack for furniture allocation.
            if (
                self.array[tokenId].furnitureIndices.values[index] ==
                _furnitureId
            ) {
                // Remove furniture
                self.array[tokenId].furnitureIndices.values[index] = self
                    .array[tokenId]
                    .furnitureIndices
                    .values[
                        self.array[tokenId].furnitureIndices.values.length - 1
                    ];
                self.array[tokenId].furnitureIndices.values.pop();

                // Remove timestamp
                self.array[tokenId].furnitureIndices.timestamps[index] = self
                    .array[tokenId]
                    .furnitureIndices
                    .timestamps[
                        self.array[tokenId].furnitureIndices.timestamps.length -
                            1
                    ];
                self.array[tokenId].furnitureIndices.timestamps.pop();

                // Stop execution.
                break;
            }
        }
    }

    //////////////////////////Reward section //////////////////////////////////

    // Method to start reward calculation time. Will be executed only once.
    function startRewardCalculation(properties storage self) public {
        require(
            self.rewardCalculationTime == 0,
            "The Property: Reward calculation already started"
        );
        self.rewardCalculationTime = block.timestamp;
    }

    function updateReward(
        properties storage self,
        uint256 tokenId,
        uint256 reward,
        uint256 processedTill
    ) internal {
        // update the reward calculation duration.
        self.array[tokenId].unclaimedDetachedReward = reward;
        self.array[tokenId].lastRewardCalculated = processedTill;
    }

    function getDailyRewardFrom(
        PropertyTypeLib.propertyType memory _propertyType,
        uint256 timestamp
    ) internal view returns (uint256, uint256) {
        // propertyType memory _propertyType = self.get(propertyTypeIndex);

        for (uint256 i = 0; i < _propertyType.dailyRewards.values.length; i++) {
            if (i + 1 == _propertyType.dailyRewards.values.length) {
                return (_propertyType.dailyRewards.values[i], block.timestamp);
            } else if (
                _propertyType.dailyRewards.timestamps[i + 1] > timestamp
            ) {
                return (
                    _propertyType.dailyRewards.values[i],
                    _propertyType.dailyRewards.timestamps[i + 1]
                );
            }
        }
        return (0, 0);
    }

    // Private method to calculate reward.
    function calculateReward(
        properties storage self,
        uint256 tokenId,
        PropertyTypeLib.propertyType memory _propertyType
    ) public view propertyExists(self, tokenId) returns (uint256, uint256) {
        // Check if reward calculation is already started yet.
        require(
            block.timestamp >= self.rewardCalculationTime &&
                self.rewardCalculationTime != 0,
            "TheProperty: Reward calculation not started yet."
        );

        property memory _property = self.get(tokenId);

        uint256[] memory rewardBoosts = new uint256[](
            _property.furnitureIndices.values.length
        );
        uint256[] memory rewardBoostTimestamps = new uint256[](
            _property.furnitureIndices.values.length
        );

        // Starting time for last reward calculation.
        uint256 rewardProcessedTill = _property.lastRewardCalculated <=
            self.rewardCalculationTime
            ? self.rewardCalculationTime
            : _property.lastRewardCalculated;

        // Get date for next day.
        rewardProcessedTill = (((rewardProcessedTill + 1 days) / 1 days) *
            1 days);

        // Furniture Interface.
        {
            ITheFurniture _furniture = ITheFurniture(self.furniture);

            // Get All rewardBoosts.
            for (uint256 i = 0; i < rewardBoosts.length; i++) {
                (uint256 _APY, uint256 _nextAPYUpdate) = _furniture
                    .getBoostFrom(
                        _property.furnitureIndices.values[i],
                        rewardProcessedTill
                    );
                rewardBoosts[i] = _APY;
                rewardBoostTimestamps[i] = _nextAPYUpdate;
            }
        }

        // Variables to store reward sum.
        uint256 rewardSum = 0;
        (uint256 _dailyReward, uint256 _nextUpdate) = getDailyRewardFrom(
            _propertyType,
            rewardProcessedTill
        );

        // max reward per day.
        while (
            rewardProcessedTill < block.timestamp &&
            rewardProcessedTill < self.getTaxClearedTime(tokenId)
        ) {

            uint256 todaysReward = _dailyReward;

            // Get today's reward with all the furniture boosts.
            {
                ITheFurniture _furniture = ITheFurniture(self.furniture);
                for (uint256 i = 0; i < rewardBoosts.length; i++) {
                    // Add the boost to daily reward if it was allocated in this property.
                    if (
                        rewardProcessedTill >
                        _property.furnitureIndices.timestamps[i]
                    ) {
                        todaysReward += rewardBoosts[i];
                    }

                    // Update the boost if required.
                    if (rewardProcessedTill > rewardBoostTimestamps[i]) {
                        (uint256 _APY, uint256 _nextAPYUpdate) = _furniture
                            .getBoostFrom(
                                _property.furnitureIndices.values[i],
                                rewardProcessedTill
                            );
                        rewardBoosts[i] = _APY;
                        rewardBoostTimestamps[i] = _nextAPYUpdate;
                    }

                    // Break if reached till total reward.
                    if (todaysReward > _propertyType.maxDailyReward) {
                        todaysReward = _propertyType.maxDailyReward;
                        break;
                    }
                }
            }
            // Update today's reward
            rewardSum += todaysReward;

            // update all variables.
            // Reward processed duration.
            rewardProcessedTill += 1 days;

            // update daily reward.
            if (_nextUpdate < rewardProcessedTill) {
                (_dailyReward, _nextUpdate) = getDailyRewardFrom(
                    _propertyType,
                    rewardProcessedTill
                );
            }
        }

        return (rewardSum, rewardProcessedTill - 1 days);
    }

    // Method to return chargable percentage on claim.
    function getClaimFeePercentrage(
        properties storage self,
        uint256 tokenId,
        uint256 reward,
        uint256 precisionValue,
        uint256 _totalSupply
    ) public view returns (uint256) {
        // Flat 50% if property is locked(tax not paid even in due dates.)
        if (self.isPropertyLocked(tokenId)) {
            return 50 * precisionValue;
        } else {
            // Total supply of neighbour contract.
            // uint256 _totalSupply = ITheNeighbours(neighbour).totalSupply();

            // Calculate reward percentage.
            uint256 rewardPercentage = (reward * 100 * precisionValue) /
                _totalSupply;

            // 10% claim fee for reward below 3% of totalSupply
            if (rewardPercentage < (3 * precisionValue)) {
                return 10 * precisionValue;
            }
            // 50% claim fee for reward above 10% of totalSupply
            else if (rewardPercentage >= (10 * precisionValue)) {
                return 50 * precisionValue;
            }
            // reward 15, 20, 25, 30, 35, 40, 45 for corresponding reward percentage above 3, 4, 5, 6, 7, 8, 9
            else {
                return
                    ((rewardPercentage / precisionValue) * 5) * precisionValue;
            }
        }
    }
}