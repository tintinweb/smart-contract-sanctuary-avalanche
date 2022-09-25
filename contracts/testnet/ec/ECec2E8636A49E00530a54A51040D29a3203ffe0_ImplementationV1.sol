/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns(uint8);
}
interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface IERC721ByteCodeGenerator {
    function generate(
        string memory _name,
        string memory _symbol,
        string memory _desc,
        address owner,
        address _proxyGen
    ) external pure returns(bytes memory);
}
/************************************************************************************************/
/****************************************| MarketPlace |*****************************************/
/************************************************************************************************/
contract ImplementationV1 { // ---> Transfering And Approving NFT Tokens Via MarketPlace <---

    error ExternalCallError(string message);

    address public marketplace;

    address public owner;

    address private marketFeeTaker;

    // Byte Code Generator
    address private erc721Gen;

    struct SellOrder {
        address nftContract;
        address orderOwner;
        address token;
        address buyer;
        uint256 nftId;
        uint256 totalPrice;
        uint256 orderStartedAt;
        uint256 orderEndedAt;
        bool isCanceled;
        bool isEnded;
    }
    uint256 totalSellOrderCount = 1;

    struct Bid {
        uint256 totalPrice;
        uint256 nftId;
        uint256 bidStartedAt;
        uint256 bidEndedAt;
        uint256 orderId;
        address nftContractAddr;
        address seller;
        address bidOwner;
        address token;
        bool isCanceled;
        bool isEnded;
    }
    uint256 totalBidCount = 1;

    event SellOrderCreated(address indexed creator,uint indexed orderId,address token);
    event BidCreated(address indexed creator,uint indexed bidId,address token);
    event ContractCreation(address indexed creator,string name,string symbol);

    // from orderId to order info (ERC721)
    mapping (uint256 => SellOrder) private order;
    // from order owner to all his sell orders (ERC721)
    mapping (address => uint[]) private userSellOrders;
    // from contract address to specific tokenids bids
    mapping (address => mapping (address => mapping (uint => uint[]))) private contractBids;
    // from user to is ERC721 contract created (ERC721)
    mapping (address => address) private userContract;
    // from bidId to bid info (ERC721)
    mapping (uint256 => Bid) private bid;
    // from bidder to bid id (ERC721)
    mapping (address => uint[]) private bidderBids;
    // from user to his added contract accounts
    mapping (address => address[]) private userAddedContracts;
    // from contract address to validation
    mapping (address => bool) private allMarketContracts;
    // from token too validation status
    mapping (address => bool) private allTokens;
    address[] private tokens;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
 
    function createSellOrder(
        address _contract,
        uint256 _tokenId,
        uint256 _price,
        address _token
    ) external {
        require(allTokens[_token] == true, "Invalid token address");
        require(allMarketContracts[_contract] == true, "This address is not a valid contract address.");
        IERC721 nft = IERC721(_contract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not Token Owner.");
        require(_price != 0, "Invalid Order Price.");

        try nft.transferFrom(msg.sender, address(this), _tokenId) {
            SellOrder memory _order = SellOrder({
                nftContract: _contract,
                orderOwner: msg.sender,
                buyer: address(0),
                nftId: _tokenId,
                totalPrice: _price,
                orderStartedAt: block.timestamp,
                orderEndedAt: 0,
                token: _token,
                isCanceled: false,
                isEnded: false
            });

            order[totalSellOrderCount] = _order;

            userSellOrders[msg.sender].push(totalSellOrderCount);

            totalSellOrderCount += 1;

            emit SellOrderCreated({
                creator: msg.sender,
                orderId: totalSellOrderCount - 1,
                token: _token
            });
        } catch {
            revert ExternalCallError({
                message: "External call failed. (1)"
            });
        }
    }

    function cancelSellOrder(uint256 _orderId) external {
        SellOrder storage _order = order[_orderId];
        require(_order.orderOwner == msg.sender, "Not Order Owner.");
        require(_order.isCanceled == false && _order.isEnded == false, "Order Has Been Ended Befor!");

        IERC721 nft = IERC721(_order.nftContract);

        _order.isCanceled = true;
        _order.orderEndedAt = block.timestamp;

        try nft.safeTransferFrom(address(this), _order.orderOwner, _order.nftId) {
            // 
        } catch {
            revert ExternalCallError({
                message: "External call failed. (2)"
            });
        }
    }
 
    function editSellOrderPrice(
        uint256 _orderId,
        uint256 _newPrice
    ) external {
        SellOrder storage _order = order[_orderId];
        require(_order.orderOwner == msg.sender, "Not Order Owner.");
        require(_order.isCanceled == false && _order.isEnded == false, "Order Has Been Ended Before!");

        _order.totalPrice = _newPrice;
    }

    function createBid(
        uint256 _bidPrice,
        uint256 _orderId,
        address _token
    ) external {
        require(allTokens[_token] == true, "Invalid token address");
        SellOrder memory _order = order[_orderId];
        require(_orderId > 0 && _orderId < totalSellOrderCount && _order.orderOwner != address(0) && _bidPrice != 0, "Invalid Bid Info.");
        require(_order.isCanceled == false && _order.isEnded == false, "Invlaid Order Id.");
        require(_order.orderOwner != msg.sender , "You Cannot Set A Bid For Your Own NFT!");

        IERC20 token = IERC20(_token);

        try token.transferFrom(msg.sender, address(this), (_bidPrice * (10**token.decimals()))) {
            Bid memory _bid = Bid({
                totalPrice: _bidPrice,
                nftId: _order.nftId,
                bidStartedAt: block.timestamp,
                bidEndedAt: 0,
                orderId: _orderId,
                nftContractAddr: _order.nftContract,
                seller: address(0),
                bidOwner: msg.sender,
                token: _token,
                isCanceled: false,
                isEnded: false
            });

            bid[totalBidCount] = _bid;

            bidderBids[msg.sender].push(totalBidCount);

            contractBids[_order.nftContract][_order.orderOwner][_order.nftId].push(totalBidCount);

            totalBidCount += 1;

            emit BidCreated({
                creator: msg.sender,
                bidId: totalBidCount - 1,
                token: _token
            });
        } catch {
            revert ExternalCallError({
                message: "External call failed. (3)"
            });
        }
    }   

    function cancelERC721Bid(
        uint _bidId
    ) external {
        Bid storage _bid = bid[_bidId];
        require(_bid.bidOwner == msg.sender, "not bid owner.");
        require(_bid.isCanceled == false && _bid.isEnded == false, "Cannot Cancel Bid!");

        _bid.isCanceled = true;
        _bid.bidEndedAt = block.timestamp;

        IERC20 token = IERC20(_bid.token);

        try token.transfer(msg.sender, (_bid.totalPrice * (10**token.decimals()))) returns(bool result) {
            require(result == true, "Something Went Wrong.");
        } catch {
            revert ExternalCallError({
                message: "External call failed. (4)"
            });
        }

    }

    function acceptERC721Bid(
        uint _bidId,
        uint _orderId
    ) external {
        Bid storage _bid = bid[_bidId];
        require(_bidId > 0 && _bidId < totalBidCount && _bid.bidOwner != address(0), "invalid bid id.");
        require(_bid.isCanceled == false && _bid.isEnded == false, "Cannot Accept Bid!");
        SellOrder storage _order = order[_orderId];
        require(_order.orderOwner == msg.sender, "Invalid Order Owner.");
        require(_order.isCanceled == false && _order.isEnded == false, "Cannot Interact With This Order.");

        _bid.isEnded = true;
        _bid.bidEndedAt = block.timestamp;
        _bid.seller = msg.sender;

        _order.isEnded = true;
        _order.orderEndedAt = block.timestamp;
        _order.buyer = _bid.bidOwner;

        uint totalFund = _bid.totalPrice;
        uint marketFee = totalFund / 50; // 2%
        uint sellerFund = totalFund - marketFee;

        IERC721 nft = IERC721(_order.nftContract);
        IERC20 token = IERC20(_bid.token);

        try nft.transferFrom(address(this), _bid.bidOwner, _order.nftId) {
            try token.transfer(msg.sender, sellerFund * (10**token.decimals())) returns(bool res) {
                require(res == true, "Something Went Wrong.");
                
                try token.transfer(marketFeeTaker, marketFee * (10**token.decimals())) returns(bool result) {
                    require(result == true, "Something Went Wrong.");
                } catch {
                    revert ExternalCallError({
                        message: "External call failed. (6)"
                    });
                }
            } catch {
                revert ExternalCallError({
                    message: "External call failed. (7)"
                });
            }
        } catch {
            revert ExternalCallError({
                message: "External call failed. (8)"
            });
        }
        
    }

    function addContractAddress(
        address _contract
    ) external {
        require(allMarketContracts[_contract] == true, "this address is not a valid contract address.");

        address[] storage addrs = userAddedContracts[msg.sender];

        bool isExist;
        for (uint i; i < addrs.length; ++i) {
            if (_contract == addrs[i]) {
                isExist = true;
                break;
            }
        }
        require(isExist == false, "Contract Already Exists.");

        addrs.push(_contract);
    }

    function createContract(
        string memory _name,
        string memory _symbol,
        string memory _desc,
        address _proxyGen
    ) external {
        require(userContract[msg.sender] == address(0), unicode"ERC721: Contract Already Created. 🤔");
        require(
            bytes(_name).length > 0 &&
            bytes(_symbol).length > 0 &&
            bytes(_desc).length > 0,
            "invalid strings."
        );

        bytes memory byteCode = IERC721ByteCodeGenerator(erc721Gen).generate(_name, _symbol, _desc, msg.sender, _proxyGen);
        address contractAddr;
        assembly {
            contractAddr := create(callvalue(), add(byteCode, 0x20), mload(byteCode))
        }
        require(contractAddr != address(0), "Failed While Creating ERC721 Contract.");

        userContract[msg.sender] = contractAddr;
        allMarketContracts[contractAddr] = true;

        emit ContractCreation({
            creator: msg.sender,
            name: _name,
            symbol: _symbol
        });
    }

    function addToken(
        address _token
    ) external onlyOwner {
        require(allTokens[_token] == false, "Token already exists!");

        allTokens[_token] = true;
        tokens.push(_token);
    }

}