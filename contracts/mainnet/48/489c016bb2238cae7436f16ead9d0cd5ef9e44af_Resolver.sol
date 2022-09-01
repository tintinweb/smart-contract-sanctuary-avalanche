/**
 *Submitted for verification at snowtrace.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@

interface IResolver {
    /// ENUMS ///

    enum PaymentToken {
        SENTINEL,
        WETH,
        DAI,
        USDC,
        USDT,
        TUSD,
        RENT
    }

    /// CONSTANT FUNCTIONS ///

    function getPaymentToken(PaymentToken paymentToken) external view returns (address);

    /// NON-CONSTANT FUNCTIONS ///

    function setPaymentToken(uint8 paymentToken, address value) external;
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * Resolver: IResolver.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@

error CannotResetAddress();

error NotAllowed();

error CannotSetSentinel();

contract Resolver is IResolver {
    address private immutable admin;
    address private immutable deployer;
    mapping(uint8 => address) private addresses;

    constructor(address newAdmin) {
        admin = newAdmin;
        deployer = msg.sender;
    }

    function getPaymentToken(PaymentToken paymentToken) external view override returns (address) {
        return addresses[uint8(paymentToken)];
    }

    function setPaymentToken(uint8 paymentToken, address paymentTokenAddress) external override {
        if (paymentToken == 0) {
            revert CannotSetSentinel();
        }
        if (addresses[paymentToken] != address(0)) {
            revert CannotResetAddress();
        }
        if (msg.sender != admin && msg.sender != deployer) {
            revert NotAllowed();
        }
        addresses[paymentToken] = paymentTokenAddress;
    }
}