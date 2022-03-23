// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Product.sol";
import "./IHelloWorldInsurance.sol";
import "./HelloWorldOracle.sol";


contract HelloWorldInsurance is IHelloWorldInsurance, Product {

    bytes32 public constant VERSION = "0.0.1";
    bytes32 public constant POLICY_FLOW = "PolicyFlowDefault";

    uint256 public constant MIN_PREMIUM = 10 * 10**16;
    uint256 public constant MAX_PREMIUM = 1500 * 10**16;

    uint256 public constant PAYOUT_FACTOR_RUDE_RESPONSE = 3;
    uint256 public constant PAYOUT_FACTOR_NO_RESPONSE = 1;
    uint256 public constant PAYOUT_FACTOR_KIND_RESPONSE = 0;

    uint16 public constant MAX_LENGTH_GREETING = 32;
    string public constant CALLBACK_METHOD_NAME = "greetingCallback";

    uint256 public uniqueIndex;
    bytes32 public greetingsOracleType;
    uint256 public greetingsOracleId;

    mapping(bytes32 => address) public policyIdToAddress;
    mapping(address => bytes32[]) public addressToPolicyIds;

    constructor(
        address gifProductService,
        bytes32 productName,
        bytes32 oracleType,
        uint256 oracleId
    )
        Product(gifProductService, productName, POLICY_FLOW)
    {
        greetingsOracleType = oracleType;
        greetingsOracleId = oracleId;
    }

    function applyForPolicy() external payable override returns (bytes32 policyId) {

        address payable policyHolder = payable(msg.sender);
        uint256 premium = _getValue();

        // Create new ID for this policy
        policyId = _uniqueId(policyHolder);

        // Validate input parameters
        require(premium >= MIN_PREMIUM, "ERROR:HWI-001:INVALID_PREMIUM");
        require(premium <= MAX_PREMIUM, "ERROR:HWI-002:INVALID_PREMIUM");

        // Create and underwrite new application
        _newApplication(policyId, abi.encode(premium, policyHolder));
        _underwrite(policyId);

        emit LogHelloWorldPolicyCreated(policyId);

        // Book keeping to simplify lookup
        policyIdToAddress[policyId] = policyHolder;
        addressToPolicyIds[policyHolder].push(policyId);
    }

    function greet(bytes32 policyId, string calldata greeting) external override {

        // Validate input parameters
        require(policyIdToAddress[policyId] == msg.sender, "ERROR:HWI-003:INVALID_POLICY_OR_HOLDER");
        require(bytes(greeting).length <= MAX_LENGTH_GREETING, "ERROR:HWI-004:GREETING_TOO_LONG");

        emit LogHelloWorldGreetingReceived(policyId, greeting);

        // request response to greeting via oracle call
        uint256 requestId = _request(
            policyId,
            abi.encode(greeting),
            CALLBACK_METHOD_NAME,
            greetingsOracleType,
            greetingsOracleId
        );

        emit LogHelloWorldGreetingCompleted(requestId, policyId, greeting);
    }

    function greetingCallback(uint256 requestId, bytes32 policyId, bytes calldata response)
        external
        onlyOracle
    {
        // get policy data for oracle response
        (uint256 premium, address payable policyHolder) = abi.decode(
            _getApplicationData(policyId), (uint256, address));

        // get oracle response data
        (HelloWorldOracle.AnswerType answer) = abi.decode(response, (HelloWorldOracle.AnswerType));

        // claim handling based on reponse to greeting provided by oracle 
        _handleClaim(policyId, policyHolder, premium, answer);
        
        // policy only covers a single greeting/response pair
        // policy can therefore be expired
        _expire(policyId);

        emit LogHelloWorldCallbackCompleted(requestId, policyId, response);
}

    function withdraw(uint256 amount) external override onlyOwner {
        require(amount <= address(this).balance);

        address payable receiver;
        receiver = payable(owner());
        receiver.transfer(amount);
    }

    function _getValue() internal returns(uint256 premium) { premium = msg.value; }

    function _uniqueId(address senderAddress) internal returns (bytes32 uniqueId) {
        uniqueIndex += 1;
        return keccak256(abi.encode(senderAddress, productId, uniqueIndex));
    }

    function _handleClaim(
        bytes32 policyId, 
        address payable policyHolder, 
        uint256 premium, 
        HelloWorldOracle.AnswerType answer
    ) 
        internal 
    {
        uint256 payoutAmount = _calculatePayoutAmount(premium, answer);

        // no claims handling for payouts == 0
        if (payoutAmount > 0) {
            uint256 claimId = _newClaim(policyId, abi.encode(payoutAmount));
            uint256 payoutId = _confirmClaim(policyId, claimId, abi.encode(payoutAmount));

            _payout(policyId, payoutId, true, abi.encode(payoutAmount));

            // actual transfer of funds for payout of claim
            policyHolder.transfer(payoutAmount);

            emit LogHelloWorldPayoutExecuted(policyId, claimId, payoutId, payoutAmount);
        }
    }

    function _calculatePayoutAmount(uint256 premium, HelloWorldOracle.AnswerType answer) 
        internal 
        pure 
        returns(uint256 payoutAmount) 
    {
        if (answer == HelloWorldOracle.AnswerType.Rude) {
            payoutAmount = PAYOUT_FACTOR_RUDE_RESPONSE * premium;
        } else if (answer == HelloWorldOracle.AnswerType.None) { 
            payoutAmount = PAYOUT_FACTOR_NO_RESPONSE * premium;
        } else { 
            // for kind response, all is well, no payout
            payoutAmount = 0;
        }
    }
}