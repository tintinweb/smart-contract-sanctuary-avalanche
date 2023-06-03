/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-02
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface GoldTokenInterface {
    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    ) external;

    function redemptionBasket(
        uint256 amount_, 
        address senderAddress_
    )external;
}

contract Wallet {
    event FundsDeposit(address who, uint256 amount);
    event FundsWithdraw(address who, uint256 amount);
    event DepositToken(address who, uint256 amount, address token);

    /// @notice Keep track of users balances
    mapping(address => uint256) internal _balances;

    /// @notice Checks if specified user has
    modifier hasBalance(address _who) {
        require(
            _balances[_who] > 0,
            "Wallet: Specified address has no balance"
        );
        _;
    }

    /// @notice Deposit user funds
    function deposit() public payable virtual {}

    /// @notice Fallback - any funds sent directly to contract will be deposited
    receive() external payable virtual {}

    /// @notice Allow owner to withdraw only their funds
    function withdraw(uint256 _amount) external virtual {}

    /// @notice Getter for user balance
    function getBalance() public view virtual returns (uint256) {}

    function getBalanceWho(address who) public view virtual returns (uint256) {}
}

contract SignedWallet is Wallet {

    /**
     * @notice Indicates if signer was added/removed
     * @param who new/removed signed address
     */
    event NewSigner(address who); 
    event DeleteSigner(address who);
 
    /// @notice Keep track of users with signer role
    // mapping(address => bool) internal _signers;
    mapping(address => bool) internal _signers;
    address[] internal _signerList;
    address internal _owner;

    /// @notice Access modifier to prevent calls from 'not-signer' user
    modifier onlySigner {
        require(_signers[msg.sender], "SignedWallet: Caller is not signer");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "SignedWallet: Caller is not the owner");
        _;
    }

    modifier isSigner (address _who){
        require(
            _signers[_who],
            "MultiSigWallet: Indicated address is not signer."
        );
        _;
    }

    modifier isNotSigner (address _who){
        require(
            !_signers[_who],
            "MultiSigWallet: Indicated address is signer."
        );
        _;
    }

    /// @notice Wallet creator is first signer
    constructor() {
        _owner = msg.sender;
        _signers[msg.sender] = true;
        _signerList.push(msg.sender);
        _signersCount = 1;
    }

    /// @notice Counts signers
    uint16 internal _signersCount;

    /// @notice Adds role 'signer' to specified address
    function _addSigner(address _who) internal {
        require(_who != address(0), "SignedWallet: New signer cannot be address 0.");
        _signers[_who] = true;
        _signerList.push(_who);
        _signersCount++;
        emit NewSigner(_who);
    }

    /// @notice Removes role 'signer' from specified address
    function _removeSigner(address _who) internal {
        _signers[_who] = false;
        uint index = 0;
        for (uint i = 0 ; i < _signerList.length; i++){
            if (_signerList[i] == _who){
                index = i;
                break;
            }
        }
        for (uint i = index; i< _signerList.length - 1; i++) {
            _signerList[i] = _signerList[i + 1];
        }
        delete _signerList[_signerList.length - 1];
        _signerList.pop();
        _signersCount--;
        emit DeleteSigner(_who);
    }

    function getOwner() public view virtual returns (address){}
    function getSigner(address who) public view virtual returns (bool) {}
    function getSignerCount() public view virtual returns (uint16) {}
    function getSignerList(uint index) public view virtual returns (address) {}
}

