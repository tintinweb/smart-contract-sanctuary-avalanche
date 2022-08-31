/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-30
*/

pragma solidity ^0.5.0;



contract Users {
    // data structure that stores a user
    struct User {
        string name;
        string lastName;
        bool isOver18;
        string birthDate;
        bool isInvestor;        
        bytes32 status;
        address walletAddress;
        uint createdAt;
        uint updatedAt;
    }

    // it maps the user's wallet address with the user ID
    mapping (address => uint) public usersIds;

    // Array of User that holds the list of users and their details
    User[] public users;

    // event fired when an user is registered
    event newUserRegistered(uint id);

    // event fired when the user updates his status or name
    event userUpdateEvent(uint id);



    // Modifier: check if the caller of the smart contract is registered
    modifier checkSenderIsRegistered {
    	require(isRegistered());
    	_;
    }



    /**
     * Constructor function
     */
    constructor() public
    {
        // NOTE: the first user MUST be emtpy: if you are trying to access to an element
        // of the usersIds mapping that does not exist (like usersIds[0x12345]) you will
        // receive 0, that's why in the first position (with index 0) must be initialized
        addUser(address(0x0),"","",false,"",false,"");
    }



    /**
     * Function to register a new user.
     *
     * @param _userName 		The displaying name
     * @param _lastName         The displaying last name
     * @param _isOver18         The displaying 18 over
     * @param _birthDate        The displaying birth date
     * @param _isInvestor       The displaying investor
     * @param _status        The status of the user
     */
    function registerUser(string memory _userName, string memory _lastName, bool _isOver18, string memory _birthDate, bool _isInvestor, bytes32 _status) public
    returns(uint)
    {
    	return addUser(msg.sender, _userName, _lastName, _isOver18, _birthDate, _isInvestor, _status);
    }



    /**
     * Add a new user. This function must be private because an user
     * cannot insert another user on behalf of someone else.
     *
     * @param _wAddr 		Address wallet of the user
     * @param _userName		Displaying name of the user
     * @param _lastName     Displaying last name of the user
     * @param _isOver18     Displaying 18 over
     * @param _birthDate    Displaying birth date of the user
     * @param _isInvestor   Displaying investor of the user
     * @param _status    	Status of the user
     */
    function addUser(address _wAddr, string memory _userName, string memory _lastName, bool _isOver18,string memory _birthDate, bool _isInvestor, bytes32 _status) private
    returns(uint)
    {
        // checking if the user is already registered
        uint userId = usersIds[_wAddr];
        require (userId == 0);

        // associating the user wallet address with the new ID
        usersIds[_wAddr] = users.length;
        uint newUserId = users.length++;

        // storing the new user details
        users[newUserId] = User({
        	name: _userName,
            lastName: _lastName,
            isOver18: _isOver18,
            birthDate: _birthDate,
            isInvestor: _isInvestor,
        	status: _status,
        	walletAddress: _wAddr,
        	createdAt: now,
        	updatedAt: now
        });

        // emitting the event that a new user has been registered
        emit newUserRegistered(newUserId);

        return newUserId;
    }



    /**
     * Update the user profile of the caller of this method.
     * Note: the user can modify only his own profile.
     *
     * @param _newUserName	    The new user's displaying name
     * @param _newLastName      The new user's displaying last name
     * @param _newIsOver18      The new user's displaying 18 over
     * @param _newBirthDate     The new user's displaying birth date
     * @param _newIsInvestor    The new user's displayin investor
     * @param _newStatus 	    The new user's status
     */
    function updateUser(string memory _newUserName, string memory _newLastName, bool _newIsOver18, string memory _newBirthDate, bool _newIsInvestor, bytes32 _newStatus) checkSenderIsRegistered public
    returns(uint)
    {
    	// An user can modify only his own profile.
    	uint userId = usersIds[msg.sender];

    	User storage user = users[userId];

    	user.name = _newUserName;
        user.lastName = _newLastName;
        user.isOver18 = _newIsOver18;
        user.birthDate = _newBirthDate;
        user.isInvestor = _newIsInvestor;
    	user.status = _newStatus;
    	user.updatedAt = now;

    	emit userUpdateEvent(userId);

    	return userId;
    }



    /**
     * Get the user's profile information.
     *
     * @param _id 	The ID of the user stored on the blockchain.
     */
    function getUserById(uint _id) public view
    returns(
    	uint,
    	string memory,
        string memory,
        bool,
        string memory,
        bool,
    	bytes32,
    	address,
    	uint,
    	uint
    ) {
    	// checking if the ID is valid
    	require( (_id > 0) || (_id <= users.length) );

    	User memory i = users[_id];

    	return (
    		_id,
    		i.name,
            i.lastName,
            i.isOver18,
            i.birthDate,
            i.isInvestor,
    		i.status,
    		i.walletAddress,
    		i.createdAt,
    		i.updatedAt
    	);
    }


    /**
     * Return the profile information of the caller.
     */
    function getOwnProfile() checkSenderIsRegistered public view
    returns(
  	    uint,
    	string memory,
        string memory,
        bool,
        string memory,
        bool,
    	bytes32,
    	address,
    	uint,
    	uint
    ) {
    	uint id = usersIds[msg.sender];

    	return getUserById(id);
    }



    /**
     * Check if the user that is calling the smart contract is registered.
     */
    function isRegistered() public view returns (bool)
    {
    	return (usersIds[msg.sender] > 0);
    }



    /**
     * Return the number of total registered users.
     */
    function totalUsers() public view returns (uint)
    {
        // NOTE: the total registered user is length-1 because the user with
        // index 0 is empty check the contructor: addUser(address(0x0), "", "");
        return users.length - 1;
    }

}