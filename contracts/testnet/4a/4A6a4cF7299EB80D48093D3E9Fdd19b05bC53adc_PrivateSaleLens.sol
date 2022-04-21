//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IPrivateSaleFactory.sol";
import "./interfaces/IPrivateSale.sol";

contract PrivateSaleLens {
    struct SaleData {
        uint96 id;
        address sale;
        string name;
        uint256 maxSupply;
        uint256 totalAmountTokenSold;
        uint256 minTokenAmount;
        uint256 ethPrice;
        bool isOver;
        uint256 userBalance;
        uint120 userEthAmount;
        uint128 userAmounTokenBought;
        uint8 userStatus;
    }
    IPrivateSaleFactory public factory;

    constructor(IPrivateSaleFactory _factory) {
        factory = _factory;
    }

    function getSaleData(uint256[] calldata ids, address user)
        external
        view
        returns (SaleData[] memory availableSale)
    {
        uint256 len = ids.length;
        availableSale = new SaleData[](len);

        for (uint256 i = 0; i < len; i++) {
            IPrivateSale privateSale = IPrivateSale(
                factory.privateSales(ids[i])
            );
            IPrivateSale.UserInfo memory userInfo = privateSale.userInfo(user);

            availableSale[i] = SaleData({
                id: uint96(ids[i]),
                sale: address(privateSale),
                name: privateSale.name(),
                maxSupply: privateSale.maxSupply(),
                totalAmountTokenSold: privateSale.totalAmountTokenSold(),
                minTokenAmount: privateSale.minTokenAmount(),
                ethPrice: privateSale.ethPrice(),
                isOver: privateSale.isOver(),
                userBalance: msg.sender.balance,
                userEthAmount: userInfo.ethAmount,
                userAmounTokenBought: userInfo.amounTokenBought,
                userStatus: userInfo.status
            });
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPrivateSaleFactory {
    function owner() external view returns (address);

    function receiverAddress() external view returns (address);

    function devAddress() external view returns (address);

    function devFee() external view returns (uint256);

    function implementation() external view returns (address);

    function getPrivateSale(string memory name) external view returns (address);

    function privateSales(uint256 index) external view returns (address);

    function lenPrivateSales() external view returns (uint256);

    function createPrivateSale(
        string calldata name,
        uint256 price,
        uint256 maxSupply,
        uint256 minTokenAmount
    ) external returns (address);

    function validateUsers(string calldata name, address[] calldata addresses)
        external;

    function seizeUsers(string calldata name, address[] calldata addresses)
        external;

    function claim(string calldata name) external;

    function endSale(string calldata name) external;

    function setImplemention(address implementation) external;

    function setReceiverAddress(address receiver) external;

    function setDevAddress(address dev) external;

    function setDevFee(uint256 devFee) external;

    function emergencyWithdraw(string calldata name) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPrivateSale {
    struct UserInfo {
        uint120 ethAmount;
        uint128 amounTokenBought;
        uint8 status;
    }

    function factory() external view returns (address);

    function name() external view returns (string memory);

    function maxSupply() external view returns (uint256);

    function totalAmountTokenSold() external view returns (uint256);

    function totalEth() external view returns (uint256);

    function minTokenAmount() external view returns (uint256);

    function ethPrice() external view returns (uint256);

    function claimableEthAmount() external view returns (uint256);

    function isOver() external view returns (bool);

    function userInfo(address user) external view returns (UserInfo memory);

    function initialize(
        string calldata name,
        uint256 ethPrice,
        uint256 maxSupply,
        uint256 minTokenAmount
    ) external;

    function participate(uint256 maxTokenAmount, bytes memory signature)
        external
        payable;

    function validateUsers(address[] calldata addresses) external;

    function claim() external;

    function endSale() external;

    function seizeUsers(address[] calldata addresses) external;

    function emergencyWithdraw() external;
}