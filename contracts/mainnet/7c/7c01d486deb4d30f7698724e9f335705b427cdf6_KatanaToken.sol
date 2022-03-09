// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BEP20.sol";

contract KatanaToken is BEP20 {

    // Max holding rate in basis point. (default is 5% of total supply)
    uint16 public maxHoldingRate = 500;

    // Address that are identified as botters with holding of more than 5%.
    mapping(address => bool) private _includeToBlackList;

    // The operator
    address private _operator;

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier blackList(address sender, address recipent) {
        if (_includeToBlackList[sender] == true || _includeToBlackList[recipent] == true) {
            require(_includeToBlackList[sender] == false,"blackList: You have been blacklisted as a bot (SENDER)");
            require(_includeToBlackList[recipent] == false,"blackList: You have been blacklisted as a bot (RECIPENT)");
        }
        _;
    }

    /**
     * @notice Constructs the contract.
     */
    constructor () public BEP20('Samurai Finance', 'KATANA') {
        _operator = _msgSender();

        _includeToBlackList[msg.sender] = false;
        _includeToBlackList[address(this)] = false;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override blackList(sender, recipient) {
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Returns the max holding amount.
     */
    function maxHolding() public view returns (uint256) {
        return totalSupply().mul(maxHoldingRate).div(10000);
    }

    /**
     * @dev Include an address to blackList.
     * Can only be called by the current operator.
     */
    function setIncludeToBlackList(address _account) public onlyOperator {
        if (balanceOf(_account) > maxHolding()) {
            _includeToBlackList[_account] = true;
        } 
        else {
            _includeToBlackList[_account] = false;
        }
    }

    /**
     * @dev Exclude an address to blackList.
     * Can only be called by the current operator.
     */
    function setExcludeToBlackList(address _account) public onlyOperator {
        _includeToBlackList[_account] = false;
    }
}