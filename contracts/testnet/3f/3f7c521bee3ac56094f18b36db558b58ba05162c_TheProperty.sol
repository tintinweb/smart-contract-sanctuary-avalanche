/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-02
*/

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function allocateToProperty(uint256 tokenId, uint256 _propertyId) external;

    // Method to deallocate the furniture from property
    function deallocateFromProperty(uint256 tokenId) external;


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
    ) external;

    // Method to get APY and timestamp for furniture.
    function getAPYFrom(uint256 tokenId, uint256 timestamp)
        external
        view
        returns (uint256, uint256);
}

// File: contracts/interfaces/IJoeRouter01.sol


pragma solidity ^0.8.0;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountAVAX,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


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
        return self.length();
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
            self.get(tokenId).lastTaxDeposited +
            monthtime +
            self.taxDueAllowed;
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
            block.timestamp >= self.rewardCalculationTime,
            "TheProperty: Reward calculation not started yet."
        );

        property memory _property = self.get(tokenId);

        precesionValues memory rewardBoosts;

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
            for (uint256 i = 0; i < rewardBoosts.values.length; i++) {
                (uint256 _APY, uint256 _nextAPYUpdate) = _furniture.getAPYFrom(
                    _property.furnitureIndices.values[i],
                    rewardProcessedTill
                );
                rewardBoosts.values[i] = _APY;
                rewardBoosts.timestamps[i] = _nextAPYUpdate;
            }
        }

        // Variables to store reward sum.
        uint256 rewardSum = 0;
        (uint256 _dailyReward, uint256 _nextUpdate) = getDailyRewardFrom(
            _propertyType,
            rewardProcessedTill
        );

        // max reward per day.

        while (rewardProcessedTill <= block.timestamp) {
            uint256 todaysReward = _dailyReward;

            // Get today's reward with all the furniture boosts.
            {
                ITheFurniture _furniture = ITheFurniture(self.furniture);
                for (uint256 i = 0; i < rewardBoosts.values.length; i++) {
                    // Add the boost to daily reward if it was allocated in this property.
                    if (
                        rewardProcessedTill >
                        _property.furnitureIndices.timestamps[i]
                    ) {
                        todaysReward += rewardBoosts.values[i];
                    }

                    // Update the boost if required.
                    if (rewardProcessedTill > rewardBoosts.timestamps[i]) {
                        (uint256 _APY, uint256 _nextAPYUpdate) = _furniture
                            .getAPYFrom(
                                _property.furnitureIndices.values[i],
                                rewardProcessedTill
                            );
                        rewardBoosts.values[i] = _APY;
                        rewardBoosts.timestamps[i] = _nextAPYUpdate;
                    }

                    // Break if reached till total reward.
                    if (todaysReward > _propertyType.maxDailyReward) {
                        todaysReward = _propertyType.maxDailyReward;
                        break;
                    }
                }
            }
            // Update today's reward
            rewardSum = todaysReward;

            // update all variables.
            // Reward processed duration.
            rewardProcessedTill += 1 days;

            // Stop calculation if reached today's time or tax cleared duration.
            if (
                rewardProcessedTill > block.timestamp ||
                rewardProcessedTill > self.getTaxClearedTime(tokenId)
            ) {
                break;
            }

            // update daily reward.
            if (_nextUpdate < rewardProcessedTill) {
                (_dailyReward, _nextUpdate) = getDailyRewardFrom(
                    _propertyType,
                    rewardProcessedTill
                );
            }
        }

        return (rewardSum, rewardProcessedTill);
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/interfaces/ITheNeighbours.sol


pragma solidity ^0.8.0;


// Interface for neighbour contract.
interface ITheNeighbours is IERC20Metadata {
    function specialTransfer(address from, address to, uint amount) external;
}
// File: contracts/PoolLib.sol


pragma solidity ^0.8.0;



