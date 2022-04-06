//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RebaseWL {
    uint256 tier1WhitelistCount;
    uint256 tier2WhitelistCount;
    uint256 tier3WhitelistCount;

    uint256 tier1WhitelistMinAllocation;
    uint256 tier2WhitelistMinAllocation;
    uint256 tier3WhitelistMinAllocation;

    uint256 tier1WhitelistAllocation;
    uint256 tier2WhitelistAllocation;
    uint256 tier3WhitelistAllocation;

    uint256 totalFund;
    address owner;

    address[] addressList;

    mapping(address => bool) tier1WhitelistAddresses;
    mapping(address => bool) tier2WhitelistAddresses;
    mapping(address => bool) tier3WhitelistAddresses;
    mapping(address => uint256) currentPayments;

    constructor() {
        owner = msg.sender;

        tier1WhitelistCount = 0;
        tier2WhitelistCount = 0;
        tier3WhitelistCount = 0;

        tier1WhitelistMinAllocation = 1500000000000000000;
        tier2WhitelistMinAllocation = 3000000000000000000;
        tier3WhitelistMinAllocation = 5000000000000000000;

        tier1WhitelistAllocation = 5000000000000000000;
        tier2WhitelistAllocation = 8000000000000000000;
        tier3WhitelistAllocation = 12000000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setTier1WhitelistAllocation(uint256 _tier1WhitelistAllocation)
        external
        onlyOwner
    {
        tier1WhitelistAllocation = _tier1WhitelistAllocation;
    }

    function setTier2WhitelistAllocation(uint256 _tier2WhitelistAllocation)
        external
        onlyOwner
    {
        tier2WhitelistAllocation = _tier2WhitelistAllocation;
    }

    function setTier3WhitelistAllocation(uint256 _tier3WhitelistAllocation)
        external
        onlyOwner
    {
        tier3WhitelistAllocation = _tier3WhitelistAllocation;
    }

    function getTier1WhitelistAllocation() public view returns (uint256) {
        return tier1WhitelistAllocation;
    }

    function getTier2WhitelistAllocation() public view returns (uint256) {
        return tier2WhitelistAllocation;
    }

    function getTier3WhitelistAllocation() public view returns (uint256) {
        return tier3WhitelistAllocation;
    }

    function getAddressCurrentPayments(address _address)
        public
        view
        returns (uint256)
    {
        return currentPayments[_address];
    }

    function payWL() public payable {
        require(
            tier1WhitelistAddresses[msg.sender] ||
                tier2WhitelistAddresses[msg.sender] ||
                tier3WhitelistAddresses[msg.sender],
            "User is not whitelisted"
        );
        if (
            tier1WhitelistAddresses[msg.sender] &&
            tier2WhitelistAddresses[msg.sender] &&
            tier3WhitelistAddresses[msg.sender]
        ) {
            require(
                msg.value + currentPayments[msg.sender] >=
                    tier1WhitelistMinAllocation +
                        tier2WhitelistMinAllocation +
                        tier3WhitelistMinAllocation,
                "Payment above minimum allocation"
            );
            require(
                msg.value + currentPayments[msg.sender] <=
                    tier1WhitelistAllocation +
                        tier2WhitelistAllocation +
                        tier3WhitelistAllocation,
                "Payment above maximum allocation"
            );
        } else if (
            tier1WhitelistAddresses[msg.sender] &&
            tier2WhitelistAddresses[msg.sender]
        ) {
            require(
                msg.value + currentPayments[msg.sender] >=
                    tier1WhitelistMinAllocation + tier2WhitelistMinAllocation,
                "Payment above minimum allocation"
            );
            require(
                msg.value + currentPayments[msg.sender] <=
                    tier1WhitelistAllocation + tier2WhitelistAllocation,
                "Payment above maximum allocation"
            );
        } else if (tier1WhitelistAddresses[msg.sender]) {
            require(
                msg.value + currentPayments[msg.sender] >=
                    tier1WhitelistMinAllocation,
                "Payment above minimum allocation"
            );
            require(
                msg.value + currentPayments[msg.sender] <=
                    tier1WhitelistAllocation,
                "Payment above maximum allocation"
            );
        } else if (tier2WhitelistAddresses[msg.sender]) {
            require(
                msg.value + currentPayments[msg.sender] >=
                    tier2WhitelistMinAllocation,
                "Payment above minimum allocation"
            );
            require(
                msg.value + currentPayments[msg.sender] <=
                    tier2WhitelistAllocation,
                "Payment above maximum allocation"
            );
        } else if (tier3WhitelistAddresses[msg.sender]) {
            require(
                msg.value + currentPayments[msg.sender] >=
                    tier3WhitelistMinAllocation,
                "Payment above minimum allocation"
            );
            require(
                msg.value + currentPayments[msg.sender] <=
                    tier3WhitelistAllocation,
                "Payment above maximum allocation"
            );
        }
        currentPayments[msg.sender] += msg.value;
        totalFund += msg.value;
    }

    function addTier1WhitelistAddress(address _address) external onlyOwner {
        if (tier1WhitelistAddresses[_address] != true) {
            tier1WhitelistAddresses[_address] = true;
            tier1WhitelistCount++;
        }
    }

    function addTier2WhitelistAddress(address _address) external onlyOwner {
        if (tier2WhitelistAddresses[_address] != true) {
            tier2WhitelistAddresses[_address] = true;
            tier2WhitelistCount++;
        }
    }

    function addTier3WhitelistAddress(address _address) external onlyOwner {
        if (tier3WhitelistAddresses[_address] != true) {
            tier3WhitelistAddresses[_address] = true;
            tier3WhitelistCount++;
        }
    }

    function addMultipleTier1Addresses(address[] memory addTier1AddressList)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addTier1AddressList.length; i++) {
            if (tier1WhitelistAddresses[addTier1AddressList[i]] != true) {
                tier1WhitelistAddresses[addTier1AddressList[i]] = true;
                tier1WhitelistCount++;
            }
        }
    }

    function addMultipleTier2Addresses(address[] memory addTier2AddressList)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addTier2AddressList.length; i++) {
            if (tier2WhitelistAddresses[addTier2AddressList[i]] != true) {
                tier2WhitelistAddresses[addTier2AddressList[i]] = true;
                tier2WhitelistCount++;
            }
        }
    }

    function addMultipleTier3Addresses(address[] memory addTier3AddressList)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addTier3AddressList.length; i++) {
            if (tier3WhitelistAddresses[addTier3AddressList[i]] != true) {
                tier3WhitelistAddresses[addTier3AddressList[i]] = true;
                tier3WhitelistCount++;
            }
        }
    }

    function removeTier1WhitelistAddress(address _address) external onlyOwner {
        tier1WhitelistAddresses[_address] = false;
        tier1WhitelistCount--;
    }

    function removeTier2WhitelistAddress(address _address) external onlyOwner {
        tier2WhitelistAddresses[_address] = false;
        tier2WhitelistCount--;
    }

    function removeTier3WhitelistAddress(address _address) external onlyOwner {
        tier3WhitelistAddresses[_address] = false;
        tier3WhitelistCount--;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function IsTier1Whitelisted(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        bool userIsTier1Whitelisted = tier1WhitelistAddresses[
            _whitelistedAddress
        ];
        return userIsTier1Whitelisted;
    }

    function IsTier2Whitelisted(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        bool userIsTier2Whitelisted = tier2WhitelistAddresses[
            _whitelistedAddress
        ];
        return userIsTier2Whitelisted;
    }

    function IsTier3Whitelisted(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        bool userIsTier3Whitelisted = tier3WhitelistAddresses[
            _whitelistedAddress
        ];
        return userIsTier3Whitelisted;
    }

    function getCurrentBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalFund() public view returns (uint256) {
        return totalFund;
    }

    function getTier1WhitelistCount() public view returns (uint256) {
        return tier1WhitelistCount;
    }

    function getTier2WhitelistCount() public view returns (uint256) {
        return tier2WhitelistCount;
    }

    function getTier3WhitelistCount() public view returns (uint256) {
        return tier3WhitelistCount;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}