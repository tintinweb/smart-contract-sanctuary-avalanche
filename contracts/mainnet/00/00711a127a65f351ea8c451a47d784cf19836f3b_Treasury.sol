// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "./ERC20.sol";

contract Treasury {
    ERC20 immutable erc20;
    uint256 firnSupply;
    address owner;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    mapping(address => bool) skip;

    event Payout(address indexed recipient, uint256 amount);

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(address _erc20) {
        _status = _NOT_ENTERED;
        owner = msg.sender;
        erc20 = ERC20(_erc20);
    }

    function administrate(address _owner, address _treasury) external {
        require(msg.sender == owner, "Forbidden ownership transfer.");
        owner = _owner;
        erc20.administrate(_treasury);
        // this is if we redeploy the this contract, i.e., the treasury contract, but don't want to redeploy the ERC20.
        // we have to be able to point the ERC20 contract to the new treasury.
    }

    receive() external payable {
        payable(owner).transfer(msg.value >> 1);
    }

    function setSkip(address key, bool value) external {
        require(msg.sender == owner, "Forbidden access to skip list.");
        skip[key] = value;
    }

    function payout() external nonReentrant {
        require(gasleft() >= 7950000, "Not enough gas supplied.");
        erc20.setLockdown(true);
        firnSupply = erc20.totalSupply();
        traverse(erc20.tree().root());
        erc20.setLockdown(false);
    }

    function traverse(address cursor) internal {
        (,address left,address right,) = erc20.tree().nodes(cursor);

        if (right != erc20.tree().EMPTY()) {
            traverse(right);
        }
        if (gasleft() < 50000) {
            return;
        }
        uint256 firnBalance = erc20.balanceOf(cursor);
        if (!skip[cursor]) {
            uint256 amount = address(this).balance * firnBalance / firnSupply;
            // payable(cursor).send(amount);
            (bool success,) = payable(cursor).call{value: amount}("");
            if (success) {
                emit Payout(cursor, amount);
            }
        }
        // there is a further attack where someone could try to transfer their own firn balance within their `receive`.
        // the effect of this would be to get paid essentially twice for the same firn (there are other variants of this).
        // for this we need a further "lockdown" on the ERC-20 in order to prevent this.
        firnSupply -= firnBalance;
        if (left != erc20.tree().EMPTY()) {
            traverse(left);
        }
    }
}