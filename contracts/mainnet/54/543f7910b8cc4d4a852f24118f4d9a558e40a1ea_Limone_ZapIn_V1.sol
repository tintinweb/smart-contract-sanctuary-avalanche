/**
 *Submitted for verification at snowtrace.io on 2022-06-11
*/

///@author Zapper
///@notice This contract adds liquidity to TraderJoe pools on Avalanche using AVAX or any ERC20 Tokens.
// SPDX-License-Identifier: GPL-2.0 AND MIT


pragma solidity ^0.8.0;

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(
                newOwner != address(0) || renounce,
                "Ownable: zero address"
            );

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(
            msg.sender == _pendingOwner,
            "Ownable: caller != pending owner"
        );

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_SYMBOL)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_NAME)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_DECIMALS)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to)
        internal
        view
        returns (uint256 amount)
    {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_BALANCE_OF, to)
        );
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: Transfer failed"
        );
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: TransferFrom failed"
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );

        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: Approve failed"
        );
    }
}

abstract contract ZapBaseV2_1 is BoringOwnable {
    using BoringERC20 for IERC20;
    bool public stopped = false;

    // swapTarget => approval status
    mapping(address => bool) public approvedTargets;

    // circuit breaker modifiers
    modifier stopInEmergency() {
        if (stopped) {
            revert("Paused");
        } else {
            _;
        }
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}

// File contracts/_base/ZapInBaseV3_1.sol

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

/// @author Zapper
/// @notice This abstract contract provides utility functions for moving tokens.

pragma solidity ^0.8.0;

abstract contract ZapInBaseV3_1 is ZapBaseV2_1 {
    using BoringERC20 for IERC20;

    /**
    @dev Transfer tokens (including ETH) from msg.sender to this contract
    @param token The ERC20 token to transfer to this contract (0 address if ETH)
    @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(address token, uint256 amount, bool directLP)
        internal
        returns (uint256)
    {
        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");
            return msg.value;
        }

        require(amount > 0, "Invalid token amount");
        if (!directLP) require(msg.value == 0, "Eth sent with token");

        //transfer token

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        return amount;
    }
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

interface IBentoBoxV1 {
    function toAmount(
        address _token,
        uint256 _share,
        bool _roundUp
    ) external view returns (uint256);

    function withdraw(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deposit(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address cloneAddress);

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function balanceOf(IERC20, address) external view returns (uint256);

    function totals(IERC20) external view returns (uint256 elastic, uint256 base);

    function flashLoan(
        address borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);
}

contract Limone_ZapIn_V1 is ZapInBaseV3_1 {
    using BoringERC20 for IERC20;

    mapping(IBentoBoxV1 => bool) public allowedBoxes;

    IUniswapV2Factory private constant joeFactory =
        IUniswapV2Factory(0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10);

    IUniswapV2Router02 private constant joeRouter =
        IUniswapV2Router02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    address private constant wavaxTokenAddress =
        address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    address immutable DAO;

    struct Cache {
        uint256 initialBalance;
        uint256 balanceAfter;
        uint256 toInvest;
    }

    constructor(address _DAO) {
        DAO = _DAO;
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;

        //allowedBoxes
        allowedBoxes[IBentoBoxV1(0xf4F46382C2bE1603Dc817551Ff9A7b333Ed1D18f)] = true;
        allowedBoxes[IBentoBoxV1(0x1fC83f75499b7620d53757f0b01E2ae626aAE530)] = true;
    }

    event zapIn(address sender, address receiver, address pool, uint256 tokensRec);

    function allowBox(address bentoBox) external onlyOwner
    {
        require(bentoBox != address(0), "BNA");
        allowedBoxes[IBentoBoxV1(bentoBox)] = true;
    }

    function forbidBox(address bentoBox) external onlyOwner {
        require(bentoBox != address(0), "BNA");
        allowedBoxes[IBentoBoxV1(bentoBox)] = false;
    }

    /**
    @notice Add liquidity to Quickswap pools with ETH/ERC20 Tokens
    @param _fromToken The ERC20 token used (address(0x00) if ether)
    @param _bentoBox BentoBox or DegenBox deposit to
    @param _pairAddress JoePair address in which liquidity putted
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param _swapTarget Excecution target for the first swap
    @return Amount of LP bought
     */
    function ZapIn(
        address _fromToken,
        IBentoBoxV1 _bentoBox,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address _to
    ) external payable stopInEmergency returns (uint256) {
        require(allowedBoxes[_bentoBox], "BNA");
        Cache memory cache;
        cache.toInvest = _pullTokens(_fromToken, _amount, false);

        cache.initialBalance = _fromToken == address(0)
            ? address(this).balance
            : IERC20(_fromToken).safeBalanceOf(address(this));

        uint256 LPBought = _performZapIn(
            _fromToken,
            _pairAddress,
            cache.toInvest,
            _swapTarget,
            swapData
        );
        cache.balanceAfter = _fromToken == address(0)
            ? IERC20(wavaxTokenAddress).safeBalanceOf(address(this))
            : IERC20(_fromToken).safeBalanceOf(address(this));
        require(
            (cache.initialBalance - cache.toInvest) == cache.balanceAfter,
            "Not all tokens used"
        );
        require(LPBought >= _minPoolTokens, "High Slippage");

        _approveToken(
            _pairAddress,
            address(_bentoBox),
            LPBought
        );
        _bentoBox.deposit(IERC20(_pairAddress), address(this), _to, LPBought, 0);

        emit zapIn(msg.sender, _to, _pairAddress, LPBought);

        return LPBought;
    }

    function performLpToBox(
        IBentoBoxV1 _bentoBox,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 _minPoolTokens,
        address _to
    ) external payable stopInEmergency returns (uint256) {
         require(allowedBoxes[_bentoBox], "BNA");

        uint toInvest0 = _pullTokens(_ToUnipoolToken0, token0Amount, true);
        uint toInvest1 = _pullTokens(_ToUnipoolToken1, token1Amount, true);

        if (_ToUnipoolToken0 == address(0)) {
            IWETH(wavaxTokenAddress).deposit{value: toInvest0}();
            _ToUnipoolToken0 = wavaxTokenAddress;
        }
        if (_ToUnipoolToken1 == address(0)) {
            IWETH(wavaxTokenAddress).deposit{value: toInvest1}();
            _ToUnipoolToken1 = wavaxTokenAddress;
        }

        uint256 LPBought = _uniDeposit(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                toInvest0,
                toInvest1,
                true
            );

        require(LPBought >= _minPoolTokens, "High Slippage");

        address pair = joeFactory.getPair(_ToUnipoolToken0, _ToUnipoolToken1);
         _approveToken(
            pair,
            address(_bentoBox),
            LPBought
        );

        _bentoBox.deposit(IERC20(pair), address(this), _to, LPBought, 0);

        emit zapIn(msg.sender, _to, pair, LPBought);

        return LPBought;
    }

    function _getPairTokens(address _pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToUniswapToken0, address _ToUniswapToken1) = _getPairTokens(
            _pairAddress
        );

        if (
            _FromTokenContractAddress != _ToUniswapToken0 &&
            _FromTokenContractAddress != _ToUniswapToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                _FromTokenContractAddress,
                _pairAddress,
                _amount,
                _swapTarget,
                swapData
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) = _swapIntermediate(
            intermediateToken,
            _ToUniswapToken0,
            _ToUniswapToken1,
            intermediateAmt
        );

        return
            _uniDeposit(
                _ToUniswapToken0,
                _ToUniswapToken1,
                token0Bought,
                token1Bought,
                true
            );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(_ToUnipoolToken0, address(joeRouter), token0Bought);
        _approveToken(_ToUnipoolToken1, address(joeRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) = joeRouter.addLiquidity(
            _ToUnipoolToken0,
            _ToUnipoolToken1,
            token0Bought,
            token1Bought,
            1,
            1,
            address(this),
            deadline
        );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought - amountA > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought - amountA
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought - amountB > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought - amountB
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        if (_swapTarget == wavaxTokenAddress) {
            IWETH(wavaxTokenAddress).deposit{value: _amount}();
            return (_amount, wavaxTokenAddress);
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        (address _token0, address _token1) = _getPairTokens(_pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{value: valueToSend}(swapData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 = token0.balanceOf(address(this)) -
            initialBalance0;
        uint256 finalBalance1 = token1.balanceOf(address(this)) -
            initialBalance1;

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            joeFactory.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
        );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(joeRouter),
            tokens2Trade
        );

        address pair = joeFactory.getPair(
            _FromTokenContractAddress,
            _ToTokenContractAddress
        );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = joeRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }

    /**
     *  @notice allow owner to send lost tokens to the DAO
     *  @return bool
     */
    function recoverLostToken(address _token)
        external
        onlyOwner
        returns (bool)
    {
        IERC20(_token).safeTransfer(
            DAO,
            IERC20(_token).balanceOf(address(this))
        );
        return true;
    }

    function refundETH() external onlyOwner {
        if (address(this).balance > 0) {
            (bool success, ) = DAO.call{value: address(this).balance}(
                new bytes(0)
            );
            require(success, "STE");
        }
    }
}