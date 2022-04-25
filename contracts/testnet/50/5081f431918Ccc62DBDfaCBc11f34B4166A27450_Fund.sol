/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @title A simple contract to which you can send money and then withdraw it.
 * @author The Everest team.
 */
contract Fund {
    mapping(address => uint256) public addressToAmountFunded;
    uint256 public totalFunds;
    address[] public funders;

    /**
     * @notice Send money to the fund.
     */
    function fund() external payable {
        addressToAmountFunded[msg.sender] += msg.value;
        totalFunds += msg.value;
        funders.push(msg.sender);
    }

    /**
     * @notice Withdraw money from the fund.
     * @param _amount the amount to withdraw from the fund.
     */
    //slither-disable-next-line naming-convention
    function withdraw(uint256 _amount) external payable {
        require(_amount <= addressToAmountFunded[msg.sender], "You can't withdraw more than what you deposited");
        addressToAmountFunded[msg.sender] -= _amount;
        totalFunds -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    /**
     * @notice Get the list of users who have funded the smart contract.
     * @return _ the list of funders
     */
    function getFunders() external view returns (address[] memory) {
        return funders;
    }

    /**
     * @notice Get the amount deposited by a user.
     * @param _addr address
     * @return _ amount deposited by a user
     *
     */
    //slither-disable-next-line naming-convention
    function getAddressToAmountFunded(address _addr) external view returns (uint256) {
        return addressToAmountFunded[_addr];
    }

    /*
     * @notice Get the total amount funded to this smart contract.
     * @return _ the amount of the total funds
     */
    function getTotalFunds() external view returns (uint256) {
        return totalFunds;
    }
}