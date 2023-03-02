// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.5.0;


interface ERC20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    
    function totalSupply() external view  returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

pragma solidity ^0.5.0;

        /// @title ERC-721 Non-Fungible Token Standard
        /// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
        ///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
        interface ERC721 /* is ERC165 */ {
            
                        /// @dev This emits when ownership of any NFT changes by any mechanism.
            ///  This event emits when NFTs are created (`from` == 0) and destroyed
            ///  (`to` == 0). Exception: during contract creation, any number of NFTs
            ///  may be created and assigned without emitting Transfer. At the time of
            ///  any transfer, the approved address for that NFT (if any) is reset to none.
            event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

            /// @dev This emits when the approved address for an NFT is changed or
            ///  reaffirmed. The zero address indicates there is no approved address.
            ///  When a Transfer event emits, this also indicates that the approved
            ///  address for that NFT (if any) is reset to none.
            event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

            /// @dev This emits when an operator is enabled or disabled for an owner.
            ///  The operator can manage all NFTs of the owner.
            event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
            
            
            
            
            
                        /// @notice Count all NFTs assigned to an owner
            /// @dev NFTs assigned to the zero address are considered invalid, and this
            ///  function throws for queries about the zero address.
            /// @param _owner An address for whom to query the balance
            /// @return The number of NFTs owned by `_owner`, possibly zero
            function balanceOf(address _owner) external view returns (uint256);

            /// @notice Transfers the ownership of an NFT from one address to another address
            /// @dev Throws unless `msg.sender` is the current owner, an authorized
            ///  operator, or the approved address for this NFT. Throws if `_from` is
            ///  not the current owner. Throws if `_to` is the zero address. Throws if
            ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
            ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
            ///  `onERC721Received` on `_to` and throws if the return value is not
            ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
            /// @param _from The current owner of the NFT
            /// @param _to The new owner
            /// @param _tokenId The NFT to transfer
            /// @param data Additional data with no specified format, sent in call to `_to`
            function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

            /// @notice Transfers the ownership of an NFT from one address to another address
            /// @dev This works identically to the other function with an extra data parameter,
            ///  except this function just sets data to ""
            /// @param _from The current owner of the NFT
            /// @param _to The new owner
            /// @param _tokenId The NFT to transfer
            function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

            /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
            ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
            ///  THEY MAY BE PERMANENTLY LOST
            /// @dev Throws unless `msg.sender` is the current owner, an authorized
            ///  operator, or the approved address for this NFT. Throws if `_from` is
            ///  not the current owner. Throws if `_to` is the zero address. Throws if
            ///  `_tokenId` is not a valid NFT.
            /// @param _from The current owner of the NFT
            /// @param _to The new owner
            /// @param _tokenId The NFT to transfer
            function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

            /// @notice Set or reaffirm the approved address for an NFT
            /// @dev The zero address indicates there is no approved address.
            /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
            ///  operator of the current owner.
            /// @param _approved The new approved NFT controller
            /// @param _tokenId The NFT to approve
            function approve(address _approved, uint256 _tokenId) external payable;

            /// @notice Enable or disable approval for a third party ("operator") to manage
            ///  all of `msg.sender`'s assets.
            /// @dev Emits the ApprovalForAll event. The contract MUST allow
            ///  multiple operators per owner.
            /// @param _operator Address to add to the set of authorized operators.
            /// @param _approved True if the operator is approved, false to revoke approval
            function setApprovalForAll(address _operator, bool _approved) external;

            /// @notice Get the approved address for a single NFT
            /// @dev Throws if `_tokenId` is not a valid NFT
            /// @param _tokenId The NFT to find the approved address for
            /// @return The approved address for this NFT, or the zero address if there is none
            function getApproved(uint256 _tokenId) external view returns (address);

            /// @notice Query if an address is an authorized operator for another address
            /// @param _owner The address that owns the NFTs
            /// @param _operator The address that acts on behalf of the owner
            /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
            function isApprovedForAll(address _owner, address _operator) external view returns (bool);
            
                        /// @notice Find the owner of an NFT
            /// @dev NFTs assigned to zero address are considered invalid, and queries
            ///  about them do throw.
            /// @param _tokenId The identifier for an NFT
            /// @return The address of the owner of the NFT
            function ownerOf(uint256 _tokenId) external view returns (address);
        }

        interface ERC165 {
            /// @notice Query if a contract implements an interface
            /// @param interfaceID The interface identifier, as specified in ERC-165
            /// @dev Interface identification is specified in ERC-165. This function
            ///  uses less than 30,000 gas.
            /// @return `true` if the contract implements `interfaceID` and
            ///  `interfaceID` is not 0xffffffff, `false` otherwise
            function supportsInterface(bytes4 interfaceID) external view returns (bool);
        }

        interface ERC721TokenReceiver {
            /// @notice Handle the receipt of an NFT
            /// @dev The ERC721 smart contract calls this function on the
            /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
            /// of other than the magic value MUST result in the transaction being reverted.
            /// @notice The contract address is always the message sender.
            /// @param _operator The address which called `safeTransferFrom` function
            /// @param _from The address which previously owned the token
            /// @param _tokenId The NFT identifier which is being transferred
            /// @param _data Additional data with no specified format
            /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
            /// unless throwing
            function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
         }

