// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./IDistributor.sol";

contract DistributorAggregator {
    // Withdrawal
    function withdraw(address[] calldata distributorList) external {
        for(uint16 i=0; i < distributorList.length; i++) {
            IDistributor distributor = IDistributor(distributorList[i]);
            distributor.computeCumulativeShare(msg.sender);
            uint40 share = distributor.cumulativeShareOf(msg.sender);
            if (share > 0) {
                distributor.withdraw();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
interface IDistributor {
  function addIncome ( uint40 amount ) external;
  function computeCumulativeShare ( address tokenHolder ) external;
  function cumulativeShareOf ( address tokenHolder ) external view returns ( uint40 );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function transferOwnership ( address newOwner ) external;
  function transferToOwner ( uint256 amount ) external;
  function withdraw (  ) external;
}