library PoolLib {
    using PoolLib for pool;

    struct pool {
        // Treasury pool
        address treasuryPool;
        uint256 treasuryPoolShare;
        uint256 treasuryTaxPoolShare;
        // NEIBR pool
        address NEIBRPool;
        uint256 NEIBRPoolShare;
        uint256 NEIBRTaxPoolShare;
        // Reward pool
        address rewardPool;
        uint256 rewardPoolShare;
        uint256 rewardTaxPoolShare;
        // Router setup.
        IJoeRouter02 uniswapV2Router;
        uint256 precisionValue;
        address neighbour;
        address usdc;
    }

    // Method to update precisionValue address
    function setPrecisionValue(pool storage self, uint256 _newValue) public {
        self.precisionValue = _newValue;
    }

    // Private method to swap NEIBR to AVAX and update the share
    function swapAndSendAVAX(
        pool storage self,
        uint256 tokenAmount,
        address to
    ) internal {
        address[] memory path = new address[](2);
        path[0] = self.neighbour;
        path[1] = self.uniswapV2Router.WAVAX();

        ITheNeighbours(self.neighbour).approve(
            address(self.uniswapV2Router),
            tokenAmount
        );

        self
            .uniswapV2Router
            .swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                to,
                block.timestamp
            );
    }

    // Private method to distribute rewrds at porperty purchase.
    function distributeInPoolsAtPurchase(pool storage self, uint256 _amount)
        public
    {
        // Calculate treasuy and NEIBR pool shares.
        uint256 _treasury = (_amount * self.treasuryPoolShare) /
            (100 * self.precisionValue);
        uint256 _NEIBR = (_amount * self.NEIBRPoolShare) /
            (100 * self.precisionValue);

        // Send amount in AVAX to treasury pool
        self.swapAndSendAVAX(_treasury, self.treasuryPool);

        ITheNeighbours _neighbour = ITheNeighbours(self.neighbour);
        // Send amount to _NEIBR pool
        _neighbour.transfer(self.NEIBRPool, _NEIBR);

        // Send remaining fund if rewardPool if isn't same.
        if (address(this) != self.rewardPool) {
            _neighbour.transfer(
                self.rewardPool,
                (_amount - _treasury - _NEIBR)
            );
        }
    }

    // Distribute reward while receiving tax
    function distributeInPoolsAtTax(pool storage self) public {
        uint256 _amount = msg.value;
        // Calculate treasuy and NEIBR pool shares.
        uint256 _treasury = (_amount * self.treasuryTaxPoolShare) /
            (100 * self.precisionValue);
        uint256 _NEIBR = (_amount * self.NEIBRTaxPoolShare) /
            (100 * self.precisionValue);

        // Send amount in AVAX to treasury pool
        payable(self.treasuryPool).transfer(_treasury);

        // Send amount to _NEIBR pool
        payable(self.NEIBRPool).transfer(_NEIBR);

        // Send remaining fund if rewardPool if isn't same.
        if (address(this) != self.rewardPool) {
            payable(self.rewardPool).transfer(_amount - _treasury - _NEIBR);
        }
    }

    // Set neighbour pool
    function setNeighbour(pool storage self, address _newAddress) public {
        self.neighbour = _newAddress;
    }

    function getDollerInAvax(pool storage self, uint _amount) view public returns (uint) {
        address[] memory paths = new address[](2);
        paths[0] = self.uniswapV2Router.WAVAX();
        paths[1] = self.usdc;
        uint[] memory amounts = self.uniswapV2Router.getAmountsIn(_amount, paths);
        return amounts[0];
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol


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
library SafeMathUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


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
interface IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;



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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;









/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;




/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721Upgradeable.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;




/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: contracts/TheProperty.sol


pragma solidity ^0.8.0;











contract TheProperty is
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;
    using PropertyTypeLib for PropertyTypeLib.propertyTypes;
    using PoolLib for PoolLib.pool;
    using PropertyLib for PropertyLib.properties;

    ///////////////////////////////////////////////////////////////////////////
    // declare all storage at once to handle storage clashes.
    ///////////////////////////////////////////////////////////////////////////

    //*****************************Main Variable*******************************
    // Public variables to store address of furniture and property contract
    address public neighbour;
    address public furniture;
    uint256 public precisionValue;

    //************************Property Type Variable***************************

    // Array to store all property types
    PropertyTypeLib.propertyTypes propertyTypes;

    //*****************************Pool Variable*******************************
    // Pool address and shares.
    PoolLib.pool pool;

    //************************Property Variable********************************

    uint256 public presaleStart; // Starting timestamp for presale.
    uint256 public presaleEnd; // Ending timestamp for presale.
    address public presaleContract; // Contract address for presale.

    // Array to store properties
    PropertyLib.properties properties;

    ///////////////////////////////////////////////////////////////////////////
    // Storage declaraion End
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Event declraion.
    ///////////////////////////////////////////////////////////////////////////

    event TaxCleared(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 TaxClearedTill,
        uint256 amount
    );

    event FurnitureAttachedTo(
        uint256 indexed tokenId,
        uint256 indexed furnitureId,
        address indexed owner
    );

    event FurnitureDetachedFrom(
        uint256 indexed tokenId,
        uint256 indexed furnitureId,
        address indexed owner
    );

    event RewardClaimed(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 amount,
        uint256 claimFee
    );

    event PaidByReward(
        uint256 indexed tokenId,
        address indexed owner,
        address indexed paidTo,
        uint256 amount
    );

    ///////////////////////////////////////////////////////////////////////////
    // Event declration end.
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Admin updates.
    ///////////////////////////////////////////////////////////////////////////

    //************************Address Variables********************************
    function setNeighbour(address _newAddress) public onlyOwner {
        neighbour = _newAddress;
        pool.setNeighbour(_newAddress);
    }

    // Admin methods
    function setFurniture(address _newAddress) public onlyOwner {
        properties.setFurniture(_newAddress);
    }

    //************************Pool Share Variables*****************************

    function setPool(PoolLib.pool memory _pool) public onlyOwner {
        pool = _pool;
    }

    function getPool() public view returns (PoolLib.pool memory) {
        return pool;
    }

    //************************Property Tax Variables**************************
    // Admin methods
    function setTaxDueAllowed(uint256 _newValue) public onlyOwner {
        properties.setTaxDueAllowed(_newValue);
    }

    //************************Property Reward Variables************************

    // Method to start reward calculation time. Will be executed only once.
    function startRewardCalculation() public onlyOwner {
        properties.startRewardCalculation();
    }

    //************************Property Presale Variables***********************

    // Method to start presale.
    function setPresale(
        uint256 _presaleStart,
        uint256 _presaleEnd,
        address _presaleContract
    ) public onlyOwner {
        require(
            _presaleStart >= block.timestamp,
            "The Property: The presale start time must be future time."
        );
        require(
            _presaleStart < _presaleEnd,
            "The Property: The presale end time must be future time from starting time."
        );
        require(
            _presaleContract != address(0),
            "The Property: The presale contract must be valid address."
        );
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
        presaleContract = _presaleContract;
    }

    // Function to end presale right away.
    function termintatePresale() public onlyOwner {
        presaleStart = 0;
        presaleEnd = 0;
        presaleContract = address(0);
    }

    //************************Property Variables*******************************

    //************************Fund withdraw ***********************************

    // Method to withdraw Native currency in contract.
    function withdraw(uint256 amount) public onlyOwner {
        require(
            address(this).balance >= amount,
            "TheProperty: Insufficient balance in property."
        );
        payable(msg.sender).transfer(amount);
    }

    // Method to withdraw ERC20 tokens.
    function withdrawERC20(address _erc20Token, uint256 amount)
        public
        onlyOwner
    {
        ITheNeighbours erc20Token = ITheNeighbours(_erc20Token);
        require(
            erc20Token.balanceOf(address(this)) >= amount,
            "TheProperty: Insufficient balance in property."
        );
        erc20Token.transfer(msg.sender, amount);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Admin updates End.
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Business Logic
    ///////////////////////////////////////////////////////////////////////////

    // ********************************PropertyType section********************

    // Method to check if property type exists
    /**
     * @dev Method to check if property type exists.
     * @notice This method let's you check if property tyep exists.
     * @param _propertyTypeIndex Index of Property type to check existance.
     * @return Bool, True if property type exists else false.
     */
    function doesPropertyTypeExists(uint256 _propertyTypeIndex)
        public
        view
        returns (bool)
    {
        return propertyTypes.exists(_propertyTypeIndex);
    }

    // Modfier to check if property exists or not
    modifier propertyTypeExists(uint256 _propertyTypeIndex) {
        require(
            propertyTypes.exists(_propertyTypeIndex),
            "The Property: The Property type doesn't exists."
        );
        _;
    }

    /**
     * @dev This function will return length of property to loop and get all property types.
     * @notice This method returns you number of property types.
     * @return length of proerty types.
     */
    function getPropertyTypesLength() public view returns (uint256) {
        return propertyTypes.length();
    }

    /**
     * @dev Method will return if name already present.
     * @notice This method let's you check if it's already in property type.
     * @param _name Name of Property type to check existance.
     * @return Bool, True if name exists else false.
     */
    function doesPropertyTypeNameExists(string memory _name)
        public
        view
        returns (bool)
    {
        return propertyTypes.nameExists(_name);
    }

    function getPropertyType(uint256 _propertyTypeIndex)
        public
        view
        returns (PropertyTypeLib.propertyType memory)
    {
        return propertyTypes.get(_propertyTypeIndex);
    }

    /**
     * @dev Public method to create new propery type, allowed only to contract Owner.
     * @notice Let's you create new property type if you're contract Admin.
     * @param _name Name of new category.
     * @param _dailyReward Daily reward in NEIBR.
     * @param _maxDailyReward Maximum daily reward in NEIBR that a propery can have.
     * @param _monthlyTax Property tax user have to pay per month in dollers(wei).
     */
    function createPropertyType(
        string memory _name,
        uint256 _price,
        uint256 _dailyReward,
        uint256 _maxDailyReward,
        uint256 _monthlyTax
    ) external onlyOwner {
        propertyTypes.create(
            _name,
            _price,
            _dailyReward,
            _maxDailyReward,
            _monthlyTax
        );
    }

    /**
     * @dev Method to udate price of Property, Allowed or owner only.
     * @notice This method let's you change the price of property if you're owner of contract.
     * @param _price New Price of the Proerty type in wei
     * @param _propertyTypeIndex Index of property type
     */
    function updatePropertyTypePrice(uint256 _price, uint256 _propertyTypeIndex)
        public
        onlyOwner
        propertyTypeExists(_propertyTypeIndex)
    {
        propertyTypes.setPrice(_price, _propertyTypeIndex);
    }

    /**
     * @dev Method to udate daily reward of Property, Allowed or owner only.
     * @notice This method let's you change the daily reward of property if you're owner of contract.
     * @param _dailyReward Daily reward in NEIBR.
     * @param _propertyTypeIndex Index of property type
     */
    function updatePropertyTypeDailyReward(
        uint256 _dailyReward,
        uint256 _propertyTypeIndex
    ) public onlyOwner propertyTypeExists(_propertyTypeIndex) {
        propertyTypes.setDailyReward(_dailyReward, _propertyTypeIndex);
    }

    /**
     * @dev Method to udate maxDailyReward of Property, Allowed or owner only.
     * @notice This method let's you change the maxDailyReward of property if you're owner of contract.
     * @param _maxDailyReward Maximum daily reward in NEIBR that a propery can have.
     * @param _propertyTypeIndex Index of property type
     */
    function updatePropertyTypeMaxDailyReward(
        uint256 _maxDailyReward,
        uint256 _propertyTypeIndex
    ) public onlyOwner propertyTypeExists(_propertyTypeIndex) {
        propertyTypes.setDailyReward(_maxDailyReward, _propertyTypeIndex);
    }

    /**
     * @dev Method to udate monthlyTax of Property, Allowed or owner only.
     * @notice This method let's you change the monthlyTax of property if you're owner of contract.
     * @param _monthlyTax Property tax user have to pay per month in dollers(wei)
     * @param _propertyTypeIndex Index of property type
     */
    function updatePropertyTypeMothlyTax(
        uint256 _monthlyTax,
        uint256 _propertyTypeIndex
    ) public onlyOwner propertyTypeExists(_propertyTypeIndex) {
        propertyTypes.setDailyReward(_monthlyTax, _propertyTypeIndex);
    }

    // ********************************PropertyType section end****************

    // ********************************Property section************************

    // Function to check if contract is in presale state.
    function validPresale() private view returns (bool) {
        return (block.timestamp >= presaleStart &&
            block.timestamp <= presaleEnd &&
            msg.sender == presaleContract);
    }

    // Modifier to check if property exists
    modifier propertyExists(uint256 tokenId) {
        require(
            _exists(tokenId),
            "The Property: operator query for nonexistent token"
        );
        _;
    }

    // Method to create new property:
    function _mintProperty(
        uint256 _propertyTypeIndex,
        string memory _name,
        string memory _tokenURI,
        address tokenOwner
    ) internal propertyTypeExists(_propertyTypeIndex) {
        // create property
        uint256 tokenId = properties.create(
            _propertyTypeIndex,
            _name,
            _tokenURI
        );
        // Mint property
        _mint(tokenOwner, tokenId);
    }

    /**
     * @dev Public method to mint the property.
     * @notice This method allows you to create new property by paying the presale price
     * @param _propertyTypeIndex Property type index
     * @param _name Name of the property
     */
    function presaleMint(
        uint256 _propertyTypeIndex,
        string memory _name,
        string memory _tokenURI,
        address tokenOwner
    ) external {
        require(validPresale(), "The Property: Presale only!!");
        _mintProperty(_propertyTypeIndex, _name, _tokenURI, tokenOwner);
    }

    // Method to create new property:
    function mint(
        uint256 _propertyTypeIndex,
        string memory _name,
        string memory _tokenURI,
        bool payByReward_,
        uint256 tokenId
    ) public {
        require(
            presaleStart >= block.timestamp,
            "The Property: Can't mint before presale."
        );
        require(
            presaleEnd <= block.timestamp,
            "The Property: Can't mint in presale."
        );
        require(
            presaleContract == msg.sender,
            "The Property: Can't be minted by presale."
        );
        // Pay by reward of neighbour
        if (payByReward_) {
            _payByReward(tokenId, propertyTypes.get(_propertyTypeIndex).price);
            emit PaidByReward(
                tokenId,
                ownerOf(tokenId),
                address(this),
                propertyTypes.get(_propertyTypeIndex).price
            );
        } else {
            ITheNeighbours _neighbour = ITheNeighbours(neighbour);
            require(
                _neighbour.balanceOf(msg.sender) >=
                    propertyTypes.get(_propertyTypeIndex).price,
                "The  Property: You don't have sufficient balance to buy property."
            );
            _neighbour.specialTransfer(
                msg.sender,
                address(this),
                propertyTypes.get(_propertyTypeIndex).price
            );
        }
        // Distribute fund in pools
        pool.distributeInPoolsAtPurchase(
            propertyTypes.get(_propertyTypeIndex).price
        );

        // Create Property
        _mintProperty(_propertyTypeIndex, _name, _tokenURI, msg.sender);
    }

    // Method to get property
    function getProperty(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (PropertyLib.property memory)
    {
        return properties.get(tokenId);
    }

    function burn(uint256 tokenId) public override {
        super.burn(tokenId);
        properties.remove(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return properties.get(tokenId).tokenURI;
    }

    // ********************************Property section end *******************

    // ********************************Property tax section ******************

    modifier proertyOwnerOnly(uint256 tokenId) {
        require(
            msg.sender == ownerOf(tokenId),
            "The Property: Property owner only."
        );
        _;
    }

    // Method to get tax in Avax.
    function getTaxInAVAX(uint256 _propertyTypeIndex)
        public
        view
        propertyTypeExists(_propertyTypeIndex)
        returns (uint256)
    {
        return
            pool.getDollerInAvax(
                propertyTypes.get(_propertyTypeIndex).monthlyTax
            );
    }

    // Method to check if the tax is cleared.
    function isTaxCleared(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (bool)
    {
        return properties.isTaxCleared(tokenId);
    }

    // Method to check if proerty is locked due to insufficient tax payment.
    function isPropertyLocked(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (bool)
    {
        return properties.isPropertyLocked(tokenId);
    }

    // function to get time till tax is cleared.
    function getTaxClearedTime(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (uint256)
    {
        return properties.getTaxClearedTime(tokenId);
    }

    // Method to accept tax
    function acceptTax(uint256 tokenId, uint256 months)
        public
        payable
        proertyOwnerOnly(tokenId)
        propertyExists(tokenId)
    {
        require(
            msg.value >= (getTaxInAVAX(tokenId) * months),
            "The Property: Insufficient tax supplied. "
        );

        // update the tax by months.
        properties.acceptTax(tokenId, months);

        // Share Tax among pools.
        pool.distributeInPoolsAtTax();

        emit TaxCleared(
            tokenId,
            ownerOf(tokenId),
            properties.get(tokenId).lastTaxDeposited,
            msg.value
        );
    }

    // Method to get upcoming due date for tax payment.
    function getUpcomingTaxDue(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (uint256)
    {
        return properties.getUpcomingTaxDue(tokenId);
    }

    // Method to get upcoming due date for tax payment.
    function getLastDate(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (uint256)
    {
        return properties.getLastDate(tokenId);
    }

    // ********************************Property tax section end **************

    // ********************************Property Furniture section start *******

    // Method to check if furniture is allocated in property
    function isFurnitureAllocated(uint256 tokenId, uint256 _furnitureId)
        public
        view
        returns (bool)
    {
        return properties.isFurnitureAllocated(tokenId, _furnitureId);
    }

    // Method to allocate furniture in property
    function allocateFurniture(uint256 tokenId, uint256 _furnitureId)
        public
        proertyOwnerOnly(tokenId)
        propertyExists(tokenId)
    {
        ITheFurniture _furniture = ITheFurniture(furniture);
        _furniture.allocateToProperty(_furnitureId, tokenId);
        properties.allocateFurniture(tokenId, _furnitureId);

        emit FurnitureAttachedTo(tokenId, _furnitureId, ownerOf(tokenId));
    }

    // Method to deallocate the property
    function deallocateFurniture(uint256 tokenId, uint256 _furnitureId)
        public
        proertyOwnerOnly(tokenId)
        propertyExists(tokenId)
    {
        // Delloacte the property from furniture contract
        ITheFurniture _furniture = ITheFurniture(furniture);
        _furniture.deallocateFromProperty(_furnitureId);

        // Calculate and update the unclaimed reward.
        (uint256 reward, uint256 processedTill) = calculateReward(tokenId);
        properties.updateReward(tokenId, reward, processedTill);

        // Deallocate the furniture from property
        properties.deallocateFurniture(tokenId, _furnitureId);

        emit FurnitureDetachedFrom(tokenId, _furnitureId, ownerOf(tokenId));
    }

    // ********************************Property furniture section end *********

    // ********************************Property reward section end ************

    //  Private method to calculate reward.
    function _calculateReward(uint256 tokenId)
        private
        view
        propertyExists(tokenId)
        returns (uint256, uint256)
    {
        PropertyTypeLib.propertyType memory _propertyType = propertyTypes.get(
            properties.get(tokenId).propertyTypeIndex
        );
        return properties.calculateReward(tokenId, _propertyType);
    }

    // Public method to calculated reward.
    function calculateReward(uint256 tokenId)
        public
        view
        propertyExists(tokenId)
        returns (uint256, uint256)
    {
        (uint256 uncalculatedReward, uint256 calculatedTill) = _calculateReward(
            tokenId
        );
        return (
            properties.get(tokenId).unclaimedDetachedReward +
                uncalculatedReward,
            calculatedTill
        );
    }

    // Method to return chargable percentage on claim.
    function getClaimFeePercentrage(uint256 tokenId, uint256 reward)
        public
        view
        returns (uint256)
    {
        uint256 _totalSupply = ITheNeighbours(neighbour).totalSupply();
        return
            properties.getClaimFeePercentrage(
                tokenId,
                reward,
                precisionValue,
                _totalSupply
            );
    }

    // Method to charge the processing fees.
    function calculateClaimFee(uint256 tokenId, uint256 reward)
        public
        view
        returns (uint256)
    {
        return
            (reward * getClaimFeePercentrage(tokenId, reward)) /
            (100 * precisionValue);
    }

    // Method to harvest reward.
    function claimReward(uint256 tokenId) public propertyExists(tokenId) nonReentrant {
        // Get reward calculated till tax is cleared or current time.
        (uint256 reward, uint256 processedTill) = calculateReward(tokenId);

        // Charege the claim fees.
        uint256 claimCharges = calculateClaimFee(tokenId, reward);
        reward -= claimCharges;

        // update the reward calculation duration.`
        properties.updateReward(tokenId, 0, processedTill);

        // send the reward
        ITheNeighbours _neighbour = ITheNeighbours(neighbour);

        // transfer reward from reward pool.
        if (pool.rewardPool == address(this)) {
            _neighbour.transfer(ownerOf(tokenId), reward);
        } else {
            _neighbour.specialTransfer(
                pool.rewardPool,
                ownerOf(tokenId),
                reward
            );
        }

        emit RewardClaimed(tokenId, ownerOf(tokenId), reward, claimCharges);
    }

    // Internal method to calculate required amount to be paid and deduct if from reward.
    function _payByReward(uint256 tokenId, uint256 amount) internal {
        // Get reward calculated till tax is cleared or current time.
        (uint256 reward, uint256 processedTill) = calculateReward(tokenId);

        // Check if have suffiecient reward to pay
        require(
            amount <= reward,
            "TheProperty: Insufficient reward to pay the amount"
        );

        // update the reward calculation duration.
        properties.updateReward(tokenId, reward - amount, processedTill);
    }

    // Method to pay by reward in property contract.
    function payByReward(uint256 tokenId, uint256 amount) external {
        // Only allowed to furniture contract as external contract.
        require(
            msg.sender == furniture,
            "TheProperty: Allowed to furniture contract only."
        );

        // Calculate and deduct the reward.
        _payByReward(tokenId, amount);

        emit PaidByReward(tokenId, ownerOf(tokenId), msg.sender, amount);
    }

    // ********************************Property furniture section end *********

    // ********************************Property transfer section start ********

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Initialte original transfer.
        super._transfer(from, to, tokenId);

        claimReward(tokenId);

        // Transfer all furnitures.
        ITheFurniture _furniture = ITheFurniture(furniture);
        // Try to transfer all the Furnitures and do nothing if fails.
        try
            _furniture.transferFromByPropertyBatch(
                from,
                to,
                properties.get(tokenId).furnitureIndices.values
            )
        {} catch {}
    }

    // Private method to check array is subArray of superArray.
    function arrayIsSubArray(
        uint256[] memory superArray,
        uint256[] memory subArray
    ) private pure returns (bool) {
        for (uint256 i = 0; i < subArray.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < superArray.length; j++) {
                if (subArray[i] == superArray[j]) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                return false;
            }
        }
        return true;
    }

    // Transfer the furnitures to new owner if missed due to gas issue.
    function transferPendingProperties(
        uint256 tokenId,
        address from,
        uint256[] memory tokenIds
    ) public propertyExists(tokenId) {
        require(
            arrayIsSubArray(
                properties.get(tokenId).furnitureIndices.values,
                tokenIds
            ),
            "TheProperty: TokenIds must be of current property only."
        );
        // Transfer all furnitures.
        ITheFurniture _furniture = ITheFurniture(furniture);

        // Try to transfer all the Furnitures and do nothing if fails.
        _furniture.transferFromByPropertyBatch(
            from,
            ownerOf(tokenId),
            properties.get(tokenId).furnitureIndices.values
        );
    }

    // ********************************Property transfer section end **********

    ///////////////////////////////////////////////////////////////////////////
    // Business Logic End
    ///////////////////////////////////////////////////////////////////////////

    function initialize() public initializer {
        __ERC721_init("The Property", "PRT");
        __ERC721Burnable_init();
        __ERC721Enumerable_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        // Set PrecisionValue
        precisionValue = 10**5;

        // Set due allowed.
        properties.setTaxDueAllowed(30 days);

        // Insert blank property at init to match the tokenId from ERC721
        PropertyLib.property memory _property; // MUST NOT BE DELETED
        properties.array.push(_property); // MUST NOT BE DELETED

        // Create all 4 default categories.
        string[3] memory _properyTypeNames = ["Condo", "House", "Mansion"];

        // Prices in $NEIBR
        uint256[3] memory _prices = [
            uint256(4 * (10**18)), // Condo   4 $NEIBR
            7 * (10**18), // House   7 $NEIBR
            10 * (10**18) // Mansion 10 $NEIBR
        ];

        // Daily rewards in $NEIBR
        uint256[3] memory _dailyRewards = [
            uint256(6 * (10**16)), // Condo 0.06 $NEIBR
            8 * (10**16), // House  0.08 $NEIBR
            10 * (10**16) // Mansion 0.1 $NEIBR
        ];

        // Max daily rewards in $NEIBR
        uint256[3] memory _maxDailyRewards = [
            uint256(8 * (10**16)), // Condo Max (with home decor) 0.08 $NEIBR
            10 * (10**16), // House Max (with home decor) 0.1 $NEIBR
            13 * (10**16) // Mansion Max (with home decor) 0.13 $NEIBR
        ];

        // Monthly tax in doller. It have 6 decimal presion only.
        uint256[3] memory _monthlyTaxs = [
            uint256(10 * (10**6)), // Condo    10$ a month paid in $AVAX
            13 * (10**6), // House    13$ a month paid in $AVAX
            17 * (10 * 6) // Mansion  17$ a month paid in $AVAX
        ];

        for (uint256 i = 0; i < _properyTypeNames.length; i++) {
            propertyTypes.create(
                _properyTypeNames[i],
                _prices[i],
                _dailyRewards[i],
                _maxDailyRewards[i],
                _monthlyTaxs[i]
            );
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}