contract RequestFactory {
    /// @notice Emitted whenever new request is created.
    event NewRequest(
        uint128 indexed idx,
        uint64 requiredSignatures,
        RequestType requestType,
        bytes data
    );

    /// @notice Requests are defined here
    enum RequestType {
        CREATION_BASKET,
        REDEMPTION_BASKET
    }

    /// @notice Request, apart from idx, request type and data stores info about required/current signatures and if it was executed before.
    struct Request {
        uint128 idx;
        uint64 requiredSignatures;
        uint64 currentSignatures;
        RequestType requestType;
        bytes data;
        bool isExecuted;
    }

    /// @notice Checks if address(signer) already signded Request of given id
    mapping(uint128 => mapping(address => bool)) internal isRequestSignedBy;

    mapping(uint128 => address[]) public _requestSigners;
    /// @notice Keep track of next request id and store all requests
    uint128 internal _requestIdx;
    // Request[] internal _requests;
    Request[] public _requests;

    /// @notice Check if called id is in _requests[id]
    modifier checkOutOfBounds(uint128 _idx) {
        require(
            _idx < _requests.length,
            "RequestFactory: Called request does not exist yet."
        );
        _;
    }

    /// @notice Allow call only requests not executed before
    modifier notExecuted(uint128 _idx) {
        require(
            !_requests[_idx].isExecuted,
            "RequestFactory: Called request has been executed already."
        );
        _;
    }

    /**
     * @notice Creates CREATION_BASKET request
     * @param _requiredSignatures amount of signatures required to execute request
     * @param _amount token amout to add
     * @param _contract token contract address
     * @param _to address to add token
     * @param _basketType type of adding
     */
    function _createCreationBasketRequest(
        uint64 _requiredSignatures,
        address _contract,
        uint256 _amount,
        address _to,
        string memory _basketType
    ) internal {
        Request memory creationBasketRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.CREATION_BASKET,
            abi.encode(_contract, _amount, _to, _basketType),
            false
        );
        _requests.push(creationBasketRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.CREATION_BASKET,
            abi.encode(_contract, _amount, _to, _basketType)
        );
        _requestIdx++;
    }

    /**
     * @notice Creates REDEMPTION_BASKET request
     * @param _requiredSignatures amount of signatures required to execute request
     * @param _amount token amout to add
     * @param _contract token contract address
     * @param _to address to add token
     */
    function _createRedemptionBasketRequest(
        uint64 _requiredSignatures,
        address _contract,
        uint256 _amount,
        address _to
    ) internal {
        Request memory redemptionBasketRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.REDEMPTION_BASKET,
            abi.encode(_contract, _amount, _to),
            false
        );
        _requests.push(redemptionBasketRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.REDEMPTION_BASKET,
            abi.encode(_contract, _amount, _to)
        );
        _requestIdx++;
    }

    /// @notice default getter for request of specified request id
    function _getRequest(uint128 _idx)
        internal
        view
        returns (
            uint128,
            uint64,
            uint64,
            RequestType,
            bytes memory,
            bool
        )
    {
        Request memory r = _requests[_idx];
        return (
            r.idx,
            r.requiredSignatures,
            r.currentSignatures,
            r.requestType,
            r.data,
            r.isExecuted
        );
    }

    function _getRequestSigners(uint128 _idx)
        internal
        view
        returns(
            address[] memory
        )
    {
        address[] memory a = _requestSigners[_idx];
        return a;
    }

    function getRequestLength()
        public
        view
        returns (uint256){
            return _requests.length;
    }
    function checkSign(uint128 idx, address who)
        public
        view
        returns (bool){
        return isRequestSignedBy[idx][who];
    }
}

contract RuleFactory {
    uint256 internal _creationLimit;
    uint16 internal _creationRequiredSignature;
    event NewUpdateCreationRule(
        uint256 _newLimit,
        uint16 _newRequiredSignature
    );
    
    uint256 internal _redemptionLimit;
    uint16 internal _redemptionRequiredSignature;
    event NewUpdateRedemptionRule(
        uint256 _newLimit,
        uint16 _newRequiredSignature
    );

    function _updateCreationRule (
        uint256 _newLimit,
        uint16 _newRequiredSignature
    ) internal {
        _creationLimit = _newLimit;
        _creationRequiredSignature = _newRequiredSignature;
        emit NewUpdateCreationRule(_newLimit, _newRequiredSignature);
    }

    function _updateRedemptionRule (
        uint256 _newLimit,
        uint16 _newRequiredSignature
    ) internal {
        _redemptionLimit = _newLimit;
        _redemptionRequiredSignature = _newRequiredSignature;
        emit NewUpdateRedemptionRule(_newLimit, _newRequiredSignature);
    }
    
    function getCreationRule() public view virtual returns (uint256, uint16) {}
    function getRedemptionRule() public view virtual returns (uint256, uint16) {}
}

