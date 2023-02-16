// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./interfaces/ICoupons.sol";
//import "hardhat/console.sol";

/* Errors */
error Coupons__CouponNotFound();
error Coupons__TransferToSafeFailed();

contract Coupons is ICoupons {
    string private constant VERSION = "0.6.0";

    struct Coupon {
        string key;
        bytes32 keyHash;
        uint8 minPct;
        uint8 maxPct;
        uint16 multiplierPct;
    }

    struct CouponRule {
        uint8 minPct;
        uint8 maxPct;
        uint256 couponFee;
        uint16 multiplierPct;
    }

    struct CouponTicket {
        address userAddress;
        uint256 couponFee;
        uint16 multiplierPct;
        bool paidOut;
    }

    address private s_owner;
    address payable private s_safeAddress;

    // Coupons table: contractAddress -> coupon
    mapping(address => Coupon[]) private s_coupons;
    // Coupons rule:  contractAddress -> couponRule
    mapping(address => CouponRule) private s_couponRule;
    // Coupons store: contractAddress -> raffleId -> partnerId -> couponTicket
    mapping(address => mapping(uint32 => mapping(string => CouponTicket))) private s_couponTickets;

    event ChangeCoupons(address contractAddress, bytes32 keyHash);

    constructor(address payable safe) {
        s_owner = msg.sender;
        s_safeAddress = safe;
    }

    /** Coupons CRUD **/
    function getCoupon(
        address contractAddress,
        bytes32 couponHash
    ) public view override returns (uint8 minPct, uint8 maxPct, uint16 multiplierPct) {
        for (uint i=0; i < s_coupons[contractAddress].length; i++) {
            if (s_coupons[contractAddress][i].keyHash == couponHash) {
                return (
                    minPct=s_coupons[contractAddress][i].minPct,
                    maxPct=s_coupons[contractAddress][i].maxPct,
                    multiplierPct=s_coupons[contractAddress][i].multiplierPct
                );
            }
        }
        revert Coupons__CouponNotFound();
    }

    function getCouponHashes(address contractAddress) public view returns (bytes32[] memory result) {
        result = new bytes32[](s_coupons[contractAddress].length);
        for (uint i=0; i < s_coupons[contractAddress].length; i++) {
            result[i] = s_coupons[contractAddress][i].keyHash;
        }
    }

    function getCoupons(address contractAddress) public view returns (Coupon[] memory) {
        return s_coupons[contractAddress];
    }

    function getCouponInfo(address contractAddress, bytes32 keyHash) public view returns (Coupon memory) {
        if (s_coupons[contractAddress].length > 0) {
            for (uint i=0; i < s_coupons[contractAddress].length; i++) {
                if (s_coupons[contractAddress][i].keyHash == keyHash) {
                    return s_coupons[contractAddress][i];
                }
            }
        }
        revert('Coupon not found');
    }

    function setCoupon(address contractAddress, Coupon memory coupon) public onlyOwner{
        coupon.keyHash = keccak256(abi.encodePacked(coupon.key));
        bool found = false;
        uint id = 0;
        if (s_coupons[contractAddress].length > 0) {
            for (uint i=0; i < s_coupons[contractAddress].length; i++) {
                if (s_coupons[contractAddress][i].keyHash == coupon.keyHash) {
                    found = true;
                    id = i;
                    break;
                }
            }
        }
        if (found) {
            s_coupons[contractAddress][id] = coupon;
        } else {
            s_coupons[contractAddress].push(coupon);
        }
        emit ChangeCoupons(contractAddress, coupon.keyHash);
    }

    function deleteCoupon(address contractAddress, bytes32 keyHash) public onlyOwner {
        if (s_coupons[contractAddress].length > 0) {
            bool found = false;
            uint id;
            for (uint i = 0; i < s_coupons[contractAddress].length; i++) {
                if (s_coupons[contractAddress][i].keyHash == keyHash) {
                    id = i;
                    found = true;
                    block;
                }
            }
            if (found) {
                for (uint i = id; i < s_coupons[contractAddress].length - 1; i++){
                    s_coupons[contractAddress][i] = s_coupons[contractAddress][i + 1];
                }
                s_coupons[contractAddress].pop();
            }
        }
        emit ChangeCoupons(contractAddress, keyHash);
    }

//    function withdraw() public onlyOwner {
//        (bool safeTxSuccess, ) = s_safeAddress.call{value: address(this).balance}("");
//        if (!safeTxSuccess) {
//            revert Coupons__TransferToSafeFailed();
//        }
//    }

    /** Getters **/
    function getVersion() public pure returns (string memory) {
        return VERSION;
    }

    function getKeyHash(string memory key) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(key));
    }

    function getSafeAddress() public view returns (address payable) {
        return s_safeAddress;
    }

    /** Setters **/
    function setSafeAddress(address payable safeAddress) public onlyOwner {
        s_safeAddress = safeAddress;
    }



    function changeOwner(address owner) public onlyOwner {
        s_owner = owner;
    }

    /** Modifiers **/
    modifier onlyOwner() {
        require(msg.sender == s_owner, 'Only owner allowed');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICoupons{
    function getCoupon(
        address contractAddress,
        bytes32 couponHash
    ) external view returns (uint8 minPct, uint8 maxPct, uint16 multiplierPct);
}