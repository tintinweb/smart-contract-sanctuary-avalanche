/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

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
contract MarketPlace { // ---> Transfering And Approving NFT Tokens Via MarketPlace <---

    error ExternalCallError(string message);

    address private immutable marketFeeTaker;

    // Byte Code Generator
    address private immutable erc721Gen;

    IERC20 private immutable ERC20; // USDC token contract

    struct SellOrderERC721 {
        address tokenContract;
        address orderOwner;
        address buyer;
        uint256 tokenId;
        uint256 totalPrice; // USDC Or Ether(wei)
        uint256 orderStartedAt;
        uint256 orderEndedAt;
        bool isEther;
        bool isCanceled;
        bool isEnded;
    }
    uint256 totalERC721SellOrderCount = 1;

    struct BidERC721 {
        uint256 totalPrice; // USDC Or Ether(wei) with fee
        uint256 tokenId;
        uint256 bidStartedAt;
        uint256 bidEndedAt;
        uint256 orderId;
        address nftContractAddr;
        address seller;
        address bidOwner;
        bool isEther;
        bool isCanceled;
        bool isEnded;
    }
    uint256 totalERC721BidCount = 1;

    event SellOrderERC721Created(address indexed creator, uint indexed orderId);
    event BidERC721Created(address indexed creator, uint indexed bidId);
    event ERC721ContractCreation(address indexed creator, string name, string symbol, string desc);

    // from orderId to order info (ERC721)
    mapping (uint256 => SellOrderERC721) private orderERC721;
    // from order owner to all his sell orders (ERC721)
    mapping (address => uint[]) private userERC721SellOrders;
    // from contract address to specific tokenids bids
    mapping (address => mapping (address => mapping (uint => uint[]))) private contractBids;
    // from user to is ERC721 contract created (ERC721)
    mapping (address => address) private userERC721Contract;
    // from bidId to bid info (ERC721)
    mapping (uint256 => BidERC721) private ERC721Bid;
    // from bidder to bid id (ERC721)
    mapping (address => uint[]) private ERC721BidderBids;
    // from user to his added contract accounts
    mapping (address => address[]) private userAddedContracts;
    // from contract address to validation
    mapping (address => bool) private allMarketContracts;
    
    constructor(
        address _usdcToken,
        address _feeTaker,
        address _erc721Gen
    ) {
        ERC20 = IERC20(_usdcToken);
        marketFeeTaker = _feeTaker;
        erc721Gen = _erc721Gen;
    }

    function bidERC7211Data(uint _bidId) external view returns(BidERC721 memory) {
        return ERC721Bid[_bidId];
    }

    function orderERC721Data(uint256 _orderId) external view returns(SellOrderERC721 memory) {
        require(_orderId != 0 && _orderId < totalERC721SellOrderCount && _orderId >= 1, "Invalid Order Id.");
        return orderERC721[_orderId];
    }

    function totalERC721OrdersCount() external view returns(uint256) {
        return totalERC721SellOrderCount - 1;
    }

    function createERC721SellOrder(address _contract, uint256 _tokenId, uint256 _price, bool _isEther) external {
        require(allMarketContracts[_contract] == true, "this address is not a valid contract address.");
        IERC721 nft = IERC721(_contract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not Token Owner.");
        require(_price != 0, "Invalid Order Price.");

        require(nft.isApprovedForAll(msg.sender, address(this)) == true || nft.getApproved(_tokenId) == address(this), "Allowance Needed.");

        try nft.transferFrom(msg.sender, address(this), _tokenId) {
            SellOrderERC721 memory order = SellOrderERC721({
                tokenContract: _contract,
                orderOwner: msg.sender,
                buyer: address(0),
                tokenId: _tokenId,
                totalPrice: _price,
                orderStartedAt: block.timestamp,
                orderEndedAt: 0,
                isEther: _isEther,
                isCanceled: false,
                isEnded: false
            });

            orderERC721[totalERC721SellOrderCount] = order;

            userERC721SellOrders[msg.sender].push(totalERC721SellOrderCount);

            totalERC721SellOrderCount += 1;

            emit SellOrderERC721Created(msg.sender, totalERC721SellOrderCount - 1);
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ExternalCallError({
                    message: "Error: This Contract Doesn't Implemented transferFrom Func. (ERC721)"
                });
            } else {
                revert ExternalCallError({
                    message: "Error: External Func Call Failed."
                });
            }
        }
    }

    function cancelERC721SellOrder(uint256 _orderId) external {
        SellOrderERC721 storage order = orderERC721[_orderId];
        require(order.orderOwner == msg.sender, "Not Order Owner.");
        require(order.isCanceled == false && order.isEnded == false, "Order Has Been Ended Befor!");

        IERC721 nft = IERC721(order.tokenContract);

        order.isCanceled = true;

        try nft.safeTransferFrom(address(this), order.orderOwner, order.tokenId) {
            // 
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ExternalCallError({
                    message: "Error: This Contract Doesn't Implemented safeTransferFrom Func. (ERC721)"
                });
            } else {
                revert ExternalCallError({
                    message: "Error: External Func Call Failed."
                });
            }
        }
    }
 
    function editERC721SellOrderPrice(uint256 _orderId, uint256 _newPrice) external {
        SellOrderERC721 storage order = orderERC721[_orderId];
        require(order.orderOwner == msg.sender, "Not Order Owner.");
        require(order.isCanceled == false && order.isEnded == false, "Order Has Been Ended Befor!");

        order.totalPrice = _newPrice;
    }

    function createERC721Bid(uint256 _bidPrice, uint256 _orderId, bool _isEther) external payable {
        SellOrderERC721 memory order = orderERC721[_orderId];
        require(_orderId > 0 && _orderId < totalERC721SellOrderCount && order.orderOwner != address(0) && _bidPrice != 0, "Invalid Bid Info.");
        require(order.isCanceled == false && order.isEnded == false, "Invlaid Order Id.");
        require(order.orderOwner != msg.sender , "You Cannot Set A Bid For Your Own NFT!");
    
        if (_isEther) {
            require(msg.value == _bidPrice, "Insufficient Ether Amount.");

            BidERC721 memory bid = BidERC721({
                totalPrice: _bidPrice,
                tokenId: order.tokenId,
                bidStartedAt: block.timestamp,
                bidEndedAt: 0,
                orderId: _orderId,
                nftContractAddr: order.tokenContract,
                seller: address(0),
                bidOwner: msg.sender,
                isEther: _isEther,
                isCanceled: false,
                isEnded: false
            });

            ERC721Bid[totalERC721BidCount] = bid;

            ERC721BidderBids[msg.sender].push(totalERC721BidCount);

            contractBids[order.tokenContract][order.orderOwner][order.tokenId].push(totalERC721BidCount);

            totalERC721BidCount += 1;

            emit BidERC721Created({
                creator: msg.sender,
                bidId: totalERC721BidCount - 1
            });
        } else {
            require(ERC20.allowance(msg.sender, address(this)) == (_bidPrice * (10**ERC20.decimals())), "Invalid Allowance.");
            
            try ERC20.transferFrom(msg.sender, address(this), (_bidPrice * (10**ERC20.decimals()))) {
                BidERC721 memory bid = BidERC721({
                    totalPrice: _bidPrice,
                    tokenId: order.tokenId,
                    bidStartedAt: block.timestamp,
                    bidEndedAt: 0,
                    orderId: _orderId,
                    nftContractAddr: order.tokenContract,
                    seller: address(0),
                    bidOwner: msg.sender,
                    isEther: _isEther,
                    isCanceled: false,
                    isEnded: false
                });

                ERC721Bid[totalERC721BidCount] = bid;

                ERC721BidderBids[msg.sender].push(totalERC721BidCount);

                contractBids[order.tokenContract][order.orderOwner][order.tokenId].push(totalERC721BidCount);

                totalERC721BidCount += 1;

                emit BidERC721Created({
                    creator: msg.sender,
                    bidId: totalERC721BidCount - 1
                });
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ExternalCallError({
                        message: "Error: This Contract Doesn't Implemented transferFrom Func. (ERC20)"
                    });
                } else {
                    revert ExternalCallError({
                        message: "Error: External Func Call Failed."
                    });
                }
            }
        }
    }   

    function cancelERC721Bid(uint _bidId) external {
        BidERC721 storage bid = ERC721Bid[_bidId];
        require(bid.bidOwner == msg.sender, "not bid owner.");
        require(bid.isCanceled == false && bid.isEnded == false, "Cannot Cancel Bid!");

        if (bid.isEther) {
            bid.isCanceled = true;

            (bool result,) = msg.sender.call{value: bid.totalPrice}("");
            require(result == true, "Something Went Wrong.");
        } else {
            bid.isCanceled = true;

            try ERC20.transfer(msg.sender, (bid.totalPrice * (10**ERC20.decimals()))) returns(bool result) {
                require(result == true, "Something Went Wrong.");

            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ExternalCallError({
                        message: "Error: This Contract Doesn't Implemented transfer Func. (ERC20)"
                    });
                } else {
                    revert ExternalCallError({
                        message: "Error: External Func Call Failed."
                    });
                }
            }
        }
    }

    function acceptERC721Bid(uint _bidId, uint _orderId) external {
        BidERC721 storage bid = ERC721Bid[_bidId];
        require(_bidId > 0 && _bidId < totalERC721BidCount && bid.bidOwner != address(0), "invalid bid id.");
        require(bid.isCanceled == false && bid.isEnded == false, "Cannot Accept Bid!");
        SellOrderERC721 storage order = orderERC721[_orderId];
        require(order.orderOwner == msg.sender, "Invalid Order Owner.");
        require(order.isCanceled == false && order.isEnded == false, "Cannot Interact With This Order.");

        bid.isEnded = true;
        bid.bidEndedAt = block.timestamp;
        bid.seller = msg.sender;

        order.isEnded = true;
        order.orderEndedAt = block.timestamp;
        order.buyer = bid.bidOwner;

        uint totalFund = bid.totalPrice;
        uint marketFee = totalFund / 50; // 2%
        uint sellerFund = totalFund - marketFee;

        IERC721 nft = IERC721(bid.nftContractAddr);

        if (bid.isEther) {
            try nft.transferFrom(address(this), bid.bidOwner, bid.tokenId) {
                payable(msg.sender).transfer(sellerFund);

                (bool result,) = marketFeeTaker.call{value: marketFee}("");
                require(result == true, "Something Went Wrong.");
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ExternalCallError({
                        message: "Error: This Contract Doesn't Implemented transferFrom Func. (ERC721)"
                    });
                } else {
                    revert ExternalCallError({
                        message: "Error: External Func Call Failed."
                    });
                }
            }
        } else {
            try nft.transferFrom(address(this), bid.bidOwner, bid.tokenId) {
                try ERC20.transfer(msg.sender, sellerFund * (10**ERC20.decimals())) returns(bool res) {
                    require(res == true, "Something Went Wrong.");

                    try ERC20.transfer(marketFeeTaker, marketFee * (10**ERC20.decimals())) returns(bool result) {
                        require(result == true, "Something Went Wrong.");
                    } catch (bytes memory reason) {
                        if (reason.length == 0) {
                            revert ExternalCallError({
                                message: "Error: This Contract Doesn't Implemented transfer Func. (ERC20)"
                            });
                        } else {
                            revert ExternalCallError({
                                message: "Error: External Func Call Failed."
                            });
                        }
                    }
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert ExternalCallError({
                            message: "Error: This Contract Doesn't Implemented transferFrom Func. (ERC721)"
                        });
                    } else {
                        revert ExternalCallError({
                            message: "Error: External Func Call Failed."
                        });
                    }
                }  
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ExternalCallError({
                        message: "Error: This Contract Doesn't Implemented transferFrom Func. (ERC721)"
                    });
                } else {
                    revert ExternalCallError({
                        message: "Error: External Func Call Failed."
                    });
                }
            }
        }
    }

    function addContractAddress(address _contract) external {
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

    function createERC721Contract(string memory _name, string memory _symbol, string memory _desc, address _proxyGen) external {
        require(userERC721Contract[msg.sender] == address(0), unicode"ERC721: Contract Already Created. 🤔");
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

        userERC721Contract[msg.sender] = contractAddr;
        allMarketContracts[contractAddr] = true;

        emit ERC721ContractCreation({
            creator: msg.sender,
            name: _name,
            symbol: _symbol,
            desc: _desc
        });
    }

    function userERC721Address(address _addr) external view returns(address contractAddr) {
        contractAddr = userERC721Contract[_addr];
    }

    function userContracts(address _user) external view returns(address[] memory) {
        return userAddedContracts[_user];
    }

    function userERC721Orders(address _user) external view returns(uint[] memory) {
        return userERC721SellOrders[_user];
    }

    function userERC721OwnedContract(address _user) external view returns(address) {
        return userERC721Contract[_user];
    }

    function userERC721Bids(address _user) external view returns(uint[] memory) {
        return ERC721BidderBids[_user];
    }

    function userContractBids(
        address _contract,
        address _owner,
        uint _tokenId
    ) external view returns(uint[] memory) {
        return contractBids[_contract][_owner][_tokenId];
    }

}