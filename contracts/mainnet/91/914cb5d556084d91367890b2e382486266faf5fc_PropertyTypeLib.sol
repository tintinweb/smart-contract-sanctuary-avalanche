/**
 *Submitted for verification at snowtrace.io on 2022-06-17
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