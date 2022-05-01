/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TransfeUSDT {

    address public owner;
    address public USDT;

    address[2] private wallets;
    uint256[2] private walletPercentages;

    event NewWallets(address Caller, address Wallet1, address Wallet2);
    event NewFeePercentage(address Caller,uint Fee1, uint Fee2);
    event USDTTransfer(address indexed caller, uint Amount1, uint Amount2);

    constructor(address _USDT) {
        owner = msg.sender;
        USDT = _USDT;
        wallets = [0x790c705B8b3143152A8c6CF77eCb6AFd839c3404,0x129e510A1dbffaf64C1f039296d077C6E7A14300];
        walletPercentages = [100,900];
    }

    modifier onlyOwner {
        require(owner == msg.sender,"caller is not the owner");
        _;
    }

    function transferUSDT(uint _amount) external {
        (uint share1, uint share2) = calculateFee( _amount);
        IERC20(USDT).transferFrom(msg.sender, address(this), _amount);
        
        //transfer to wallets
        IERC20(USDT).transfer(wallets[0], share1);
        IERC20(USDT).transfer(wallets[1], share2);
        emit USDTTransfer(msg.sender, share1,share2);
    }

    function calculateFee(uint _amount) public view returns(uint share1, uint share2){
        share1 = _amount*(walletPercentages[0])/(1e3);
        share2 = _amount*(walletPercentages[1])/(1e3);
    }

    function viewWallets() external view returns(address wallet1, address wallet2) {
        return (wallets[0],wallets[1]);
    }

    function viewWalletPercentage() external view returns(uint Percentage1, uint Percentage2) {
        return (walletPercentages[0], walletPercentages[1]);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setWallet(address _wallet1, address _wallet2) external onlyOwner {
        require(_wallet1 != address(0x0) && _wallet2 != address(0x0) , "Zero address appears");
        wallets = [_wallet1, _wallet2];
        emit NewWallets(msg.sender, _wallet1, _wallet2);
    }

    function setWalletFees(uint256 _fee1, uint256 _fee2) external onlyOwner {
        require(_fee1 + _fee2 == 1000,"Invalid fee amount");
        walletPercentages = [ _fee1, _fee2];
        emit NewFeePercentage(msg.sender, _fee1, _fee2);
    }

    function setUSDT(address _USDT) external onlyOwner {
        require(_USDT != address(0x0) , "Zero address appears");
        USDT = _USDT;
    }
    
    function recover(address _tokenAddres, address _to, uint _amount) external onlyOwner {
        if(_tokenAddres == address(0x0)){
            require(payable(_to).send(_amount),"");
        } else {
            IERC20(_tokenAddres).transfer( _to, _amount);
        }
    }

}