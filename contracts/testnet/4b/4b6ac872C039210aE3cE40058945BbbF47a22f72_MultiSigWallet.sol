// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface GoldTokenInterface {
    function transfer(address to, uint256 amount) external returns (bool);

    function freezeAllTransactions() external;

    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    ) external;

    function redemptionBasket(
        uint256 amount_, 
        address senderAddress_
    )external;

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external;
}

contract Wallet {
    event FundsDeposit(address who, uint256 amount);
    event FundsWithdraw(address who, uint256 amount);
    event DepositToken(address who, uint256 amount, address token);

    /// @notice Keep track of users balances
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _tokenBalances;

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

    function depositToken(uint256 _amount, address _contract) public virtual{}

    /// @notice Fallback - any funds sent directly to contract will be deposited
    receive() external payable virtual {}

    /// @notice Allow owner to withdraw only their funds
    function withdraw(uint256 _amount) external virtual {}

    function withdrawAll() external virtual {}

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

    /**
     * @notice Emitted whenever signers decide to change amount of required signatures
     * @param oldVal old _requiredSignatures value
     * @param newVal new _requiredSignatures value
     */
    event RequiredSignaturesIncreased(uint oldVal, uint newVal);
    event RequiredSignaturesDecreased(uint oldVal, uint newVal);
    
    /// @notice Keep track of users with signer role
    // mapping(address => bool) internal _signers;
    mapping(address => bool) public _signers;
    address[] public _signerList;

    /// @notice Access modifier to prevent calls from 'not-signer' user
    modifier onlySigner {
        require(_signers[msg.sender], "SignedWallet: Caller is not signer");
        _;
    }

    /// @notice Wallet creator is first signer
    constructor() {
        _signers[msg.sender] = true;
        _signerList.push(msg.sender);
        _signersCount = 1;
        _requiredSignatures = 1;
    }

    /// @notice Counts signers
    uint public _signersCount;
    /// @notice Represents how much signatures are needed for action
    uint public _requiredSignatures;

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

    function _increaseRequiredSignatures() internal {
        if (_requiredSignatures + 1 <= _signersCount) {
            emit RequiredSignaturesIncreased(_requiredSignatures, _requiredSignatures + 1);
            _requiredSignatures++;
        }
    }

    function _decreaseRequiredSignatures() internal {
        if (_requiredSignatures - 1 < 1) {
            _requiredSignatures = _requiredSignatures;
        } else {
            emit RequiredSignaturesDecreased(_requiredSignatures, _requiredSignatures - 1);
            _requiredSignatures--;
        }
    }

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
        ADD_SIGNER,
        REMOVE_SIGNER,
        INCREASE_REQ_SIGNATURES,
        DECREASE_REQ_SIGNATURES,
        SEND_TRANSACTION,
        SEND_TOKEN,
        FREEZE_TRANSACTION,
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
     * @notice Creates ADD_SIGNER request
     * @param _requiredSignatures amount of signatures required to execute request
     * @param _who address of new signer
     */
    function _createAddSignerRequest(uint64 _requiredSignatures, address _who)
        internal
    {
        Request memory addSignerRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.ADD_SIGNER,
            abi.encode(_who),
            false
        );
        _requests.push(addSignerRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.ADD_SIGNER,
            abi.encode(_who)
        );
        _requestIdx++;
    }

    /**
     * @notice Creates REMOVE_SIGNER request
     * @param _requiredSignatures amount of signatures required to execute request
     * @param _who address of signer to remove
     */
    function _createRemoveSignerRequest(
        uint64 _requiredSignatures,
        address _who
    ) internal {
        Request memory removeSignerRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.REMOVE_SIGNER,
            abi.encode(_who),
            false
        );
        _requests.push(removeSignerRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.REMOVE_SIGNER,
            abi.encode(_who)
        );
        _requestIdx++;
    }

    /**
     * @notice Creates INCREASE_REQ_SIGNATURES request
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createIncrementReqSignaturesRequest(uint64 _requiredSignatures)
        internal
    {
        Request memory incrementReqSignaturesRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.INCREASE_REQ_SIGNATURES,
            bytes(""),
            false
        );
        _requests.push(incrementReqSignaturesRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.INCREASE_REQ_SIGNATURES,
            bytes("")
        );
        _requestIdx++;
    }

    /**
     * @notice Creates DECREASE_REQ_SIGNATURES request
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createDecrementReqSignaturesRequest(uint64 _requiredSignatures)
        internal
    {
        Request memory decrementReqSignaturesRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.DECREASE_REQ_SIGNATURES,
            bytes(""),
            false
        );
        _requests.push(decrementReqSignaturesRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.DECREASE_REQ_SIGNATURES,
            bytes("")
        );
        _requestIdx++;
    }

    /**
     * @notice Creates SEND_TRANSACTION request
     * @param _requiredSignatures amount of signatures required to execute request
     * @param _to address of transaction receiver
     * @param _data transaction data [i.e. to call receiver contract function]
     */
    function _createSendTransactionRequest(
        uint64 _requiredSignatures,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        Request memory sendTransactionRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.SEND_TRANSACTION,
            abi.encode(_to, _value, _data),
            false
        );
        _requests.push(sendTransactionRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.SEND_TRANSACTION,
            abi.encodePacked(_to, _value, _data)
        );
        _requestIdx++;
    }

    /**
     * @notice Creates FREEZE_TRANSACTION request
     * @param _requiredSignatures amount of signatures required to execute request
     * @param _contract address to freeze
     */
    function _createFreezeTransactionRequest(
        uint64 _requiredSignatures,
        address _contract
    ) internal {
        Request memory freezeTransactionRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.FREEZE_TRANSACTION,
            abi.encode(_contract),
            false
        );
        _requests.push(freezeTransactionRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.FREEZE_TRANSACTION,
            abi.encode(_contract)
        );
        _requestIdx++;
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

    /**
     * @notice Creates SEND_TOKEN request
     * @param _requiredSignatures amount of signatures required to execute request
     * @param _amount token amout to send
     * @param _contract token contract address
     * @param _to address to send token
     */
    function _createSendTokenRequest(
        uint64 _requiredSignatures,
        address _contract,
        uint256 _amount,
        address _from,
        address _to
    ) internal {
        Request memory sendTokenRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.SEND_TOKEN,
            abi.encode(_contract, _amount, _from, _to),
            false
        );
        _requests.push(sendTokenRequest);
        emit NewRequest(
            _requestIdx,
            _requiredSignatures,
            RequestType.SEND_TOKEN,
            abi.encode(_contract, _amount, _from, _to)
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

contract MultiSigWallet is SignedWallet, RequestFactory {
    /// @notice Request state tracking events, emitted whenever Request of id is signed, signature is revoked or request is executed
    event RequestSigned(uint128 indexed id, address who);
    event RequestSignatureRevoked(uint128 indexed id, address who);
    event RequestExecuted(uint128 indexed id, address by);

    /// @notice Tracker of sent transaction, emitted when SEND_TRANSACTION request is executed
    event TransactionSent(address to, uint256 value, bytes txData);
    /// @notice Tracker of adding token
    event CreationBasket(uint256 amount, address to, string basketType);

    event RedemptionBasket ( uint256 amount, address to);
    /// @notice Tracker of sending token
    event SendToken(uint256 amount, address to);
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
            /*idx*/
            /*requiredSignatures*/
            /*currentSignatures*/
            RequestType requestType,
            bytes memory data, /*isExecuted*/
        ) = _getRequest(_idx);
        if (
            requestType == RequestType.ADD_SIGNER ||
            requestType == RequestType.REMOVE_SIGNER
        ) {
            address who = abi.decode(data, (address));
            if (requestType == RequestType.ADD_SIGNER) {
                _addSigner(who);
            }
            if (requestType == RequestType.REMOVE_SIGNER) {
                _removeSigner(who);
            }
            emit RequestExecuted(_idx, msg.sender);
        } else if (requestType == RequestType.INCREASE_REQ_SIGNATURES) {
            _increaseRequiredSignatures();
            emit RequestExecuted(_idx, msg.sender);
        } else if (requestType == RequestType.DECREASE_REQ_SIGNATURES) {
            _decreaseRequiredSignatures();
            emit RequestExecuted(_idx, msg.sender);
        } else if (requestType == RequestType.SEND_TRANSACTION) {
            (address to, uint256 value, bytes memory txData) = abi.decode(
                data,
                (address, uint256, bytes)
            );
            (
                bool success, /*data*/

            ) = to.call{value: value}(txData);
            emit TransactionSent(to, value, txData);
            emit RequestExecuted(_idx, msg.sender);
            require(success, "MultiSigWallet: Ether transfer failed");
        } else if (requestType == RequestType.SEND_TOKEN) {
            (address _contract, uint256 _amount, address _from, address _to) = abi.decode(
                data,
                (address, uint256, address, address)
            );
            GoldTokenInterface instance = GoldTokenInterface(_contract);
            instance.transfer(_to, _amount);
            _tokenBalances[_from][_contract] -= _amount;
            emit SendToken(_amount, _to);
        } else if (requestType == RequestType.CREATION_BASKET) {
            (address _contract, uint256 _amount, address _to, string memory _basketType) = abi.decode(
                data,
                (address, uint256, address, string)
            );
            if (_amount > 1000000000000000000000){
                require(_requests[_idx].currentSignatures >= 3, "Creation more than 1000 should require more than 3 signers.");
            }
            GoldTokenInterface instance = GoldTokenInterface(_contract);
            instance.creationBasket(_amount, _to, _basketType);
            emit CreationBasket(_amount, _to, _basketType);
        } else if (requestType == RequestType.REDEMPTION_BASKET){
            (address _contract, uint256 _amount, address _to) = abi.decode(
                data,
                (address, uint256, address)
            );
            if (_amount > 1000000000000000000000){
                require(_requests[_idx].currentSignatures >= 3, "Redemption more than 1000 should require more than 3 signers.");
            }
            GoldTokenInterface instance = GoldTokenInterface(_contract);
            instance.redemptionBasket(_amount, _to);
            emit RedemptionBasket(_amount, _to);
        } else if (requestType == RequestType.FREEZE_TRANSACTION) {
            address tokenContract = abi.decode(data, (address));
            GoldTokenInterface instance = GoldTokenInterface(tokenContract);
            instance.freezeAllTransactions();
        } else {
            revert("MultiSigWallet: Specified request type does not exist.");
        }
        _requests[_idx].isExecuted = true;
    }

    /// @notice On-chain mechanism of signing contract of specified _idx
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

    /// @notice Revokes the signature provided under the request
    function revokeSignature(uint128 _idx)
        external
        checkOutOfBounds(_idx)
        notExecuted(_idx)
        onlySigner
    {
        require(
            isRequestSignedBy[_idx][msg.sender],
            "MultiSigWallet: Caller has not signed request yet."
        );
        RequestFactory.Request storage requestToRevokeSignature = _requests[
            _idx
        ];
        isRequestSignedBy[_idx][msg.sender] = false;
        requestToRevokeSignature.currentSignatures--;
        emit RequestSignatureRevoked(_idx, msg.sender);
    }

    /// @notice Wrapped call of internal _createAddSignerRequest from RequestFactory
    /// @param _who address of new signer
    function addSigner(address _who) 
        external 
        onlySigner 
        /// hasBalance(_who) 
    {
        _createAddSignerRequest(uint64(_requiredSignatures), _who);
    }

    /// @notice Wrapped call of internal _createRemoveSignerRequest from RequestFactory
    /// @param _who address of signer to remove
    function removeSigner(address _who) external onlySigner {
        require(
            _signers[_who],
            "MultiSigWallet: Indicated address to delete is not signer."
        );
        _createRemoveSignerRequest(uint64(_requiredSignatures), _who);
    }

    /// @notice Wrapped call of internal _createIncrementReqSignaturesRequest from RequestFactory
    function increaseRequiredSignatures() external onlySigner {
        require(
            _requiredSignatures + 1 <= _signersCount,
            "MultiSigWallet: Required signatures cannot exceed signers count"
        );
        _createIncrementReqSignaturesRequest(uint64(_requiredSignatures));
    }

    /// @notice Wrapped call of internal _createDecrementReqSignaturesRequest from RequestFactory
    function decreaseRequiredSignatures() external onlySigner {
        require(
            _requiredSignatures - 1 > 0,
            "MultiSigWallet: Required signatures cannot be 0."
        );
        _createDecrementReqSignaturesRequest(uint64(_requiredSignatures));
    }

    /// @notice Wrapped call of internal _createFreezeTransactionRequest from RequestFactory
    /// @param _contract address to freeze
    function createFreezeTransaction(address _contract) external onlySigner {
        _createFreezeTransactionRequest(uint64(_requiredSignatures), _contract);
    }

    /**
     * @notice Wrapped call of internal  _createCreationBasketRequest from RequestFactory
     * @param _contract address to add token
     * @param _amount token amout to add
     * @param _contract address to freeze
     * @param _to token contract address
     * @param _basketType type of adding
     */
    function createCreationBasketRequest(
        address _contract,
        uint256 _amount,
        address _to,
        string memory _basketType
    ) external onlySigner {
        _createCreationBasketRequest(
            uint64(_requiredSignatures),
            _contract,
            _amount,
            _to,
            _basketType
        );
    }

    /**
     * @notice Wrapped call of internal  _createRedemptionBasketRequest from RequestFactory
     * @param _contract address to add token
     * @param _amount token amout to add
     * @param _contract address to freeze
     * @param _to token contract address
     */
    function createRedemptionBasketRequest(
        address _contract,
        uint256 _amount,
        address _to
    ) external onlySigner {
        _createRedemptionBasketRequest(
            uint64(_requiredSignatures),
            _contract,
            _amount,
            _to
        );
    }
    
    /**
    * @notice Wrapped call of internal  _createCreationBasketRequest from RequestFactory
    * @param _contract address to add token
    * @param _amount token amout to add
    * @param _contract token contract address 
    * @param _to address to add token
    */ 
    function craeteSentTokenRequest(
        address _contract,
        uint256 _amount,
        address _to
    ) external onlySigner{
        require ( _tokenBalances[msg.sender][_contract] >= _amount, "Caller doesn't have enough amount in the contract wallet");
        _createSendTokenRequest(
            uint64(_requiredSignatures),
            _contract,
            _amount,
            msg.sender,
            _to
        );
    }
    /**
     * @notice Wrapped call of internal _createSendTransactionRequest from RequestFactory
     * @param _to address receiving transaction
     * @param _value ETH value to send
     * @param _data transaction data
     */
    function sendTx(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlySigner {
        require(
            _to != address(0),
            "MultiSigWallet: Cannot send transaction to address 0."
        );
        _createSendTransactionRequest(
            uint64(_requiredSignatures),
            _to,
            _value,
            _data
        );
    }

    /// @notice Getter for contract balance
    function getContractBalance()
        public
        view
        hasBalance(msg.sender)
        returns (uint256)
    {
        return address(this).balance;
    }

    /// @notice WALLET OVERRIDDEN FUNCTIONS (PROVIDING STANDARD WALLET FUNCTIONALITY)
    function deposit() public payable override {
        require(msg.value > 0, "MultiSigWallet: Value cannot be 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposit(msg.sender, msg.value);
    }

    function depositToken(uint256 _amount, address _contract) public override{
        require(_amount> 0, "MultiSigWallet: Amount cannot be 0");
        GoldTokenInterface instance = GoldTokenInterface(_contract);
        instance.transferFrom (msg.sender, address(this), _amount);
        _tokenBalances[msg.sender][_contract] += _amount;
        emit DepositToken(msg.sender, _amount, _contract);
    }

    receive() external payable override {
        deposit();
    }

    function withdraw(uint256 _amount) external override {
        require(
            _amount <= getBalance(),
            "MultiSigWallet: Callers balance is insufficient"
        );
        _balances[msg.sender] -= _amount;
        emit FundsWithdraw(msg.sender, _amount);
        (
            bool success, /*data*/

        ) = address(msg.sender).call{value: _amount}("");
        require(success, "MultiSigWallet: Ether transfer failed");
    }

    function withdrawAll() external override hasBalance(msg.sender) {
        uint256 amount = getBalance();
        _balances[msg.sender] = 0;
        emit FundsWithdraw(msg.sender, amount);
        (
            bool success, /*data*/

        ) = address(msg.sender).call{value: amount}("");
        require(success, "MultiSigWallet: Ether transfer failed");
    }

    function getBalance() public view override returns (uint256) {
        return _balances[msg.sender];
    }

    function getBalanceWho(address who) public view override returns (uint256) {
        return _balances[who];
    }
}