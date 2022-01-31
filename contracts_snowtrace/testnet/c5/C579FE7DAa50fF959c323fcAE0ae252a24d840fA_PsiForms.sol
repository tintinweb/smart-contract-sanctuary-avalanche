/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

contract Gate {
	address payable public owner;

	modifier onlyOwner() {
		require(msg.sender == owner, 'Owner only');
		_;
	}

	function setOwner(address payable _owner) public onlyOwner {
		_setOwner(_owner);
	}

	function _setOwner(address payable _owner) internal {
		require(_owner != address(0));
		owner = _owner;
	}
}

contract Pausable is Gate {

	bool public isPaused = false;

	modifier onlyNotPaused() {
		require(!isPaused, 'Contract is paused');
		_;
	}

	modifier onlyPaused() {
		require(isPaused, 'Contract is not paused');
		_;
	}

	function pause() public onlyOwner onlyNotPaused {
		isPaused = true;
	}

	function unpause() public onlyOwner onlyPaused {
		isPaused = false;
	}
}

contract PsiForms is Gate, Pausable {

	uint16 public fee = 25; // 4%
	uint public minApprovalTime = 86400;
	uint public minUnitPrice = 100000;

	mapping (uint128 => Form) public forms;
	mapping (uint128 => mapping(uint128 => Request)) public requests;

	struct Form {
		bool isEnabled;
		bool isBanned;
		bool requireApproval;
		uint64 minQuantity;
		uint64 maxQuantity;
		uint unitPrice;
		uint income;
		address payable creator;
	}

	struct Request {
		uint64 quantity;
		uint value;
		uint256 hash;
		uint createdAt;
		RequestStatus status;
		address payable sender;
	}

	enum RequestStatus {
		__,
		pending,
		approved,
		rejected,
		rolledBack
	}

	event FormCreated(uint _formId, address _creator, bool _isEnabled, bool _requireApproval, uint64 _minQuantity, uint64 _maxQuantity, uint _unitPrice);
	event FormUpdated(uint _formId, bool _isEnabled, uint64 _minQuantity, uint64 _maxQuantity, uint _unitPrice);
	event FormBanChanged(uint _formId, bool _isBanned);
	event RequestCreated(uint _formId, uint _requestId, address _sender, uint64 _quantity, uint _value, uint256 _hash);
	event RequestApproved(uint _formId, uint _requestId);
	event RequestRejected(uint _formId, uint _requestId);
	event RequestRolledBack(uint _formId, uint _requestId);
	event Transfered(address _target, uint _value);

	constructor() {
		_setOwner(payable(msg.sender));
	}

	function setFee(uint16 _fee) public onlyOwner {
		require(_fee > 2, 'Invalid fee');
		fee = _fee;
	}

	function setMinApprovalTime(uint _mat) public onlyOwner {
		minApprovalTime = _mat;
	}

	function setMinUnitPrice(uint _minUnitPrice) public onlyOwner {
		minUnitPrice = _minUnitPrice;
	}

	function createForm(uint128 _formId, bool _isEnabled, bool _requireApproval, uint64 _minQuantity, uint64 _maxQuantity, uint _unitPrice) public onlyNotPaused {
		Form storage _form = forms[_formId];
		require(_form.creator == address(0), 'formId is already used');
		_requireCorrectValues(_minQuantity, _maxQuantity, _unitPrice);

		_form.isEnabled = _isEnabled;
		_form.isBanned = false;
		_form.requireApproval = _requireApproval;
		_form.minQuantity = _minQuantity;
		_form.maxQuantity = _maxQuantity;
		_form.unitPrice = _unitPrice;
		_form.income = 0;
		_form.creator = payable(msg.sender);
		emit FormCreated(_formId, msg.sender, _isEnabled, _requireApproval, _minQuantity, _maxQuantity, _unitPrice);
	}

	function updateForm(uint128 _formId, bool _isEnabled, uint64 _minQuantity, uint64 _maxQuantity, uint _unitPrice) public onlyNotPaused {
		Form storage _form = forms[_formId];
		_requireCreator(_form);
		_requireCorrectValues(_minQuantity, _maxQuantity, _unitPrice);

		_form.isEnabled = _isEnabled;
		_form.minQuantity = _minQuantity;
		_form.maxQuantity = _maxQuantity;
		_form.unitPrice = _unitPrice;

		emit FormUpdated(_formId, _isEnabled, _minQuantity, _maxQuantity, _unitPrice);
	}

	function banForm(uint128 _formId, bool _isBanned) public onlyNotPaused onlyOwner {
		Form storage _form = forms[_formId];
		require(_form.creator != address(0), 'Form does not exist');

		_form.isBanned = _isBanned;
		emit FormBanChanged(_formId, _isBanned);
	}

	function createRequest(uint128 _formId, uint128 _requestId, uint64 _quantity, uint256 _hash) public payable onlyNotPaused {
		Form storage _form = forms[_formId];
		require(_form.creator != address(0), 'Form does not exist');
		require(_form.isEnabled, 'Form is disabled');
		require(!_form.isBanned, 'Form is banned');
		require(_quantity >= _form.minQuantity, 'Quantity is too low');
		require(_quantity <= _form.maxQuantity, 'Quantity is too high');

		uint _value = _quantity * _form.unitPrice;
		require(_value == msg.value, 'Invalid value');

		Request storage _request = requests[_formId][_requestId];
		require(_request.sender == address(0), 'adId is already used');
		_request.sender = payable(msg.sender);
		_request.quantity = _quantity;
		_request.value = _value;
		_request.hash = _hash;
		_request.createdAt = block.timestamp;
		_request.status = RequestStatus.pending;

		emit RequestCreated(_formId, _requestId, msg.sender, _quantity, _value, _hash);

		if (!_form.requireApproval) {
			_approveRequest(_formId, _form, _requestId, _request);
		}
	}

	function rollBackRequest(uint128 _formId, uint128 _requestId) public onlyNotPaused {
		Request storage _request = requests[_formId][_requestId];
		_requireSender(_request);
		require(_request.status == RequestStatus.pending, 'Request has wrong status');
		require(_request.createdAt + minApprovalTime <= block.timestamp, 'Too early');

		_rollBackRequest(_formId, _requestId, _request);
	}

	function approveOrRejectRequests(uint128 _formId, uint128[] memory _requestIds, bool[] memory _statuses) public onlyNotPaused {
		Form storage _form = forms[_formId];
		_requireCreator(_form);
		require(_requestIds.length > 0, 'Nothing to do');
		require(_requestIds.length == _statuses.length, 'Invalid pair');

		uint _n = _requestIds.length;
		for (uint _i = 0; _i < _n; _i++) {
			uint128 _requestId = _requestIds[_i];
			Request storage _request = requests[_formId][_requestId];
			require(_request.sender != address(0), 'Request does not exist');
			require(_request.status == RequestStatus.pending, 'Request has wrong status');

			if (_statuses[_i]) {
				_approveRequest(_formId, _form, _requestId, _request);
			} else {
				_rejectRequest(_formId, _requestId, _request);
			}
		}
	}

	function _approveRequest(uint128 _formId, Form storage _form, uint128 _requestId, Request storage _request) private {
		_request.status = RequestStatus.approved;
		emit RequestApproved(_formId, _requestId);

		uint _feeValue = _request.value / uint(fee);
		uint _creatorValue = _request.value - _feeValue;
		require(_feeValue + _creatorValue == _request.value, 'Invalid calculation');

		_transfer(owner, _feeValue);
		_transfer(_form.creator, _creatorValue);

		_form.income += _request.value;
	}

	function _rejectRequest(uint128 _formId, uint128 _requestId, Request storage _request) private {
		_request.status = RequestStatus.rejected;
		emit RequestRejected(_formId, _requestId);

		_transfer(_request.sender, _request.value);
	}

	function _rollBackRequest(uint128 _formId, uint128 _requestId, Request storage _request) private {
		_request.status = RequestStatus.rolledBack;
		emit RequestRolledBack(_formId, _requestId);

		_transfer(_request.sender, _request.value);
	}

	function _transfer(address payable _target, uint _value) private {
		(bool _success, ) = _target.call{ value: _value }('');
		require(_success, 'Transfer failed');
		emit Transfered(_target, _value);
	}

	//

	function _requireCreator(Form storage _form) private view {
		require(_form.creator == msg.sender, 'creator only');
	}

	function _requireSender(Request storage _request) private view {
		require(_request.sender == msg.sender, 'sender only');
	}

	function _requireCorrectValues(uint64 _minQuantity, uint64 _maxQuantity, uint _unitPrice) private view {
		require(_minQuantity > 0, 'Min quantity is to low');
		require(_maxQuantity >= _maxQuantity, 'Max quantity is lower than min quantity');
		require(_unitPrice > minUnitPrice, 'Unit price is to low');
	}
}