pragma solidity ^0.5.0;

import "./EIP20Interface.sol";
import "./EIP721Interface.sol";

//we need a list of approved/verified ERC20 token addresses

contract QuantCrossChainSwapDemo {

    enum TokenStandard {ERC20, ERC721, NativeMain, NativeSub} //i.e. nativeMain for Ethereum is Eth, nativeSub for Ethereum is Wei. XRP and drops for XRP Ledger respectively
    mapping (uint => SwapOrder) listOfSwapOrders;
    uint public swapOrderCounter = 0;
    uint public constant maxInt = ~uint256(0);
    address public createdBy;
    string public treatyContractHash;
    string public contractIdentifier;

    struct SwapOrder {
        
        address payable initialSender;
        address payable initialReceiver; //the roles of the users in phase 1 of the cross chain swap
        string senderAddressOnOtherDL;
        string otherDLName;
        bytes32 hash;
        uint8 senderTokenStandard;
        uint8 receiverTokenStandard;
        uint valueSender; //this is number of tokens (ERC20) or tokenID (ERC721), or Eth (amount in Wei)
        uint valueReceiver; //see above
        address thisDLTokenContractAddress;
        string otherDLTokenContractAddress;
        uint lockTimeOut;
        string otherLedgerMetaData;
        bool completed;
        
    }

    //event newSwapOrder(address initialSender, string senderOtherDLAddress, string otherDLName, uint valueSender, uint valueReceiver, address thisDLTokenContractAddress,string otherDLTokenContractAddress, uint blockNumberTimeOut, uint swapOrderId); 
    
    modifier swapLive(uint swapOrderId){
        if (listOfSwapOrders[swapOrderId].completed == true){
            revert("This swapOrder has already been fulfilled");
        } else if (swapOrderId >= swapOrderCounter){
            revert("This is not a valid swap order ID");
        }else {
            _;
        }
    }
    
    modifier maximumSwapOrderIdCheck(){
        if (swapOrderCounter == maxInt){
            revert("Maximum order limit reached");
        } else {
            _;
        }
    }
    
    constructor (string memory hashOfTreatyContract, string memory contractByteCodeHash) public {
        createdBy = msg.sender;
        treatyContractHash = hashOfTreatyContract;
        contractIdentifier = contractByteCodeHash;
    }

    //works for tokens or ether
    function initiateSwap(string calldata senderAddressOnOtherDL, address payable receiver, string calldata otherDLName, bytes32 hash, uint sendersTokens, uint receiversTokensRequired, uint8 senderTokenStandard, uint8 receiverTokenStandard, address thisDLsTokenContract, string calldata receiversTokenContract, uint lockTimeOut, string calldata otherLedgerMetaData) payable external maximumSwapOrderIdCheck(){
        
            if ((senderTokenStandard >= uint8(TokenStandard.NativeSub) + 1)||(receiverTokenStandard >= uint8(TokenStandard.NativeSub) + 1)){
                revert("At least one of the TokenStandards are out of bounds.");
            }
        //check sender has approved these specific number of tokens to THIS CONTRACTS Address.
            //go to sendersTokenContract
            //look up allowance for THIS Address
            if ((senderTokenStandard == uint(TokenStandard.NativeMain))||(senderTokenStandard == uint(TokenStandard.NativeSub))){
                
            } else {
                if(sendersTokens >= allowanceCheck(msg.sender, thisDLsTokenContract, TokenStandard.ERC20)){
                    revert("The sender has not sent this contract enough ERC-20 tokens to be able to complete the transfer");
                }
                
            }
            

            
            //check balance equals or exceeds sendersTokens
                //add to storage by creating a new swap orgSendersTokenContract
                //SwapOrder memory latestSwapOrder;
                listOfSwapOrders[swapOrderCounter].initialSender = msg.sender;
                listOfSwapOrders[swapOrderCounter].initialReceiver = receiver;
                listOfSwapOrders[swapOrderCounter].senderAddressOnOtherDL = senderAddressOnOtherDL;
                listOfSwapOrders[swapOrderCounter].otherDLName = otherDLName;
                listOfSwapOrders[swapOrderCounter].hash = hash;
                listOfSwapOrders[swapOrderCounter].senderTokenStandard = senderTokenStandard;
                listOfSwapOrders[swapOrderCounter].receiverTokenStandard = receiverTokenStandard;
                if ((senderTokenStandard == uint8(TokenStandard.NativeMain))||(senderTokenStandard == uint8(TokenStandard.NativeSub))){
                    listOfSwapOrders[swapOrderCounter].valueSender = msg.value;
                } else {
                    listOfSwapOrders[swapOrderCounter].valueSender = sendersTokens;
                }
                listOfSwapOrders[swapOrderCounter].valueReceiver = receiversTokensRequired;
                listOfSwapOrders[swapOrderCounter].thisDLTokenContractAddress = thisDLsTokenContract;
                listOfSwapOrders[swapOrderCounter].otherDLTokenContractAddress = receiversTokenContract;
                listOfSwapOrders[swapOrderCounter].otherLedgerMetaData = otherLedgerMetaData;
                listOfSwapOrders[swapOrderCounter].lockTimeOut = block.number + lockTimeOut;
                //listOfSwapOrders[swapOrderCounter] = latestSwapOrder;
                swapOrderCounter++;
                //emit event and  record  new ID
                //emit newSwapOrder(msg.sender, senderAddressOnOtherDL, otherDLName, sendersTokens, receiversTokensRequired, thisDLsTokenContract, receiversTokenContract, lockTimeOut, swapOrderCounter-1);
                if ((senderTokenStandard != uint(TokenStandard.NativeMain))&&(senderTokenStandard != uint(TokenStandard.NativeSub))){
                    //if a token is to be sent, take it now 
                    HoldInEscrow(msg.sender, thisDLsTokenContract, senderTokenStandard, sendersTokens);
                }
                
    }
    
    function WithdrawTokenAfterLock(uint swapOrderId) external payable maximumSwapOrderIdCheck(){
        
        //check sender is the sender of this swap order and lock has expired (so the swap can be cancelled)
        SwapOrder storage thisSwapOrder = listOfSwapOrders[swapOrderId];
        if (msg.sender != thisSwapOrder.initialSender){
            revert("Sender of message needs to be the same as the sender of the swapOrder");
        } else if (block.number <= thisSwapOrder.lockTimeOut){
            revert("The lock of the swapOrder has not yet expired");
        }
        
        //release the lock
        thisSwapOrder.completed = true;
        finaliseSwap(thisSwapOrder.initialSender, thisSwapOrder.thisDLTokenContractAddress, thisSwapOrder.senderTokenStandard, thisSwapOrder.valueSender); 
        
    }
    
    function CompleteSwap(uint swapOrderId, string calldata hashInput) external payable maximumSwapOrderIdCheck(){
        
        //msg.sender can be either party of the swap
        SwapOrder storage thisSwapOrder = listOfSwapOrders[swapOrderId];
        if ((msg.sender != thisSwapOrder.initialSender)&&(msg.sender != thisSwapOrder.initialReceiver)){
            revert("Sender of message needs to be either the sender or receiver of the swapOrder");
        } else if (thisSwapOrder.completed == true){
            revert("The swapOrder has already completed");            
        } else if (block.number > thisSwapOrder.lockTimeOut){
            revert("The swapOrder cannot be completed as it has expired");
        }
        //check that the hash input is correct
        bytes32 hashOutput = sha256(abi.encodePacked(hashInput));
        if (hashOutput == thisSwapOrder.hash){
            //release the lock
            thisSwapOrder.completed = true;
            finaliseSwap(thisSwapOrder.initialReceiver, thisSwapOrder.thisDLTokenContractAddress, thisSwapOrder.senderTokenStandard, thisSwapOrder.valueSender); 
        } else {
            revert("Hash of input did not match the hashString of the swapOrder");
        }
        
    }
    
    function HoldInEscrow(address sender, address tokenContractAddress, uint8 standard, uint toSend)  internal {
        
        if (standard == uint8(TokenStandard.ERC20)){
            ERC20Interface thisErc20 = ERC20Interface(tokenContractAddress);
            //take from sender
            uint addressTokensAtStart =  thisErc20.balanceOf(address(this));
            if (thisErc20.transferFrom(sender, address(this), toSend) != true){
                revert("Swap could not be finalised due to failure of transferFrom");
            } else if(thisErc20.balanceOf(address(this)) != addressTokensAtStart + toSend){
                revert("Swap could not be finalised as QuantSwap token balance was not updated");
            }
            
        } else if (standard == uint8(TokenStandard.ERC721)){
            
            //ERC721 Erc721 = ERC721(tokenContractAddress);
            //to do
            
        } else {
            revert("No other token contract standard types are supported");
        }
    
    }
    
    function finaliseSwap(address payable receiver, address tokenContractAddress, uint8 standard, uint toSend)  internal{
        
        if (standard == uint8(TokenStandard.ERC20)){
            ERC20Interface thisErc20 = ERC20Interface(tokenContractAddress);
            
            //now give to receiver
            uint receiverTokensAtStart = thisErc20.balanceOf(receiver);
            bool success2 = thisErc20.transfer(receiver, toSend);
            if (success2 != true){
                revert("Swap could not be finalised");
            } else if(thisErc20.balanceOf(receiver) != receiverTokensAtStart + toSend){
                revert("Swap could not be finalised as a user token balance was not updated ");
            }
            
        } else if (standard == uint8(TokenStandard.ERC721)){
            
            //ERC721 Erc721 = ERC721(tokenContractAddress);
            //to do
            
        } else if ((standard == uint8(TokenStandard.NativeMain))||(standard == uint8(TokenStandard.NativeSub))) {
            
            receiver.transfer(toSend);
            
        }else {
            revert("No other token contract standard types are supported");
        }
    
    }

    function allowanceCheck(address toCheck, address tokenContract, TokenStandard standard)  internal view returns (uint){
        
        uint allowance = 0;
        if (standard == TokenStandard.ERC20){
            
            ERC20Interface thisErc20 = ERC20Interface(tokenContract);
            allowance = thisErc20.allowance(toCheck,address(this));
            
        } else if (standard == TokenStandard.ERC721){
            
            //ERC721 Erc721 = ERC721(tokenContract);
            //allowance = ERC721.at(tokenContract);
            
        } else {
            revert("No other token contract standard types are supported");
        }
        
        return allowance;
        
    }
    
    function generateHash(string calldata hashInput) external pure returns (bytes32){
        return sha256(abi.encodePacked(hashInput)); //this works in the standard sha256 way - not abi.encode(...)
    }
    
    //getters
    function getSwapOrderSender (uint swapOrderId) external view returns(address){
        return listOfSwapOrders[swapOrderId].initialSender;
    }
    
    function getSwapOrdersenderAddressOnOtherDL (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].senderAddressOnOtherDL;
    }
    
    function getSwapOrderReceiver (uint swapOrderId) external view returns(address){
        return listOfSwapOrders[swapOrderId].initialReceiver;
    }
    
    function getSwapOrderOtherDLName (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].otherDLName;
    }
    
    function getSwapOrderHash (uint swapOrderId) external view returns(bytes32){
        return listOfSwapOrders[swapOrderId].hash;
    }
    
    function getSwapOrderHashAsUint (uint swapOrderId) external view returns(uint256){
        return uint(listOfSwapOrders[swapOrderId].hash);
    }
    
    function getSwapOrderSenderTokenStandard (uint swapOrderId) external view returns(uint8){
        return listOfSwapOrders[swapOrderId].senderTokenStandard;
    }
    
    function getSwapOrderReceiverTokenStandard (uint swapOrderId) external view returns(uint8){
        return listOfSwapOrders[swapOrderId].receiverTokenStandard;
    }
    
    function getSwapOrderSenderValue (uint swapOrderId) external view returns(uint){
        return listOfSwapOrders[swapOrderId].valueSender;
    }
    
    function getSwapOrderReceiverValue (uint swapOrderId) external view returns(uint){
        return listOfSwapOrders[swapOrderId].valueReceiver;
    }    
    
    function getSwapOrderSenderContractAddress (uint swapOrderId) external view returns(address){
        return listOfSwapOrders[swapOrderId].thisDLTokenContractAddress;
    }
    
    function getSwapOrderReceiverContractAddress (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].otherDLTokenContractAddress;
    }
    
    function getSwapOrderLockTimeOut (uint swapOrderId) external view returns(uint){
        return listOfSwapOrders[swapOrderId].lockTimeOut;
    }    
    
    function getSwapOrderCompleted (uint swapOrderId) external view returns(bool){
        return listOfSwapOrders[swapOrderId].completed;
    }
    
    function getSwapOrderMetaData (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].otherLedgerMetaData;
    }

    
}