contract MultiSigV1 is SignedWallet, RequestFactory, RuleFactory {
    /// @notice Request state tracking events, emitted whenever Request of id is signed, signature is revoked or request is executed
    event RequestSigned(uint128 indexed id, address who);
    event RequestExecuted(uint128 indexed id, address by);
    /// @notice Tracker of adding token
    event CreationBasket(uint256 amount, address to, string basketType);
    event RedemptionBasket ( uint256 amount, address to);
    /// @notice Runs execution of Request with specified request _idx
    function execute(uint128 _idx)
        external
        checkOutOfBounds(_idx)
        notExecuted(_idx)
    {
        require(
            _requests[_idx].requiredSignatures <=
                _requests[_idx].currentSignatures,
            "MultiSigWallet: Called request is not fully signed yet."
        );
        (
            ,
            ,
            ,
            RequestType requestType,
            bytes memory data, /*isExecuted*/
        ) = _getRequest(_idx);
        if (requestType == RequestType.CREATION_BASKET) {
            (address _contract, uint256 _amount, address _to, string memory _basketType) = abi.decode(
                data,
                (address, uint256, address, string)
            );
            GoldTokenInterface instance = GoldTokenInterface(_contract);
            instance.creationBasket(_amount, _to, _basketType);
            emit CreationBasket(_amount, _to, _basketType);
        } else if (requestType == RequestType.REDEMPTION_BASKET){
            (address _contract, uint256 _amount, address _to) = abi.decode(
                data,
                (address, uint256, address)
            );
            GoldTokenInterface instance = GoldTokenInterface(_contract);
            instance.redemptionBasket(_amount, _to);
            emit RedemptionBasket(_amount, _to);
        } else {
            revert("MultiSigWallet: Specified request type does not exist.");
        }
        _requests[_idx].isExecuted = true;
    }

    function sign(uint128 _idx)
        external
        checkOutOfBounds(_idx)
        notExecuted(_idx)
        onlySigner
    {
        require(
            !isRequestSignedBy[_idx][msg.sender],
            "MultiSigWallet: Called request has been signed by sender already."
        );
        RequestFactory.Request storage requestToSign = _requests[_idx];
        isRequestSignedBy[_idx][msg.sender] = true;
        requestToSign.currentSignatures++;
        address[] storage requestSigners = _requestSigners[_idx];
        requestSigners.push(msg.sender);
        emit RequestSigned(_idx, msg.sender);
    }

    function addSigner(address _who) 
        external 
        onlyOwner 
        isNotSigner (_who)
    {
        _addSigner(_who);
    }

    /// @notice Wrapped call of internal _createRemoveSignerRequest from RequestFactory
    /// @param _who address of signer to remove
    function removeSigner(address _who) 
        external 
        onlyOwner 
        isSigner(_who)
    {
        _removeSigner(_who);
    }

    function creationBasket (
        address _contract,
        uint256 _amount,
        address _to,
        string memory _basketType
    ) external onlySigner(){
        if (_amount > _creationLimit){
            _createCreationBasketRequest(
                uint64(_creationRequiredSignature),
                _contract,
                _amount,
                _to,
                _basketType
            );
        } else{
            GoldTokenInterface instance = GoldTokenInterface(_contract);
            instance.creationBasket(_amount, _to, _basketType);
            emit CreationBasket(_amount, _to, _basketType);
        }
    }

    function redemptionBasket(
        address _contract, 
        uint256 _amount, 
        address _to
    ) external onlySigner {
        if (_amount > _redemptionLimit){
            _createRedemptionBasketRequest(
                uint64(_redemptionRequiredSignature),
                _contract,
                _amount,
                _to
            );
        } else {
            GoldTokenInterface instance = GoldTokenInterface(_contract);
            instance.redemptionBasket(_amount, _to);
            emit RedemptionBasket(_amount, _to);
        }
    }


    function updateCreationRule(
        uint256 _newLimit, 
        uint16 _newRequiredSignature
    ) external onlyOwner {
        _updateCreationRule(
            _newLimit,
            _newRequiredSignature
        );
    }

    function updateRedemptionRule(
        uint256 _newLimit, 
        uint16 _newRequiredSignature
    ) external onlyOwner {
        _updateRedemptionRule(
            _newLimit, 
            _newRequiredSignature
        );
    }
    
    receive() external payable override {
        deposit();
    }

    function getBalance() public view override returns (uint256) {
        return _balances[msg.sender];
    }

    function getBalanceWho(address who) public view override returns (uint256) {
        return _balances[who];
    }

    function getCreationRule() public view override returns (uint256, uint16){
        return (_creationLimit, _creationRequiredSignature);
    }

    function getRedemptionRule() public view override returns (uint256, uint16){
        return (_redemptionLimit, _redemptionRequiredSignature);
    }

    function getOwner() public view override returns (address){
        return _owner;
    }

    function getSigner(address who) public view override returns (bool){
        return _signers[who];
    }

    function getSignerCount() public view override returns (uint16){
        return _signersCount;
    }

    function getSignerList(uint index) public view override returns (address){
        return _signerList[index];
    }
}