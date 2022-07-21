// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Strings.sol";

contract NFT is ERC1155, Ownable {
    using Strings for uint256;

    string name;
    string symbol;

    string baseURI;
    string notRevealedUri;
    string public baseExtension = ".json";
    bool public paused;

    uint256 public cost = 0.05 ether;
    uint256 public totalPaid;

    uint256 private tokenIds;

    mapping(address => uint256[]) adrToIds;

    mapping(uint256 => Item) private items;

    mapping(address => bool) blacklist;
    mapping(address => wl) whitelist;

    uint256 public usersWhitelisted;

    mapping(address => lv) private updateLV;

    struct lv {
        string newLV;
        bool isUpdated;
    }

    struct wl {
        uint256 amount;
        uint256 transferFee;
        uint256 cost;
    }

    mapping(address => uint256) public amountsNFT;
    /*mapping(address => uint256[]) public idOfUser;*/

    mapping(uint256 => Admin) idToAdmin;
    mapping(address => uint256) adrToId;
    uint256 public adminAmount;

    struct Admin {
        uint256 id;
        address user;
        bool isAdmin;
    }

    bool public revealed;

    uint256 public nftAmountPerUser;
    uint256 public transferFee = 0.001 ether;

    uint256 public maxAmount = 13;
    uint256 public currentAmount;

    struct Item {
        uint256 id;
        address creator;
        uint256 quantity;
        address holder;
    }

    constructor(
        uint256 cost_,
        uint256 transferFee_,
        string memory uri_,
        string memory notRevealedUri_,
        uint256 nftAmountPerUser_,
        //bool revealDefault_,
        //uint256 maxAmount_,
        string memory name_,
        string memory symbol_
    ) ERC1155(uri_) {
        cost = cost_;
        transferFee = transferFee_;
        notRevealedUri = notRevealedUri_;
        baseURI = uri_;
        paused = true;
        nftAmountPerUser = nftAmountPerUser_;
        //revealed = revealDefault_;
        //maxAmount = maxAmount_;
        name = name_;
        symbol = symbol_;
    }

    function mint(address to, uint256 amount) external payable {
        require(!paused, "mint is paused");

        require(blacklist[msg.sender] == false, "you are in blacklist");
        require(currentAmount + amount <= maxAmount);
        if (whitelist[msg.sender].amount > 0) {
            require(
                msg.value >= whitelist[msg.sender].cost * amount,
                "Insufficient funds"
            );
            require(
                amountsNFT[msg.sender] + amount <= whitelist[msg.sender].amount,
                "nft collection amount is exceeded"
            );
        } else {
            require(msg.value >= cost * amount, "Insufficient funds");
            require(
                amountsNFT[msg.sender] + amount <= nftAmountPerUser,
                "nft collection amount is exceeded"
            );
        }

        for (uint256 i; i < amount; i++) {
            _mint(to, tokenIds, 1, "");
            currentAmount++;
            if (!isInArray(adrToIds[msg.sender], tokenIds)) {
                adrToIds[msg.sender].push(tokenIds);
            }

            items[tokenIds] = Item(tokenIds, msg.sender, 1, msg.sender);

            amountsNFT[msg.sender] += 1;
            //idOfUser[msg.sender].push(tokenIds);

            tokenIds++;
        }

        totalPaid += amount * cost;
    }

    function revealNFTs() external onlyOwner {
        revealed = !revealed;
    }

    function nameCollection() external view returns (string memory) {
        return name;
    }

    function symbolCollection() external view returns (string memory) {
        return symbol;
    }

    function setNameCollection(string memory name_) external onlyOwner {
        name = name_;
    }

    function changePauseStatus() external onlyOwner {
        paused = !paused;
    }

    function changeMaxAmount(uint256 newMaxAMount) external onlyOwner {
        require(newMaxAMount >= currentAmount);
        maxAmount = newMaxAMount;
    }

    function changeTransferFee(uint256 newTransferFee) external onlyOwner {
        transferFee = newTransferFee;
    }

    function changeNftAmountPerUser(uint256 newAmount) external onlyOwner {
        nftAmountPerUser = newAmount;
    }

    function checkUserIds() external view returns (uint256[] memory) {
        return adrToIds[msg.sender];
    }

    /*function checkItems() external view returns (Item memory){
        return(items[msg.sender]);
    }*/

    /*function totalSupply() external view returns (uint256) {
        return tokenIds;
    }*/

    function checkUserAmount() external view returns (uint256) {
        return amountsNFT[msg.sender];
    }

    function _ownerOf(uint256 tokenId) internal view returns (bool) {
        return balanceOf(msg.sender, tokenId) != 0;
    }

    /*function checkCostNft() external view returns (uint256) {
        return cost;
    }*/

    function checkTransferFeetNft() external view returns (uint256) {
        return transferFee;
    }

    function isInArray(uint256[] memory Ids, uint256 id)
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < Ids.length; i++) {
            if (Ids[i] == id) {
                return true;
            }
        }
        return false;
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId <= tokenIds);
        if (revealed == false) {
            return notRevealedUri;
        }

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        if (updateLV[items[tokenId].holder].isUpdated) {
            return updateLV[items[tokenId].holder].newLV;
        }
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }

    function changeMeta(address user, string memory newMeta)
        external
        onlyOwner
    {
        updateLV[user].newLV = newMeta;
        updateLV[user].isUpdated = true;
    }

    function batchTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable {
        if (whitelist[msg.sender].amount > 0) {
            require(
                msg.value >= whitelist[msg.sender].transferFee * ids.length,
                "Insufficient funds"
            );
        } else {
            require(msg.value >= transferFee, "Insufficient funds");
        }
        //require(msg.value >= transferFee, "Insufficient funds");
        _safeBatchTransferFrom(from, to, ids, amounts, "");
        //adrToIds[msg.sender]
        for (uint256 i; i < adrToIds[msg.sender].length; i++) {
            for (uint256 j; j < ids.length; j++) {
                if (adrToIds[msg.sender][i] == ids[j]) {
                    remove(i);
                }
            }
        }
    }

    function transfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external payable {
        if (whitelist[msg.sender].amount > 0) {
            require(
                msg.value >= whitelist[msg.sender].transferFee,
                "Insufficient funds"
            );
        } else {
            require(msg.value >= transferFee, "Insufficient funds");
        }
        //require(msg.value >= transferFee, "Insufficient funds");
        _safeTransferFrom(from, to, id, amount, "");
        items[id].holder = to;
        totalPaid += transferFee;
        for (uint256 i; i < adrToIds[msg.sender].length; i++) {
            if (adrToIds[msg.sender][i] == id) {
                remove(i);
            }
        }
    }

    function remove(uint256 index) internal returns (uint256[] memory) {
        //if (index >= adrToIds[msg.sender].length) return ;

        for (uint256 i = index; i < adrToIds[msg.sender].length - 1; i++) {
            adrToIds[msg.sender][i] = adrToIds[msg.sender][i + 1];
        }
        delete adrToIds[msg.sender][adrToIds[msg.sender].length - 1];
        adrToIds[msg.sender].pop();
        return adrToIds[msg.sender];
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {}

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function addToWhitelist(
        address user_,
        uint256 amount_,
        uint256 transferFee_,
        uint256 cost_
    ) external {
        require(
            msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin
        );
        require(blacklist[msg.sender] == false);
        usersWhitelisted++;
        whitelist[user_].amount = amount_;
        whitelist[user_].transferFee = transferFee_;
        whitelist[user_].cost = cost_;
    }

    function deleteFromWhitelist(address user) external {
        require(
            msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin
        );
        require(blacklist[msg.sender] == false);
        whitelist[user].amount = 0;
        whitelist[user].transferFee = 0;
        whitelist[user].cost = 0;
        usersWhitelisted--;
    }

    function addToBlacklist(address user) external {
        require(
            msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin
        );
        require(blacklist[msg.sender] == false);
        blacklist[user] = true;
    }

    function deleteFromBlacklist(address user) external {
        require(
            msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin
        );
        require(blacklist[msg.sender] == false);
        blacklist[user] = false;
    }

    function addAdmin(address admin) external onlyOwner {
        require(idToAdmin[adminAmount].isAdmin != true, "Already admin");
        adminAmount++;
        idToAdmin[adminAmount] = Admin(adminAmount, admin, true);
        adrToId[admin] = adminAmount;
    }

    function showAdmins() external view returns (address[] memory) {
        address[] memory admins;
        for (uint256 i; i < adminAmount; i++) {
            admins[i] = idToAdmin[i].user;
        }
        return (admins);
    }

    function deleteAdmin(uint256 adminId) external onlyOwner {
        idToAdmin[adminId].isAdmin = false;
    }

    function showItems(uint256 number) external view returns (Item memory) {
        require(items[number].id <= tokenIds);
        return items[number];
    }

    /*function checkUserIds() external view returns (uint256[] memory) {
        return idOfUser[msg.sender];
    }*/

    function isUserInBlacklist(address user) external view returns (bool) {
        require(
            msg.sender == owner() ||
                msg.sender == user ||
                idToAdmin[adrToId[msg.sender]].isAdmin
        );

        return blacklist[user];
    }

    //function changeParametersWhitelist(address user, )

    function isUserInWhitelist(address user)
        external
        view
        returns (
            uint256 amountOf,
            uint256 feeForTransfer,
            uint256 costOfMint
        )
    {
        require(
            msg.sender == owner() ||
                msg.sender == user ||
                idToAdmin[adrToId[msg.sender]].isAdmin
        );

        if (whitelist[user].amount == 0) {
            require(whitelist[user].amount != 0, "User is not whilelisted");
            return (0, 0, 0);
        } else {
            return (
                whitelist[user].amount,
                whitelist[user].transferFee,
                whitelist[user].cost
            );
        }
    }

    function availableNFTs()
        external
        view
        returns (
            uint256 amount,
            uint256 feeForTransfer,
            uint256 costForMint
        )
    {
        if (whitelist[msg.sender].amount > 0) {
            return (
                whitelist[msg.sender].amount - amountsNFT[msg.sender],
                whitelist[msg.sender].transferFee,
                whitelist[msg.sender].cost
            );
        } else {
            return (
                nftAmountPerUser - amountsNFT[msg.sender],
                transferFee,
                cost
            );
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}