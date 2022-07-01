/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-30
*/

// File: contracts/PaymentReceived.sol



pragma solidity ^0.8.7;



/**

 * @title Receive Payment Contract

 * @notice Recieves AVAX from a creator and authorizes that user.

 */





contract PaymentReceived {

    bool public lock;



    address payable public owner;



    mapping(address => mapping(address => bool)) public Authorized;

    

    mapping(uint256 => uint256) public Prices;



    mapping(uint256 => string) public Services;



    uint256 public increment;



    event AuthorizedEvent(address indexed sender, address indexed nftContract);

    event Withdraw(uint256 indexed amount);





    modifier onlyOwner {

        require(msg.sender == owner, "Only the owner can perform this action");

        _;

    }



    function initialize() public {

        increment = 1;

        lock = false;

        owner = payable(msg.sender);

    }

    function addPrice(uint256 _price, string memory _service) external onlyOwner {

        Services[increment] = _service;

        Prices[increment] = _price;

        increment++;

    }

    function changePrice(uint256 _index, uint256 _price) external onlyOwner {

        Prices[_index] = _price;

    }



    function authorize(uint256 _service, address _contract) external payable returns(bool _success) {

        require(!lock, "The contract is locked, contact the owner to unlock it");

        require(_contract != address(0), "PaymentReceived: INVALID_ADDRESS");

        require(!Authorized[msg.sender][_contract], "Already authorized");

        lock = true;

        require(msg.value >= Prices[_service], "Not enough Avax sent");

        Authorized[msg.sender][_contract] = true;

        emit AuthorizedEvent(msg.sender, _contract);

        lock = false;

        return true;

    }



    function unlock() external onlyOwner {

        lock = false;

    }



    function withdraw() external onlyOwner {

        require(!lock);

        require(address(this).balance > 0, "No funds to withdraw");

        lock = true;

        owner.transfer(address(this).balance);

        emit Withdraw(address(this).balance);

        lock = false;

    }

}