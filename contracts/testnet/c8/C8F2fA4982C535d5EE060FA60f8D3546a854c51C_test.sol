pragma solidity ^0.8.4;

import "./thetap.sol";

contract test {
    //address payable addr = address(uint160(0xa260D54fD6FbF4eAaf52EB8887A879B9ef73B089));
    TheTap tapContract;

    function setTapContract(address payable _address) public {
        tapContract = TheTap(_address);
    }

    function getUser(address _address)
        public
        view
        returns (
            //Referral Info
            address upline,
            uint256 referrals,
            uint256 total_structure,
            //Long-term Referral Accounting
            uint256 direct_bonus,
            uint256 match_bonus,
            //Deposit Accounting
            uint256 deposits,
            uint256 deposit_time,
            //Payout and Roll Accounting
            uint256 payouts,
            uint256 rolls,
            //Upline Round Robin tracking
            uint256 ref_claim_pos,
            address entered_address
        )
    {
        return tapContract.users(_address);
    }
}