// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SignedWallet } from "./SignedWallet.sol";
import { RequestFactory } from "./RequestFactory.sol";

/** 
 * @title Ethereum multi user wallet implementation.
 * @notice Wallet uses 'signer' role from SignedWallet to prevent calling vital methods.
 * @notice Every wallet action is represented by Request from RequestFactory.
 * @notice To 'run' any of request action (i.e sending transaction) required signatures must be collected from signers.
 * @notice If such requirement is satisfied anyone may execute that request.
 * @author kchn9
 */
contract MultiSigWallet is SignedWallet, RequestFactory {

    /// @notice Request state tracking events, emitted whenever Request of id is signed, signature is revoked or request is executed
    event RequestSigned(uint128 indexed id, address who);
    event RequestSignatureRevoked(uint128 indexed id, address who);
    event RequestExecuted(uint128 indexed id, address by);

    /// @notice Tracker of sent transaction, emitted when SEND_TRANSACTION request is executed
    event TransactionSent(address to, uint256 value, bytes txData);

    /// @notice Runs execution of Request with specified request _idx
    function execute(uint128 _idx) external checkOutOfBounds(_idx) notExecuted(_idx) {
        require(_requests[_idx].requiredSignatures <= _requests[_idx].currentSignatures, 
            "MultiSigWallet: Called request is not fully signed yet.");
        (/*idx*/,
        /*requiredSignatures*/,
        /*currentSignatures*/,
        RequestType requestType,
        bytes memory data,
        /*isExecuted*/) = _getRequest(_idx);
        if (requestType == RequestType.ADD_SIGNER || requestType == RequestType.REMOVE_SIGNER) {
            address who = abi.decode(data, (address));
            if (requestType == RequestType.ADD_SIGNER) {
                _addSigner(who);
            }
            if (requestType == RequestType.REMOVE_SIGNER) {
                _removeSigner(who);
            }
            emit RequestExecuted(_idx, msg.sender);
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.INCREASE_REQ_SIGNATURES) {
            _increaseRequiredSignatures();
            emit RequestExecuted(_idx, msg.sender);
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.DECREASE_REQ_SIGNATURES) {
            _decreaseRequiredSignatures();
            emit RequestExecuted(_idx, msg.sender);
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.SEND_TRANSACTION){
            (address to, uint256 value, bytes memory txData) = abi.decode(data, (address, uint256, bytes));
            (bool success, /*data*/) = to.call{ value: value }(txData);
            _requests[_idx].isExecuted = true;
            emit TransactionSent(to, value, txData);
            emit RequestExecuted(_idx, msg.sender);
            require(success, "MultiSigWallet: Ether transfer failed");
        }
        else {
            revert("MultiSigWallet: Specified request type does not exist.");
        }
    }

    /// @notice On-chain mechanism of signing contract of specified _idx
    function sign(uint128 _idx) external checkOutOfBounds(_idx) notExecuted(_idx) onlySigner {
        require(!isRequestSignedBy[_idx][msg.sender], "MultiSigWallet: Called request has been signed by sender already.");
        RequestFactory.Request storage requestToSign = _requests[_idx];
        isRequestSignedBy[_idx][msg.sender] = true;
        requestToSign.currentSignatures++;
        emit RequestSigned(_idx, msg.sender);
    }

    /// @notice Revokes the signature provided under the request
    function revokeSignature(uint128 _idx) external checkOutOfBounds(_idx) notExecuted(_idx) onlySigner {
        require(isRequestSignedBy[_idx][msg.sender], "MultiSigWallet: Caller has not signed request yet.");
        RequestFactory.Request storage requestToRevokeSignature = _requests[_idx];
        isRequestSignedBy[_idx][msg.sender] = false;
        requestToRevokeSignature.currentSignatures--;
        emit RequestSignatureRevoked(_idx, msg.sender);
    }

    /// @notice Wrapped call of internal _createAddSignerRequest from RequestFactory
    /// @param _who address of new signer
    function addSigner(address _who) external onlySigner hasBalance(_who) {
        _createAddSignerRequest(uint64(_requiredSignatures), _who);
    }

    /// @notice Wrapped call of internal _createRemoveSignerRequest from RequestFactory
    /// @param _who address of signer to remove
    function removeSigner(address _who) external onlySigner {
        require(_signers[_who], "MultiSigWallet: Indicated address to delete is not signer.");
        _createRemoveSignerRequest(uint64(_requiredSignatures), _who); 
    }

    /// @notice Wrapped call of internal _createIncrementReqSignaturesRequest from RequestFactory
    function increaseRequiredSignatures() external onlySigner {
        require(_requiredSignatures + 1 <= _signersCount, "MultiSigWallet: Required signatures cannot exceed signers count");
        _createIncrementReqSignaturesRequest(uint64(_requiredSignatures));
    }

    /// @notice Wrapped call of internal _createDecrementReqSignaturesRequest from RequestFactory
    function decreaseRequiredSignatures() external onlySigner {
        require(_requiredSignatures - 1 > 0, "MultiSigWallet: Required signatures cannot be 0.");
        _createDecrementReqSignaturesRequest(uint64(_requiredSignatures));
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
        require(_to != address(0), "MultiSigWallet: Cannot send transaction to address 0.");
        _createSendTransactionRequest(uint64(_requiredSignatures), _to, _value, _data);
    }

    /// @notice Getter for contract balance
    function getContractBalance() hasBalance(msg.sender) public view returns(uint256) {
        return address(this).balance;
    }

    /// @notice WALLET OVERRIDDEN FUNCTIONS (PROVIDING STANDARD WALLET FUNCTIONALITY)
    function deposit() public override payable {
        require(msg.value > 0, "MultiSigWallet: Value cannot be 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposit(msg.sender, msg.value);
    }

    receive() external override payable {
        deposit();
    }
    
    function withdraw(uint256 _amount) external override {
        require(_amount <= getBalance(), "MultiSigWallet: Callers balance is insufficient");
        _balances[msg.sender] -= _amount;
        emit FundsWithdraw(msg.sender, _amount);
        (bool success, /*data*/) = address(msg.sender).call{ value: _amount}("");
        require(success, "MultiSigWallet: Ether transfer failed");
    }

    function withdrawAll() external override hasBalance(msg.sender) {
        uint256 amount = getBalance();
        _balances[msg.sender] = 0;
        emit FundsWithdraw(msg.sender, amount);
        (bool success, /*data*/) = address(msg.sender).call{ value: amount}("");
        require(success, "MultiSigWallet: Ether transfer failed");
    }

    function getBalance() public override view returns(uint256) {
        return _balances[msg.sender];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice RequestFactory implements way to create Request [i.e. adding new signer, sending funds] of any type defined in RequestType.
 * @notice Every Request has data field which stores required data to execute requested action [i.e. address of new signer].
 * @notice Whenever Request is created it emits NewRequest event. All requests are tracked by their ids and stored in _request array.
 * @author kchn9
 */
contract RequestFactory {

    /// @notice Emitted whenever new request is created.
    event NewRequest(uint128 indexed idx, uint64 requiredSignatures, RequestType requestType, bytes data);

    /// @notice Requests are defined here
    enum RequestType { ADD_SIGNER, REMOVE_SIGNER, INCREASE_REQ_SIGNATURES, DECREASE_REQ_SIGNATURES, SEND_TRANSACTION }

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

    /// @notice Keep track of next request id and store all requests
    uint128 internal _requestIdx;
    Request[] internal _requests;

    /// @notice Check if called id is in _requests[id]
    modifier checkOutOfBounds(uint128 _idx) {
        require(_idx < _requests.length, "RequestFactory: Called request does not exist yet.");
        _;
    }

    /// @notice Allow call only requests not executed before
    modifier notExecuted(uint128 _idx) {
        require(!_requests[_idx].isExecuted, "RequestFactory: Called request has been executed already.");
        _;
    }

    /**
     * @notice Creates ADD_SIGNER request
     * @param _requiredSignatures amount of signatures required to execute request
     * @param _who address of new signer
     */
    function _createAddSignerRequest(
        uint64 _requiredSignatures,
        address _who
    ) internal {
        Request memory addSignerRequest = Request(
            _requestIdx, 
            _requiredSignatures,
            0,
            RequestType.ADD_SIGNER,
            abi.encode(_who),
            false
        );
        _requests.push(addSignerRequest);
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.ADD_SIGNER, abi.encode(_who));
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
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.REMOVE_SIGNER, abi.encode(_who));
        _requestIdx++;
    }

    /**
     * @notice Creates INCREASE_REQ_SIGNATURES request
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createIncrementReqSignaturesRequest(
        uint64 _requiredSignatures
    ) internal {
        Request memory incrementReqSignaturesRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.INCREASE_REQ_SIGNATURES,
            bytes(""),
            false
        );
        _requests.push(incrementReqSignaturesRequest);
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.INCREASE_REQ_SIGNATURES, bytes(""));
        _requestIdx++;
    }

    /**
     * @notice Creates DECREASE_REQ_SIGNATURES request
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createDecrementReqSignaturesRequest(
        uint64 _requiredSignatures
    ) internal {
        Request memory decrementReqSignaturesRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.DECREASE_REQ_SIGNATURES,
            bytes(""),
            false
        );
        _requests.push(decrementReqSignaturesRequest);
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.DECREASE_REQ_SIGNATURES, bytes(""));
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
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.SEND_TRANSACTION, abi.encodePacked(_to, _value, _data));
        _requestIdx++;
    }

    /// @notice default getter for request of specified request id
    function _getRequest(
        uint128 _idx
    ) internal view returns (
        uint128,
        uint64,
        uint64,
        RequestType,
        bytes memory,
        bool
    ) {
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

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Wallet.sol";

/**
 * @notice Contract that adds potential 'signing' mechanism used for authenticating some calls in future contracts.
 * @author kchn9
 */

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
    mapping(address => bool) internal _signers;

    /// @notice Access modifier to prevent calls from 'not-signer' user
    modifier onlySigner {
        require(_signers[msg.sender], "SignedWallet: Caller is not signer");
        _;
    }

    /// @notice Wallet creator is first signer
    constructor() {
        _signers[msg.sender] = true;
        _signersCount = 1;
        _requiredSignatures = 1;
    }

    /// @notice Counts signers
    uint internal _signersCount;
    /// @notice Represents how much signatures are needed for action
    uint internal _requiredSignatures;

    /// @notice Adds role 'signer' to specified address
    function _addSigner(address _who) internal {
        require(_who != address(0), "SignedWallet: New signer cannot be address 0.");
        _signers[_who] = true;
        _signersCount++;
        emit NewSigner(_who);
    }

    /// @notice Removes role 'signer' from specified address
    function _removeSigner(address _who) internal {
        _signers[_who] = false;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
 * Abstract contract implementing core features of wallet
 * @author kchn9
 */
contract Wallet {

    event FundsDeposit(address who, uint256 amount);
    event FundsWithdraw(address who, uint256 amount);

    /// @notice Keep track of users balances
    mapping (address => uint256) internal _balances;

    /// @notice Checks if specified user has
    modifier hasBalance(address _who) {
        require(_balances[_who] > 0, "Wallet: Specified address has no balance");
        _;
    }
    
    /// @notice Deposit user funds 
    function deposit() public virtual payable {}

    /// @notice Fallback - any funds sent directly to contract will be deposited
    receive() external virtual payable {}
    
    /// @notice Allow owner to withdraw only their funds
    function withdraw(uint256 _amount) virtual external {}

    function withdrawAll() virtual external {}

    /// @notice Getter for user balance
    function getBalance() public view virtual returns(uint256) {}

}