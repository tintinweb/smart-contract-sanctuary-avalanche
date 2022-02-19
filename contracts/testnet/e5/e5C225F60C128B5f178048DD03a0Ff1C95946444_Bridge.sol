//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./SignatureVerifier.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Bridge is SignatureVerifier, Ownable {
    mapping(address => uint256) private _userNonce;
    mapping(address => address) private _matchPair;
    event TokenMovedToBridge(
        address indexed from,
        address tokenAddress,
        uint256 amount,
        uint256 nonce,
        bytes signature
    );
    event TokenMovedToUser(
        address indexed to,
        address tokenAddress,
        uint256 amount,
        uint256 nonce,
        bytes signature
    );

    function getUserNonce() public view returns (uint256) {
        return _userNonce[msg.sender];
    }

    function addMatchTokenPair(address _token, address _matchToken)
        public
        onlyOwner
    {
        _matchPair[_token] = _matchToken;
    }

    function getMatchToken(address _token) public view returns (address) {
        return _matchPair[_token];
    }

    function bridgeTransferExactToken(
        address _to,
        address _tokenAddress,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) external onlyOwner returns (bool) {
        require(_tokenAddress != address(0), "BRIDGE: invalid token address");
        require(_amount > 0, "BRIDGE: invalid amount");
        require(_signature.length == 65, "BRIDGE: invalid signature");
        require(_userNonce[_to] == _nonce, "BRIDGE: mismatch nonce");
        require(
            _verifySignature(_to, _tokenAddress, _amount, _nonce, _signature),
            "BRIDGE: mismatch signature"
        );
        address _matchTokenAddress = getMatchToken(_tokenAddress);
        require(
            _matchTokenAddress != address(0),
            "BRIDGE: non-existent token match"
        );
        _userNonce[_to]++;
        _moveTokenFromBridgeToUser(_to, _matchTokenAddress, _amount);
        emit TokenMovedToUser(
            _to,
            _matchTokenAddress,
            _amount,
            _nonce,
            _signature
        );
        return true;
    }

    function moveTokenThroughBridgeForExactToken(
        address _tokenAddress,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) external returns (bool) {
        require(_nonce == _userNonce[msg.sender], "BRIDGE: nonce mismatch");
        _userNonce[msg.sender]++;
        _moveTokenFromUserToBridge(msg.sender, _tokenAddress, _amount);
        emit TokenMovedToBridge(
            msg.sender,
            _tokenAddress,
            _amount,
            _nonce,
            _signature
        );
        return true;
    }

    function _moveTokenFromUserToBridge(
        address _from,
        address _tokenAddress,
        uint256 _amount
    ) internal returns (bool) {
        require(_tokenAddress != address(0), "BRIDGE: invalid token address");
        require(_amount > 0, "BRIDGE: invalid amount");
        IERC20 token = IERC20(_tokenAddress);
        return token.transferFrom(_from, address(this), _amount); // transfer from user to bridge
    }

    function _moveTokenFromBridgeToUser(
        address _to,
        address _tokenAddress,
        uint256 _amount
    ) internal returns (bool) {
        require(_tokenAddress != address(0), "BRIDGE: invalid token address");
        require(_amount > 0, "BRIDGE: invalid amount");
        IERC20 token = IERC20(_tokenAddress);
        return token.transfer(address(_to), _amount); // transfer from bridge to user
    }
}