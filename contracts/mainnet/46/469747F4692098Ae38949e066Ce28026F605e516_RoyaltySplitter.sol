/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: royalties.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice This is the royalties splitter for American Gothic
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./modules/splitter/PaymentSplitterV3NFT.sol";

contract RoyaltySplitter is PaymentSplitterV3NFT {

  // @notice Function to receive ether, msg.data must be empty
  receive() 
    external
    payable {
    // From PaymentSplitterV3NFT.sol
    emit PaymentReceived(msg.sender, msg.value);
  }

  // @notice Function to receive ether, msg.data is not empty
  fallback()
    external
    payable {
    // From PaymentSplitterV3NFT.sol
    emit PaymentReceived(msg.sender, msg.value);
  }

  // @notice this is a public getter for ETH blance on contract
  function getBalance()
    external
    view
    returns (uint) {
    return address(this).balance;
  }

  // @notice Standard override for ERC165
  // @param interfaceId: interfaceId to check for compliance
  // @return: bool if interfaceId is supported
  function supportsInterface(
    bytes4 interfaceId
  ) public
    view
    virtual
    override 
    returns (bool) {
    return (
      interfaceId == type(IRole).interfaceId  ||
      interfaceId == type(IDeveloper).interfaceId  ||
      interfaceId == type(IDeveloperV2).interfaceId  ||
      interfaceId == type(IOwner).interfaceId  ||
      interfaceId == type(IOwnerV2).interfaceId  ||
      interfaceId == type(IPaymentSplitterV2).interfaceId  ||
      interfaceId == type(IPaymentSplitterV3).interfaceId
    );
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: PaymentSplitterV3NFT.sol
 * @author: written by Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice was once an OZ payment splitter now, a maxflow payment splitter
 * @custom:OG-Source ./PaymentSplitterV2.sol
 * @custom:error-code PSV3:E1 No Shares for address
 * @custom:error-code PSV3:E2-ETH No payment due for address, in ETH
 * @custom:error-code PSV3:E2-20 No payment due for address, in ERC 20
 * @custom:error-code PSV3:E3 Can not use address(0)
 * @custom:error-code PSV3:E4 Shares can not be 0
 * @custom:error-code PSV3:E5 User has shares already
 * @custom:error-code PSV3:E6 ERC-20 can not be address(0)
 * @custom:error-code PSV3:E7 ERC-20 already in authorized list
 * @custom:error-code PSV3:E8 ERC-20 not in authorized list
 * @custom:change-log added ERC165 with Interfaces IPaymentSplitter & IPaymentSplitterV3
 * @custom:change-log reintroduced ERC-20 via supported tokens array
 * @custom:change-log modified claim to eth/20/both
 * @custom:change-log added pay all
 * @custom:change-log added custom error-codes above
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./IPaymentSplitterV3.sol";
import "../../access/MaxAccess.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */

abstract contract PaymentSplitterV3NFT is MaxAccess
                                        , IPaymentSplitterV3 {
  uint256 private _totalShares = 1000;
  uint256 private _totalReleased;

  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  mapping(IERC20 => uint256) private _erc20TotalReleased;
  mapping(IERC20 => mapping(address => uint256)) private _erc20Released;
  address[] private _payees;
  IERC20[] private _authTokens;

  address private nft;
  mapping(uint256 => uint256) private _nftReleased;
  mapping(IERC20 => mapping(uint256 => uint256)) private _nftErc20Released;

  event TokenAdded(IERC20 indexed token);
  event TokenRemoved(IERC20 indexed token);
  event TokensReset();
  event PayeeAdded(address account, uint256 shares);
  event PayeeRemoved(address account, uint256 shares);
  event PayeesReset();
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  /**
   * @notice The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   *
   *  receive() external payable virtual {
   *    emit PaymentReceived(msg.sender, msg.value);
   *  }
   *
   *  // Fallback function is called when msg.data is not empty
   *  // Added to PaymentSplitter.sol
   *  fallback() external payable {
   *    emit PaymentReceived(msg.sender, msg.value);
   *  }
   *
   * receive() and fallback() to be handled at final contract
   */

  // Internals of this contract

  // @dev: returns uint of payment for account in wei
  // @param account: account to lookup
  // @return: uint of wei
  function _pendingPayment(
    address account
  ) internal
    view
    returns (uint256) {
    uint totalReceived = address(this).balance + _totalReleased;
    return (totalReceived * _shares[account]) / _totalShares - _released[account];
  }

  // @dev: returns uint of payment in ERC20.decimals()
  // @param token: IERC20 address of token
  // @param account: account to lookup
  // @return: uint of ERC20.decimals()
  function _pendingPayment(
    IERC20 token
  , address account
  ) internal
    view
    returns (uint256) {
    uint totalReceived = token.balanceOf(address(this)) + _erc20TotalReleased[token];
    return (totalReceived * _shares[account]) / _totalShares - _erc20Released[token][account];
  }

  // @dev: claims "eth" for user
  // @param user: address of user
  function _claimETH(
    address user
  ) internal {
    if (_shares[user] == 0) {
      revert MaxSplaining({
        reason: "PSV3:E1"
      });
    }

    uint256 payment = _pendingPayment(user);

    if (payment == 0) {
      revert MaxSplaining({
        reason: "PSV3:E2-ETH"
      });
    }

    // _totalReleased is the sum of all values in _released.
    // If "_totalReleased += payment" does not overflow,
    // then "_released[account] += payment" cannot overflow.
    _totalReleased += payment;
    unchecked {
      _released[user] += payment;
    }
    Address.sendValue(payable(user), payment);
    emit PaymentReleased(user, payment);
  }

  // @dev: claims ERC20 for user
  // @param token: ERC20 Contract Address
  // @param user: address of user
  function _claimERC20(
    IERC20 token
  , address user
  ) internal {
    if (_shares[user] == 0) {
      revert MaxSplaining({
        reason: "PSV3:E1"
      });
    }

    uint256 payment = _pendingPayment(token, user);

    if (payment == 0) {
      revert MaxSplaining({
        reason: "PSV3:E2-20"
      });
    }

    // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
    // If "_erc20TotalReleased[token] += payment" does not overflow,
    // then "_erc20Released[token][account] += payment" cannot overflow.
    _erc20TotalReleased[token] += payment;
    unchecked {
      _erc20Released[token][user] += payment;
    }
    SafeERC20.safeTransfer(token, user, payment);
    emit ERC20PaymentReleased(token, user, payment);
  }

  // @dev: this claims both "eth" and ERC20 for user based off _authTokens[]
  // @param user: address of user
  function _claimAll(
    address user
  ) internal {
    _claimETH(user);
    uint len = _authTokens.length;
    for (uint x = 0; x < len;) {
      _claimERC20(_authTokens[x], user);
      unchecked {
        ++x;
      }
    }
  }

  // @dev: this claims both "eth" and ERC20 for user based off _authTokens[] and all _payees[]
  function _payAll()
    internal {
    uint len = _payees.length;
    for (uint x = 0; x < len;) {
      _claimAll(_payees[x]);
      unchecked {
        ++x;
      }
    }
  }

  // @dev: this will add a payee to PaymentSplitterV3
  // @param account: address of account to add
  // @param shares: uint256 of shares to add to account
  function _addPayee(
    address account
  , uint256 addShares
  ) internal {
    if (account == address(0)) {
      revert MaxSplaining({
        reason: "PSV3:E3"
      });
    } else if (addShares == 0) {
      revert MaxSplaining({
        reason: "PSV3:E4"
      });
    } else if (_shares[account] > 0) {
      revert MaxSplaining({
        reason: "PSV3:E5"
      });
    }

    _payees.push(account);
    _shares[account] = addShares;
    _totalShares = _totalShares + addShares;

    emit PayeeAdded(account, addShares);
  }

  // @dev: finds index of an account in _payees
  // @param account: address of account to find
  // @return index: position of account in address[] _payees
  function _findIndex(
    address account
  ) internal
    view
    returns (uint index) {
    uint len = _payees.length;
    for (uint x = 0; x < len;) {
      if (_payees[x] == account) {
        index = x;
      }
      unchecked {
        ++x;
      }
    }
  }

  // @dev: removes an account in _payees
  // @param account: address of account to remove
  // @notice will keep payment data in there
  function _removePayee(
    address account
  ) internal {
    if (account == address(0)) {
      revert MaxSplaining({
        reason: "PSV3:E3"
      });
    }

    // This finds the payee in the array _payees and removes it
    uint remove = _findIndex(account);
    address last = _payees[_payees.length - 1];
    _payees[remove] = last;
    _payees.pop();

    uint removeTwo = _shares[account];
    _shares[account] = 0;
    _totalShares = _totalShares - removeTwo;

    emit PayeeRemoved(account, removeTwo);
  }

  // @dev: this clears all shares/users from PaymentSplitterV3
  //       this WILL leave the payments already claimed on contract
  function _clearPayees()
    internal {
    uint len = _payees.length;
    for (uint x = 0; x < len;) {
      address account = _payees[x];
      _shares[account] = 0;
      unchecked {
         ++x;
      }
    }
    _totalShares = 1000;
    delete _payees;
    emit PayeesReset();
  }

  // @dev: this returns if token is in _authTokens[]
  // @param token: IERC20 to check
  // @return check: bool true/false (default)
  function _tokenCheck(
    IERC20 token
  ) internal
    view
    returns (bool check) {
    uint len = _authTokens.length;
    for (uint x = 0; x < len;) {
      if (_authTokens[x] == token) {
        check = true;
      }
      unchecked {
        ++x;
      }
    }
  }

  // @dev: this adds an ERC20 to _authTokens[]
  // @param token: IERC20 to add
  // @notice will call _tokenCheck(token) for error/revert
  function _addToken(
    IERC20 token
  ) internal {
    if (address(token) == address(0)) {
      revert MaxSplaining({
        reason: "PSV3:E6"
      });
    }
    if (_tokenCheck(token)) {
      revert MaxSplaining({
        reason: "PSV3:E7"
      });
    }

    _authTokens.push(token);
    emit TokenAdded(token);
  }

  // @dev: finds token in _authTokens[]
  // @param token: ERC20 token to find
  // @return index: position of account in IERC20[] _authTokens
  function _findToken(
    IERC20 token
  ) internal
    view
    returns (uint index) {
    uint len = _authTokens.length;
    for (uint x = 0; x < len;) {
      if (_authTokens[x] == token) {
        index = x;
      }
      unchecked {
        ++x;
      }
    }
  }

  // @dev: removes token in _authTokens[]
  // @param token: ERC20 token to remove
  function _removeToken(
    IERC20 token
  ) internal {
    if (address(token) == address(0)) {
      revert MaxSplaining({
        reason: "PSV3:E6"
      });
    }
    if (!_tokenCheck(token)) {
      revert MaxSplaining({
        reason: "PSV3:E8"
      });
    }

    // This finds the payee in the array _payees and removes it
    uint remove = _findToken(token);
    IERC20 last = _authTokens[_payees.length - 1];
    _authTokens[remove] = last;
    _payees.pop();

    emit TokenRemoved(token);
  }

  // @dev: this clears all tokens from _authTokens[]
  function _clearTokens()
    internal {
    delete _authTokens;
    emit TokensReset();
  }

  // internals for NFT claims

  // @dev: returns uint of payment for NFT tokenId in wei
  // @param tokenId: token ID to query
  // @return: uint of wei
  function _pendingPayment(
    uint256 tokenId
  ) internal
    view
    returns (uint256) {
    uint totalReceived = address(this).balance + _totalReleased;
    return (totalReceived) / _totalShares - _nftReleased[tokenId];
  }

  // @dev: returns uint of payment in ERC20.decimals()
  // @param token: IERC20 address of token
  // @param tokenId: token ID to query
  // @return: uint of ERC20.decimals()
  function _pendingPayment(
    IERC20 token
  , uint256 tokenId
  ) internal
    view
    returns (uint256) {
    uint totalReceived = token.balanceOf(address(this)) + _erc20TotalReleased[token];
    return (totalReceived) / _totalShares - _nftErc20Released[token][tokenId];
  }

  // @dev: claims "eth" for tokenID
  // @param tokenId: token ID of user
  function _claimETH(
    uint256 tokenId
  ) internal {
    uint256 payment = _pendingPayment(tokenId);
    address user = IERC721(nft).ownerOf(tokenId);

    if (payment == 0) {
      revert MaxSplaining({
        reason: "PSV3:E2-ETH"
      });
    }

    // _totalReleased is the sum of all values in _released.
    // If "_totalReleased += payment" does not overflow,
    // then "_released[account] += payment" cannot overflow.
    _totalReleased += payment;
    unchecked {
      _nftReleased[tokenId] += payment;
    }
    Address.sendValue(payable(user), payment);
    emit PaymentReleased(user, payment);
  }

  // @dev: claims ERC20 for user
  // @param token: ERC20 Contract Address
  // @param tokenId: token ID of user
  function _claimERC20(
    IERC20 token
  , uint256 tokenId
  ) internal {
    uint256 payment = _pendingPayment(token, tokenId);
    address user = IERC721(nft).ownerOf(tokenId);

    if (payment == 0) {
      revert MaxSplaining({
        reason: "PSV3:E2-20"
      });
    }

    // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
    // If "_erc20TotalReleased[token] += payment" does not overflow,
    // then "_erc20Released[token][account] += payment" cannot overflow.
    _erc20TotalReleased[token] += payment;
    unchecked {
      _nftErc20Released[token][tokenId] += payment;
    }
    SafeERC20.safeTransfer(token, user, payment);
    emit ERC20PaymentReleased(token, user, payment);
  }

  // @dev: this claims both "eth" and ERC20 for user based off _authTokens[]
  // @param user: address of user
  function _claimAll(
    uint256 tokenId
  ) internal {
    _claimETH(tokenId);
    uint len = _authTokens.length;
    for (uint x = 0; x < len;) {
      _claimERC20(_authTokens[x], tokenId);
      unchecked {
        ++x;
      }
    }
  }

  // Now the externals, listed by use

  // @dev: this claims all "eth" on contract for msg.sender
  function claim()
    external
    virtual
    override {
    _claimETH(msg.sender);
  }

  // @dev: this claims all ERC20 on contract for msg.sender
  // @param token: ERC20 Contract Address
  function claim(
    IERC20 token
  ) external
    virtual
    override {
    _claimERC20(token, msg.sender);
  }

  // @dev: this claims all "eth" on contract for tokenId
  // @param tokenId: Token ID to claim
  function claim(
    uint256 tokenId
  ) external
    virtual {
    _claimETH(tokenId);
  }

  // @dev: this claims all ERC20 on contract for tokenId
  // @param token: ERC20 Contract Address
  // @param tokenId: Token ID to claim
  function claim(
    IERC20 token
  , uint256 tokenId
  ) external
    virtual {
    _claimERC20(token, tokenId);
  }

  // @dev: this claims all "eth" and ERC20's from IERC20[] _authTokens
  //       on contract for msg.sender
  // @param tokenId: Token ID to claim
  function claimAll(
    uint256 tokenId
  ) external
    virtual {
    _claimAll(tokenId);
  }

  // @dev: this claims all "eth" and ERC20's from IERC20[] _authTokens
  //       on contract for msg.sender
  function claimAll()
    external
    virtual
    override {
    _claimAll(msg.sender);
  }

  // @dev: This adds a payment split to PaymentSplitterV3.sol
  // @param newSplit: Address of payee
  // @param newShares: Shares to send user
  function addSplit (
    address newSplit
  , uint256 newShares
  ) external
    virtual
    override
    onlyDev() {
    _addPayee(newSplit, newShares);
  }

  // @dev: This pays all payment splits on PaymentSplitterV3.sol
  function paySplits()
    external
    virtual
    override
    onlyDev() {
    _payAll();
  }

  // @dev: This removes a payment split on PaymentSplitterV3.sol
  // @param remove: Address of payee to remove
  // @notice use paySplits() prior to use if anything is on the contract
  function removeSplit (
    address remove
  ) external
    virtual
    override
    onlyDev() {
    _removePayee(remove);
  }

  // @dev: This removes all payment splits on PaymentSplitterV3.sol
  // @notice use paySplits() prior to use if anything is on the contract
  function clearSplits()
    external
    virtual
    override
    onlyDev() {
    _clearPayees();
  }

  // @dev: This adds a token on PaymentSplitterV3.sol
  // @param token: ERC20 Contract Address to add
  function addToken(
    IERC20 token
  ) external
    virtual
    override
    onlyDev() {
    _addToken(token);
  }

  // @dev: This removes a token on PaymentSplitterV3.sol
  // @param token: ERC20 Contract Address to remove
  function removeToken(
    IERC20 token
  ) external
    virtual
    override
    onlyDev() {
    _removeToken(token);
  }

  // @dev: This removes all _authTokens on PaymentSplitterV3.sol
  function clearTokens()
    external
    virtual
    override
    onlyDev() {
    _clearTokens();
  }

  // @dev: returns total shares
  // @return: uint256 of all shares on contract
  function totalShares()
    external
    view
    virtual
    override
    returns (uint256) {
    return _totalShares;
  }

  // @dev: returns total releases in "eth"
  // @return: uint256 of all "eth" released in wei
  function totalReleased()
    external
    view
    virtual
    override
    returns (uint256) {
    return _totalReleased;
  }

  // @dev: returns total releases in ERC20
  // @param token: ERC20 Contract Address
  // @return: uint256 of all ERC20 released in IERC20.decimals()
  function totalReleased(
    IERC20 token
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _erc20TotalReleased[token];
  }

  // @dev: returns shares of an address
  // @param account: address of account to return
  // @return: mapping(address => uint) of _shares
  function shares(
    address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _shares[account];
  }

  // @dev: returns released "eth" of an account
  // @param account: address of account to look up
  // @return: mapping(address => uint) of _released
  function released(
    address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _released[account];
  }


  // @dev: returns released ERC20 of an account
  // @param token: ERC20 Contract Address
  // @param account: address of account to look up
  // @return: mapping(address => uint) of _released
  function released(
    IERC20 token
  , address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _erc20Released[token][account];
  }

  // @dev: returns index number of payee
  // @param index: number of index
  // @return: address at _payees[index]
  function payee(
    uint256 index
  ) external
    view
    virtual
    override
    returns (address) {
    return _payees[index];
  }

  // @dev: returns amount of "eth" that can be released to account
  // @param account: address of account to look up
  // @return: uint in wei of "eth" to release
  function releasable(
    address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _pendingPayment(account);
  }

  // @dev: returns amount of ERC20 that can be released to account
  // @param token: ERC20 Contract Address
  // @param account: address of account to look up
  // @return: uint in IERC20.decimals() of ERC20 to release
  function releasable(
    IERC20 token
  , address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _pendingPayment(token, account);
  }

  // @dev: this returns the array of _authTokens[]
  // @return: IERC20[] _authTokens
  function supportedTokens()
    external
    view
    virtual
    override
    returns (IERC20[] memory) {
    return _authTokens;
  }

  // @dev: this returns the array length of _authTokens[]
  // @return: uint256 of _authTokens.length
  function supportedTokensLength()
    external
    view
    virtual
    override
    returns (uint256) {
    return _authTokens.length;
  }

  // @dev set nft
  function setNFT(
    address ca
  ) external
    virtual
    onlyDev() {
    nft = ca;
  }

  // @dev see nft
  function nftContract()
    external
    view
    virtual
    returns (address) {
    return nft;
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IPaymentSplitterV3.sol
 * @author: OG was OZ, rewritten by Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Interface extension for PaymentSplitter.sol
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./IPaymentSplitterV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPaymentSplitterV3 is IPaymentSplitterV2 {

  // @dev: this claims all ERC20 on contract for msg.sender
  // @param token: ERC20 Contract Address
  function claim(
    IERC20 token
  ) external;

  // @dev: this claims all "eth" and ERC20's from IERC20[] _authTokens
  //       on contract for msg.sender
  function claimAll()
    external;

  // @dev: This adds a token on PaymentSplitterV3.sol
  // @param token: ERC20 Contract Address to add
  function addToken(
    IERC20 token
  ) external;

  // @dev: This removes a token on PaymentSplitterV3.sol
  // @param token: ERC20 Contract Address to remove
  function removeToken(
    IERC20 token
  ) external;

  // @dev: This removes all _authTokens on PaymentSplitterV3.sol
  function clearTokens()
    external;

  // @dev: returns total releases in ERC20
  // @param token: ERC20 Contract Address
  // @return: uint256 of all ERC20 released in IERC20.decimals()
  function totalReleased(
    IERC20 token
  ) external
    view
    returns (uint256);

  // @dev: returns released ERC20 of an account
  // @param token: ERC20 Contract Address
  // @param account: address of account to look up
  // @return: mapping(address => uint) of _released
  function released(
    IERC20 token
  , address account
  ) external
    view
    returns (uint256);

  // @dev: returns amount of ERC20 that can be released to account
  // @param token: ERC20 Contract Address
  // @param account: address of account to look up
  // @return: uint in IERC20.decimals() of ERC20 to release
  function releasable(
    IERC20 token
  , address account
  ) external
    view
    returns (uint256);

  // @dev: this returns the array of _authTokens[]
  // @return: IERC20[] _authTokens
  function supportedTokens()
    external
    view
    returns (IERC20[] memory);

  // @dev: this returns the array length of _authTokens[]
  // @return: uint256 of _authTokens.length
  function supportedTokensLength()
    external
    view
    returns (uint256);
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IPaymentSplitter.sol
 * @author: OG was OZ, rewritten by Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Interface for PaymentSplitter.sol
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPaymentSplitterV2 is IERC165 {

  // @dev: this claims all "eth" on contract for msg.sender
  function claim()
    external;

  // @dev: This adds a payment split to PaymentSplitterV3.sol
  // @param newSplit: Address of payee
  // @param newShares: Shares to send user
  function addSplit (
    address newSplit
  , uint256 newShares
  ) external;

  // @dev: This pays all payment splits on PaymentSplitterV3.sol
  function paySplits()
    external;

  // @dev: This removes a payment split on PaymentSplitterV3.sol
  // @param remove: Address of payee to remove
  // @notice use paySplits() prior to use if anything is on the contract
  function removeSplit (
    address remove
  ) external;

  // @dev: This removes all payment splits on PaymentSplitterV3.sol
  // @notice use paySplits() prior to use if anything is on the contract
  function clearSplits()
    external;

  // @dev: returns total shares
  // @return: uint256 of all shares on contract
  function totalShares()
    external
    view
    returns (uint256);

  // @dev: returns total releases in "eth"
  // @return: uint256 of all "eth" released in wei
  function totalReleased()
    external
    view
    returns (uint256);

  // @dev: returns shares of an address
  // @param account: address of account to return
  // @return: mapping(address => uint) of _shares
  function shares(
    address account
  ) external
    view
    returns (uint256);

  // @dev: returns released "eth" of an account
  // @param account: address of account to look up
  // @return: mapping(address => uint) of _released
  function released(
    address account
  ) external
    view
    returns (uint256);

  // @dev: returns index number of payee
  // @param index: number of index
  // @return: address at _payees[index]
  function payee(
    uint256 index
  ) external
    view
    returns (address);

  // @dev: returns amount of "eth" that can be released to account
  // @param account: address of account to look up
  // @return: uint in wei of "eth" to release
  function releasable(
    address account
  ) external
    view
    returns (uint256);

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Roles.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Library for MaxAcess.sol
 * @custom:error-code Lib-Roles:E1 User has role already
 * @custom:error-code Lib-Roles:E2 User does not have role to revoke
 * @custom:change-log Custom errors added above
 *
 * Include with 'using Roles for Roles.Role;'
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

library Roles {

  // @dev: this is Unauthorized(), basically a catch all, zero description
  // @notice 0x82b42900 bytes4 of this
  error Unauthorized();

  // @dev: this is MaxSplaining(), giving you a reason, aka require(param, "reason")
  // @param reason: Use the "Contract name: error"
  // @notice 0x0661b792 bytes4 of this
  error MaxSplaining(
    string reason
  );

  event RoleChanged(bytes4 _type, address _user, bool _status); // 0x0baaa7ab

  struct Role {
    mapping(address => mapping(bytes4 => bool)) bearer;
  }

  function add(Role storage role, bytes4 _type, address account) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (has(role, _type, account)) {
      revert MaxSplaining({
        reason: "Roles:1"
      });
    }
    role.bearer[account][_type] = true;
    emit RoleChanged(_type, account, true);
  }

  function remove(Role storage role, bytes4 _type, address account) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (!has(role, _type, account)) {
      revert MaxSplaining({
        reason: "Roles:2"
      });
    }
    role.bearer[account][_type] = false;
    emit RoleChanged(_type, account, false);
  }

  function has(Role storage role, bytes4 _type, address account)
    internal
    view
    returns (bool)
  {
    if (account == address(0)) {
      revert Unauthorized();
    }
    return role.bearer[account][_type];
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: MaxErrors.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Custom errors for all contracts, minus libraries
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;


import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract MaxErrors {

  // @dev: this is Unauthorized(), basically a catch all, zero description
  // @notice 0x82b42900 bytes4 of this
  error Unauthorized();

  // @dev: this is MaxSplaining(), giving you a reason, aka require(param, "reason")
  // @param reason: Use the "Contract name: error"
  // @notice 0x0661b792 bytes4 of this
  error MaxSplaining(
    string reason
  );

  // @dev: this is TooSoonJunior(), using times
  // @param yourTime: should almost always be block.timestamp
  // @param hitTime: the time you should have started
  // @notice 0xf3f82ac5 bytes4 of this
  error TooSoonJunior(
    uint yourTime
  , uint hitTime
  );

  // @dev: this is TooLateBoomer(), using times
  // @param yourTime: should almost always be block.timestamp
  // @param hitTime: the time you should have ended
  // @notice 0x43c540ef bytes4 of this
  error TooLateBoomer(
    uint yourTime
  , uint hitTime
  );

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: MaxAccess.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Access control based off EIP 173/roles from OZ
 * @custom:error-code MA:E1 you are not admin or role
 * @custom:error-code MA:E2 pending developers can not use
 * @custom:error-code MA:E3 pending owners can not use
 * @custom:error-code MA:E4 you are not onlyDev()
 * @custom:error-code MA:E5 you are not onlyOwner()
 * @custom:change-log added custom errors above
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./IOwnerV2.sol";
import "./IDeveloperV2.sol";
import "./IRole.sol";
import "../lib/Roles.sol";
import "../errors/MaxErrors.sol";

abstract contract MaxAccess is MaxErrors
                             , IRole
                             , IOwnerV2
                             , IDeveloperV2 {

  using Roles for Roles.Role;

  Roles.Role private contractRoles;

  // bytes4 caluclated as follows
  // bytes4(keccak256(bytes(signature)))
  // developer() => 0xca4b208b
  // owner() => 0x8da5cb5b
  // admin() => 0xf851a440
  // was using trailing () for caluclations

  bytes4 constant private DEVS = 0xca4b208b;
  bytes4 constant private PENDING_DEVS = 0xca4b208a; // DEVS - 1
  bytes4 constant private OWNERS = 0x8da5cb5b;
  bytes4 constant private PENDING_OWNERS = 0x8da5cb5a; // OWNERS - 1
  bytes4 constant private ADMIN = 0xf851a440;

  // @dev you can sub your own address here... this is MaxFlowO2.eth
  // these are for displays anyways, and init().
  address private TheDev = address(0x4CE69fd760AD0c07490178f9a47863Dc0358cCCD);
  address private TheOwner = address(0x4CE69fd760AD0c07490178f9a47863Dc0358cCCD);

  constructor() {
    // supercedes all the logic below
    contractRoles.add(ADMIN, address(this));
    _grantRole(ADMIN, TheDev);
    _grantRole(OWNERS, TheOwner);
    _grantRole(DEVS, TheDev);
  }

  // modifiers
  modifier onlyRole(bytes4 role) {
    if (_checkRole(role, msg.sender) || _checkRole(ADMIN, msg.sender)) {
      _;
    } else {
      revert Unauthorized();
    }
  }

  modifier onlyDev() {
    if (!_checkRole(DEVS, msg.sender)) {
      revert Unauthorized();
    }
    _;
  }

  modifier onlyOwner() {
    if (!_checkRole(OWNERS, msg.sender)) {
      revert Unauthorized();
    }
    _;
  }

  // internal logic first 
  // (sets the tone later, and for later contracts)

  // @dev: this is the bool for checking if the account has a role via lib roles.sol
  // @param role: bytes4 of the role to check for
  // @param account: address of account to check
  // @return: bool true/false
  function _checkRole(
    bytes4 role
  , address account
  ) internal
    view
    virtual
    returns (bool) {
    return contractRoles.has(role, account);
  }

  // @dev: this is the internal to grant roles
  // @param role: bytes4 of the role
  // @param account: address of account to add
  function _grantRole(
    bytes4 role
  , address account
  ) internal
    virtual {
    contractRoles.add(role, account);
  }

  // @dev: this is the internal to revoke roles
  // @param role: bytes4 of the role
  // @param account: address of account to remove
  function _revokeRole(
    bytes4 role
  , address account
  ) internal
    virtual {
    contractRoles.remove(role, account);
  }

  // @dev: Returns `true` if `account` has been granted `role`.
  // @param role: Bytes4 of a role
  // @param account: Address to check
  // @return: bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    virtual
    override
    returns (bool) {
    return _checkRole(role, account);
  }

  // @dev: Returns the admin role that controls a role
  // @param role: Role to check
  // @return: admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view
    virtual
    override
    returns (bytes4) {
    return ADMIN;
  }

  // @dev: Grants `role` to `account`
  // @param role: Bytes4 of a role
  // @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external
    virtual
    override 
    onlyRole(role) {

    if (role == PENDING_DEVS) {
      // locks out pending devs from mass swapping roles
      if (_checkRole(PENDING_DEVS, msg.sender)) {
        revert Unauthorized();
      }
    }

    if (role == PENDING_OWNERS) {
      // locks out pending owners from mass swapping roles
      if (_checkRole(PENDING_OWNERS, msg.sender)) {
        revert Unauthorized();
      }
    }

    _grantRole(role, account);
  }

  // @dev: Revokes `role` from `account`
  // @param role: Bytes4 of a role
  // @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external
    virtual
    override
    onlyRole(role) {

    if (role == PENDING_DEVS) {
      // locks out pending devs from mass swapping roles
      if (account != msg.sender) {
        revert Unauthorized();
      }
    }

    if (role == PENDING_OWNERS) {
      // locks out pending owners from mass swapping roles
      if (account != msg.sender) {
        revert Unauthorized();
      }
    }
    _revokeRole(role, account);
  }

  // @dev: Renounces `role` from `account`
  // @param role: Bytes4 of a role
  // @param account: account to renounce role from
  function renounceRole(
    bytes4 role
  ) external
    virtual
    override 
    onlyRole(role) {
    address user = msg.sender;
    _revokeRole(role, user);
  }

  // Now the classic onlyDev() + "V2" suggested by auditors

  // @dev: Classic "EIP-173" but for onlyDev()
  // @return: Developer of contract
  function developer()
    external
    view
    virtual
    override
    returns (address) {
    return TheDev;
  }

  // @dev: This renounces your role as onlyDev()
  function renounceDeveloper()
    external
    virtual
    override 
    onlyRole(DEVS) {
    address user = msg.sender;
    _revokeRole(DEVS, user);
  }

  // @dev: Classic "EIP-173" but for onlyDev()
  // @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external
    virtual
    override 
    onlyRole(DEVS) {
    address user = msg.sender;
    _grantRole(DEVS, newDeveloper);
    _revokeRole(DEVS, user);
  }

  // @dev: This accepts the push-pull method of onlyDev()
  function acceptDeveloper()
    external
    virtual
    override 
    onlyRole(PENDING_DEVS) {
    address user = msg.sender;
    _revokeRole(PENDING_DEVS, user);
    _grantRole(DEVS, user);
  }

  // @dev: This declines the push-pull method of onlyDev()
  function declineDeveloper()
    external
    virtual
    override 
    onlyRole(PENDING_DEVS) {
    address user = msg.sender;
    _revokeRole(PENDING_DEVS, user);
  }

  // @dev: This starts the push-pull method of onlyDev()
  // @param newDeveloper: addres of new pending developer role
  function pushDeveloper(
    address newDeveloper
  ) external
    virtual
    override
    onlyRole(DEVS) {
    _grantRole(PENDING_DEVS, newDeveloper);
  }

  // @dev: This changes the display of developer()
  // @param newDisplay: new display addrss for developer()
  function setDeveloper(
    address newDisplay
  ) external
    onlyDev() {
    if (!_checkRole(DEVS, newDisplay)) {
      revert Unauthorized();
    }
    TheDev = newDisplay;
  }

  // Now the classic onlyOwner() + "V2" suggested by auditors

  // @dev: Classic "EIP-173" getter for owner()
  // @return: owner of contract
  function owner()
    external
    view
    virtual
    override
    returns (address) {
    return TheOwner;
  }

   // @dev: This renounces your role as onlyOwner()
  function renounceOwnership()
    external
    virtual
    override
    onlyRole(OWNERS) {
    address user = msg.sender;
    _revokeRole(OWNERS, user);
  }

  // @dev: Classic "EIP-173" but for onlyOwner()
  // @param newOwner: addres of new pending Developer role
  function transferOwnership(
    address newOwner
  ) external
    virtual
    override
    onlyRole(OWNERS) {
    address user = msg.sender;
    _grantRole(OWNERS, newOwner);
    _revokeRole(OWNERS, user);
  }

  // @dev: This accepts the push-pull method of onlyOwner()
  function acceptOwnership()
    external
    virtual
    override
    onlyRole(PENDING_OWNERS) {
    address user = msg.sender;
    _revokeRole(PENDING_OWNERS, user);
    _grantRole(OWNERS, user);
  }

  // @dev: This declines the push-pull method of onlyOwner()
  function declineOwnership()
    external
    virtual
    override
    onlyRole(PENDING_OWNERS) {
    address user = msg.sender;
    _revokeRole(PENDING_OWNERS, user);
  }

  // @dev: This starts the push-pull method of onlyOwner()
  // @param newOwner: addres of new pending developer role
  function pushOwnership(
    address newOwner
  ) external
    virtual
    override
    onlyRole(OWNERS) {
    _grantRole(PENDING_OWNERS, newOwner);
  }

  // @dev: This changes the display of Ownership()
  // @param newDisplay: new display addrss for Ownership()
  function setOwner(
    address newDisplay
  ) external
    onlyOwner() {
    if (!_checkRole(OWNERS, newDisplay)) {
      revert Unauthorized();
    }
    TheOwner = newDisplay;
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IRole.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Interface for MaxAccess version of roles
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRole is IERC165 {

  // @dev: Returns `true` if `account` has been granted `role`.
  // @param role: Bytes4 of a role
  // @param account: Address to check
  // @return: bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    returns (bool);

  // @dev: Returns the admin role that controls a role
  // @param role: Role to check
  // @return: admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view 
    returns (bytes4);

  // @dev: Grants `role` to `account`
  // @param role: Bytes4 of a role
  // @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external;

  // @dev: Revokes `role` from `account`
  // @param role: Bytes4 of a role
  // @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external;

  // @dev: Renounces `role` from `account`
  // @param role: Bytes4 of a role
  // @param account: account to renounce role from
  function renounceRole(
    bytes4 role
  ) external;
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IOwnerV2.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Interface V2 for onlyOwner() role, suggested by Auditors...
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./IOwner.sol";

interface IOwnerV2 is IOwner {

  // @dev: This accepts the push-pull method of onlyOwner()
  function acceptOwnership()
    external;

  // @dev: This declines the push-pull method of onlyOwner()
  function declineOwnership()
    external;

  // @dev: This starts the push-pull method of onlyOwner()
  // @param newOwner: addres of new pending owner role
  function pushOwnership(
    address newOwner
  ) external;
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#* 
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=: 
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%* 
 *
 * @title: IOwner.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Interface for onlyOwner() role
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IOwner is IERC165 {

  // @dev: Classic "EIP-173" getter for owner()
  // @return: owner of contract
  function owner()
    external
    view
    returns (address);

  // @dev: This is the classic "EIP-173" method of setting onlyOwner()  
  function renounceOwnership()
    external;


  // @dev: This is the classic "EIP-173" method of setting onlyOwner()
  // @param newOwner: addres of new pending owner role
  function transferOwnership(
    address newOwner
  ) external;
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IDeveloperV2.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Interface V2 for onlyDev() role, suggested by Auditors...
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./IDeveloper.sol";

interface IDeveloperV2 is IDeveloper {

  // @dev: This accepts the push-pull method of onlyDev()
  function acceptDeveloper()
    external;

  // @dev: This declines the push-pull method of onlyDev()
  function declineDeveloper()
    external;

  // @dev: This starts the push-pull method of onlyDev()
  // @param newDeveloper: addres of new pending developer role
  function pushDeveloper(
    address newDeveloper
  ) external;
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#* 
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=: 
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%* 
 *
 * @title: IDeveloper.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Interface for onlyDev() role
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IDeveloper is IERC165 {


  // @dev: Classic "EIP-173" but for onlyDev()
  // @return: Developer of contract
  function developer()
    external
    view
    returns (address);

  // @dev: This renounces your role as onlyDev()
  function renounceDeveloper()
    external;

  // @dev: Classic "EIP-173" but for onlyDev()
  // @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}