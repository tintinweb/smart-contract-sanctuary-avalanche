//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";

interface IToken {
    function getOwner() external view returns (address);
    function burn(uint256 amount) external returns (bool);
}

contract FeeReceiver {

    // token
    address public immutable token;

    // Recipients Of Fees
    address public marketing;

    modifier onlyOwner(){
        require(
            msg.sender == IToken(token).getOwner(),
            'Only Token Owner'
        );
        _;
    }

    constructor(address _token, address marketingWallet) {
        token = _token;
        marketing = marketingWallet;
    }

    function trigger() external {

        // MDB Balance In Contract
        uint balance = IERC20(token).balanceOf(address(this));

        if (balance <= 1) {
            return;
        }

        // send to marketing
        _send(marketing, balance / 2);
        
        // burn rest
        IToken(token).burn(IERC20(token).balanceOf(address(this)));
    }
   
    function setMarketing(address newMarketing) external onlyOwner {
        marketing = newMarketing;
    }
    
    function withdrawETH() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }
    
    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
    
    receive() external payable {}

    function _send(address recipient, uint amount) internal {
        IERC20(token).transfer(recipient, amount);
    }
}