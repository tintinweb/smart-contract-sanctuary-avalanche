/**
 *Submitted for verification at snowtrace.io on 2022-02-25
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/cashbag_verifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0 AND BSD-4-Clause AND UNLICENSED
pragma solidity ^0.8.9;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            7467796778264498634631944894706172448990409983329037625491375180910931874265,
            16605418660745546860601641505967473285827601288402912188681192516392226764774
        );

        vk.beta2 = Pairing.G2Point(
            [521290181315496077321720146591963896821216009977085516909349257794111097074,
             14016180290301960662739883067232247011443258100905725730063942714139098341106],
            [13413489582234934896651061027481515272410877876531989178187139833498165014677,
             7497322429734100271594698248430046412988693656255501580060443636306107231043]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [13620227423858030106968884443782349401387618267395765438554944172976126554140,
             18383875736701370454503047127780090903004221441279044996096231572647308727977],
            [10731238774937577478441093350495318258269114178190434410158271624310097554404,
             811359493436801780647031752691811982908063981760702476761830738381829517280]
        );
        vk.IC = new Pairing.G1Point[](4);
        
        vk.IC[0] = Pairing.G1Point( 
            21380625667200387528401129494482519663690443407178035735613871875914461254980,
            16493919322223292842377930174482141353320302353444594004620314121253752619386
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            11038973125721914099800221906018918348960416730007261309079075397778347451981,
            9005473273089848277684595323664681654388658103149161233613526643769785570927
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            628896472802401632616699392795734814326511455056714619270984877917538731001,
            8559617517996988313301771792829922924409262956417953005579902261434141099708
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            14045438792201697807793452729889490184571621721716852148191971702300426958079,
            6101361649744643088351328445551466940771106232545048972570850120315102331200
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[3] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}


// File contracts/ABDKMath64x64.sol

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt(int256 x) internal pure returns (int128) {
    unchecked {
      require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128(x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt(int128 x) internal pure returns (int64) {
    unchecked {
      return int64(x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt(uint256 x) internal pure returns (int128) {
    unchecked {
      require(x <= 0x7FFFFFFFFFFFFFFF);
      return int128(int256(x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt(int128 x) internal pure returns (uint64) {
    unchecked {
      require(x >= 0);
      return uint64(uint128(x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128(int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128(int128 x) internal pure returns (int256) {
    unchecked {
      return int256(x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = (int256(x) * y) >> 64;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli(int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require(
          y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
            y <= 0x1000000000000000000000000000000000000000000000000
        );
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu(x, uint256(y));
        if (negativeResult) {
          require(
            absoluteResult <=
              0x8000000000000000000000000000000000000000000000000000000000000000
          );
          return -int256(absoluteResult); // We rely on overflow behavior here
        } else {
          require(
            absoluteResult <=
              0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          );
          return int256(absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu(int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require(x >= 0);

      uint256 lo = (uint256(int256(x)) *
        (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256(int256(x)) * (y >> 128);

      require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require(
        hi <=
          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
            lo
      );
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require(y != 0);
      int256 result = (int256(x) << 64) / y;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi(int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require(y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu(uint256(x), uint256(y));
      if (negativeResult) {
        require(absoluteResult <= 0x80000000000000000000000000000000);
        return -int128(absoluteResult); // We rely on overflow behavior here
      } else {
        require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128(absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu(uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require(y != 0);
      uint128 result = divuu(x, y);
      require(result <= uint128(MAX_64x64));
      return int128(result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg(int128 x) internal pure returns (int128) {
    unchecked {
      require(x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs(int128 x) internal pure returns (int128) {
    unchecked {
      require(x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv(int128 x) internal pure returns (int128) {
    unchecked {
      require(x != 0);
      int256 result = int256(0x100000000000000000000000000000000) / x;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128((int256(x) + int256(y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256(x) * int256(y);
      require(m >= 0);
      require(
        m < 0x4000000000000000000000000000000000000000000000000000000000000000
      );
      return int128(sqrtu(uint256(m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow(int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128(x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = (absResult * absX) >> 127;
          }
          absX = (absX * absX) >> 127;

          if (y & 0x2 != 0) {
            absResult = (absResult * absX) >> 127;
          }
          absX = (absX * absX) >> 127;

          if (y & 0x4 != 0) {
            absResult = (absResult * absX) >> 127;
          }
          absX = (absX * absX) >> 127;

          if (y & 0x8 != 0) {
            absResult = (absResult * absX) >> 127;
          }
          absX = (absX * absX) >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) {
          absX <<= 32;
          absXShift -= 32;
        }
        if (absX < 0x10000000000000000000000000000) {
          absX <<= 16;
          absXShift -= 16;
        }
        if (absX < 0x1000000000000000000000000000000) {
          absX <<= 8;
          absXShift -= 8;
        }
        if (absX < 0x10000000000000000000000000000000) {
          absX <<= 4;
          absXShift -= 4;
        }
        if (absX < 0x40000000000000000000000000000000) {
          absX <<= 2;
          absXShift -= 2;
        }
        if (absX < 0x80000000000000000000000000000000) {
          absX <<= 1;
          absXShift -= 1;
        }

        uint256 resultShift = 0;
        while (y != 0) {
          require(absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = (absResult * absX) >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = (absX * absX) >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
            absX >>= 1;
            absXShift += 1;
          }

          y >>= 1;
        }

        require(resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256(absResult) : int256(absResult);
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt(int128 x) internal pure returns (int128) {
    unchecked {
      require(x >= 0);
      return int128(sqrtu(uint256(int256(x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2(int128 x) internal pure returns (int128) {
    unchecked {
      require(x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) {
        xc >>= 64;
        msb += 64;
      }
      if (xc >= 0x100000000) {
        xc >>= 32;
        msb += 32;
      }
      if (xc >= 0x10000) {
        xc >>= 16;
        msb += 16;
      }
      if (xc >= 0x100) {
        xc >>= 8;
        msb += 8;
      }
      if (xc >= 0x10) {
        xc >>= 4;
        msb += 4;
      }
      if (xc >= 0x4) {
        xc >>= 2;
        msb += 2;
      }
      if (xc >= 0x2) msb += 1; // No need to shift xc anymore

      int256 result = (msb - 64) << 64;
      uint256 ux = uint256(int256(x)) << uint256(127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256(b);
      }

      return int128(result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln(int128 x) internal pure returns (int128) {
    unchecked {
      require(x > 0);

      return
        int128(
          int256(
            (uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >>
              128
          )
        );
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2(int128 x) internal pure returns (int128) {
    unchecked {
      require(x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
      if (x & 0x4000000000000000 > 0)
        result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
      if (x & 0x2000000000000000 > 0)
        result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
      if (x & 0x1000000000000000 > 0)
        result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
      if (x & 0x800000000000000 > 0)
        result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
      if (x & 0x400000000000000 > 0)
        result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
      if (x & 0x200000000000000 > 0)
        result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
      if (x & 0x100000000000000 > 0)
        result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
      if (x & 0x80000000000000 > 0)
        result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
      if (x & 0x40000000000000 > 0)
        result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
      if (x & 0x20000000000000 > 0)
        result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
      if (x & 0x10000000000000 > 0)
        result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
      if (x & 0x8000000000000 > 0)
        result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
      if (x & 0x4000000000000 > 0)
        result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
      if (x & 0x2000000000000 > 0)
        result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
      if (x & 0x1000000000000 > 0)
        result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
      if (x & 0x800000000000 > 0)
        result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
      if (x & 0x400000000000 > 0)
        result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
      if (x & 0x200000000000 > 0)
        result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
      if (x & 0x100000000000 > 0)
        result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
      if (x & 0x80000000000 > 0)
        result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
      if (x & 0x40000000000 > 0)
        result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
      if (x & 0x20000000000 > 0)
        result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
      if (x & 0x10000000000 > 0)
        result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
      if (x & 0x8000000000 > 0)
        result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
      if (x & 0x4000000000 > 0)
        result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
      if (x & 0x2000000000 > 0)
        result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
      if (x & 0x1000000000 > 0)
        result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
      if (x & 0x800000000 > 0)
        result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
      if (x & 0x400000000 > 0)
        result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
      if (x & 0x200000000 > 0)
        result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
      if (x & 0x100000000 > 0)
        result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
      if (x & 0x80000000 > 0)
        result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
      if (x & 0x40000000 > 0)
        result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
      if (x & 0x20000000 > 0)
        result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
      if (x & 0x10000000 > 0)
        result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
      if (x & 0x8000000 > 0)
        result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
      if (x & 0x4000000 > 0)
        result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
      if (x & 0x2000000 > 0)
        result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
      if (x & 0x1000000 > 0)
        result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
      if (x & 0x800000 > 0)
        result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
      if (x & 0x400000 > 0)
        result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
      if (x & 0x200000 > 0)
        result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
      if (x & 0x100000 > 0)
        result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
      if (x & 0x80000 > 0)
        result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
      if (x & 0x40000 > 0)
        result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
      if (x & 0x20000 > 0)
        result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
      if (x & 0x10000 > 0)
        result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
      if (x & 0x8000 > 0)
        result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
      if (x & 0x4000 > 0)
        result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
      if (x & 0x2000 > 0)
        result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
      if (x & 0x1000 > 0)
        result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
      if (x & 0x800 > 0)
        result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
      if (x & 0x400 > 0)
        result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
      if (x & 0x200 > 0)
        result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
      if (x & 0x100 > 0)
        result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
      if (x & 0x80 > 0)
        result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
      if (x & 0x40 > 0)
        result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
      if (x & 0x20 > 0)
        result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
      if (x & 0x10 > 0)
        result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
      if (x & 0x8 > 0)
        result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
      if (x & 0x4 > 0)
        result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
      if (x & 0x2 > 0)
        result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
      if (x & 0x1 > 0)
        result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

      result >>= uint256(int256(63 - (x >> 64)));
      require(result <= uint256(int256(MAX_64x64)));

      return int128(int256(result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp(int128 x) internal pure returns (int128) {
    unchecked {
      require(x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return
        exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu(uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require(y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) {
          xc >>= 32;
          msb += 32;
        }
        if (xc >= 0x10000) {
          xc >>= 16;
          msb += 16;
        }
        if (xc >= 0x100) {
          xc >>= 8;
          msb += 8;
        }
        if (xc >= 0x10) {
          xc >>= 4;
          msb += 4;
        }
        if (xc >= 0x4) {
          xc >>= 2;
          msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert(xh == hi >> 128);

        result += xl / y;
      }

      require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128(result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu(uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
          xx >>= 128;
          r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
          xx >>= 64;
          r <<= 32;
        }
        if (xx >= 0x100000000) {
          xx >>= 32;
          r <<= 16;
        }
        if (xx >= 0x10000) {
          xx >>= 16;
          r <<= 8;
        }
        if (xx >= 0x100) {
          xx >>= 8;
          r <<= 4;
        }
        if (xx >= 0x10) {
          xx >>= 4;
          r <<= 2;
        }
        if (xx >= 0x8) {
          r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128(r < r1 ? r : r1);
      }
    }
  }
}


// File contracts/CashbagManager.sol

pragma solidity ^0.8.9;


// import '../node_modules/hardhat/console.sol';

// TODO: Add support for cashbags with more than 9 AVAX.
// It's a limitation of ABDKMath64x64 float point numbers we use for randomization calculations.

contract CashbagManager is Verifier {
  using ABDKMath64x64 for int128;

  enum CashbagPhase {
    Open,
    Finished
  }
  enum ParticipantStatus {
    NotClaimed,
    Claimed
  }

  struct Cashbag {
    // Cashbag owner address
    address owner;
    // Starting amount of cash for grabs, in wei
    uint256 startingCash;
    // Amount of cash for grabs, in wei
    uint256 cash;
    // Min payout amount per claim
    uint256 minPayoutAmount;
    // Timestamp UNIX, when claim period is over
    uint256 claimPeriodOver;
    // Max number of participants
    uint128 maxParticipants;
    // Password hash is computed via zksnark circuit.
    uint96 salt;
    uint256 passwordHash;
    // List of participant addresses
    address[] participantAddresses;
    // List of participant payout amounts
    uint256[] participantPayouts;
    // Precomputed payout amounts that have not been claimed yet
    uint256[] remainingPayoutAmounts;
  }

  struct Participant {
    ParticipantStatus status;
  }

  /* ========== STATE VARIABLES ========== */

  // [cashbagId] => cashbag
  Cashbag[] public cashbags;
  address private owner;
  uint256 private commissionFeeBalance = 0;

  // [cashbagId][participantAddress] => Participant
  mapping(uint256 => mapping(address => Participant))
    public cashbagParticipants;

  /* ========== CONSTRUCTOR ========== */

  constructor() {
    owner = msg.sender;
  }

  /* ========== VIEWS ========== */

  /**
   * Gets cashbag via id
   */
  function getCashbag(uint256 _cashBagId)
    external
    view
    returns (Cashbag memory)
  {
    require(_cashBagId < cashbags.length, 'Cashbag ID out of bounds');
    return cashbags[_cashBagId];
  }

  function isFinished(uint256 _cashbagId) external view returns (bool) {
    CashbagPhase phase = _getCurrentPhase(_cashbagId);
    return phase == CashbagPhase.Finished;
  }

  /**
   * Get payout mount claimed by the caller.
   */
  function getPayoutTakenAmount(uint256 _cashbagId)
    external
    view
    returns (uint256)
  {
    Participant memory participant = cashbagParticipants[_cashbagId][
      msg.sender
    ];

    if (participant.status != ParticipantStatus.Claimed) {
      return 0;
    }

    Cashbag storage cashbag = cashbags[_cashbagId];

    for (uint256 i = 0; i < cashbag.participantAddresses.length; i++) {
      if (cashbag.participantAddresses[i] != msg.sender) continue;
      return cashbag.participantPayouts[i];
    }
    return 0;
  }

  function getOwnerCashbags()
    external
    view
    returns (
      Cashbag[] memory,
      uint256[] memory,
      uint256
    )
  {
    Cashbag[] memory ownerCashbags = new Cashbag[](cashbags.length);
    uint256[] memory ownerCashbagsIds = new uint256[](cashbags.length);
    uint256 numOwnerCashbags = 0;

    for (uint256 i = 0; i < cashbags.length; i++) {
      if (cashbags[i].owner == msg.sender) {
        ownerCashbags[numOwnerCashbags] = cashbags[i];
        ownerCashbagsIds[numOwnerCashbags] = i;
        numOwnerCashbags++;
      }
    }
    return (ownerCashbags, ownerCashbagsIds, numOwnerCashbags);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function createCashbag(
    uint64 _maxParticipants,
    uint96 _salt,
    uint256 _passwordHash,
    uint256 _claimPeriod,
    uint256 _minPayoutAmount
  ) external payable {
    require(_maxParticipants > 0, 'Need to have at least one participant');
    require(
      msg.value >= _minPayoutAmount * _maxParticipants,
      'Not enough cash to send min payouts'
    );
    require(msg.value <= 0x7FFFFFFFFFFFFFFF, 'no more that 9 AVAX allowed');

    // 1. Get distributed values.
    int128[] memory distributedValues = new int128[](_maxParticipants);
    // Split distribution interval (0,10) into equal pieces, then feed their
    // mid-points into distribution function to generate desired distribution.
    // splitLength = 10 / _maxParticipants
    int128 splitLength = ABDKMath64x64.fromUInt(10).div(
      ABDKMath64x64.fromUInt(_maxParticipants)
    );
    for (uint256 i = 0; i < _maxParticipants; i++) {
      // x = splitLength / 2 + splitLength * i
      int128 x = splitLength.div(ABDKMath64x64.fromUInt(2)).add(
        splitLength.mul(ABDKMath64x64.fromUInt(i))
      );
      // y = (2^x)/100 + 10
      // @see https://www.wolframalpha.com/input?i=plot+Divide%5BPower%5B2%2Cx%5D%2C100%5D%2B10+from+x%3D0+to+11
      int128 y = ABDKMath64x64.exp_2(x).div(ABDKMath64x64.fromUInt(100)).add(
        ABDKMath64x64.fromUInt(10)
      );
      distributedValues[i] = y;
    }

    // 2. Normalize distributed values to add up to 1,
    // then use to calculate payout amounts.
    int128 distributedValuesSum;
    for (uint256 i = 0; i < _maxParticipants; i++) {
      distributedValuesSum = distributedValuesSum.add(distributedValues[i]);
    }
    uint256[] memory payoutAmounts = new uint256[](_maxParticipants);
    for (uint256 i = 0; i < _maxParticipants; i++) {
      payoutAmounts[i] =
        // fixed payout amount
        _minPayoutAmount +
        // variable payout amount
        ABDKMath64x64
          .fromUInt(
            // total variable payout amount
            msg.value - (_minPayoutAmount * _maxParticipants)
          )
          .mul(distributedValues[i].div(distributedValuesSum))
          .toUInt();
    }

    Cashbag memory cashbag;
    cashbag.owner = msg.sender;
    cashbag.maxParticipants = _maxParticipants;
    cashbag.cash = msg.value;
    cashbag.startingCash = msg.value;
    cashbag.salt = _salt;
    cashbag.claimPeriodOver = block.timestamp + _claimPeriod;
    cashbag.passwordHash = _passwordHash;
    cashbag.remainingPayoutAmounts = payoutAmounts;
    cashbags.push(cashbag);

    emit CashbagCreated(cashbags.length - 1, msg.sender);
  }

  function takeFromCashbag(
    uint256 _cashbagId,
    uint256 _passwordHash,
    uint256[2] memory proofA,
    uint256[2][2] memory proofB,
    uint256[2] memory proofC
  ) external payable {
    require(_cashbagId < cashbags.length, 'Cashbag not found');

    Participant storage participant = cashbagParticipants[_cashbagId][
      msg.sender
    ];
    Cashbag storage cashbag = cashbags[_cashbagId];

    CashbagPhase currentPhase = _getCurrentPhase(_cashbagId);

    require(
      cashbag.owner != msg.sender,
      'Owner cannot claim their own cashbag'
    );

    require(
      participant.status == ParticipantStatus.NotClaimed,
      'Participant has already claimed this cashbag'
    );
    require(currentPhase == CashbagPhase.Open, 'Cashbag has finished');
    require(_passwordHash == cashbag.passwordHash, 'Password mismatch');
    require(
      verifyProof(
        proofA,
        proofB,
        proofC,
        [
          // Hash has already been verified.
          _passwordHash,
          // Expect the proof to be based on sender address.
          uint256(uint160(address(msg.sender))),
          // Expect the proof to be based on the cashbag salt.
          uint256(cashbag.salt)
        ]
      ),
      'Verification failed'
    );

    // Pick a random payout amount, and mark it as claimed
    uint256 payoutAmount = _claimRandomPayoutAmount(_cashbagId);

    // Mark participant as Claimed
    cashbag.participantAddresses.push(msg.sender);
    participant.status = ParticipantStatus.Claimed;

    // Send payout
    cashbag.cash -= payoutAmount;

    uint256 participantPayoutAmount = (payoutAmount * 999) / 1000;
    uint256 commissionFee = payoutAmount - participantPayoutAmount;
    commissionFeeBalance += commissionFee;

    cashbag.participantPayouts.push(participantPayoutAmount);

    // If it's last participant, take leftover dust as commission fee
    if (cashbag.participantAddresses.length == cashbag.maxParticipants) {
      commissionFeeBalance += cashbag.cash;
      cashbag.cash = 0;
    }

    (bool success, ) = msg.sender.call{value: participantPayoutAmount}('');

    require(success, 'Ether failed to sent');
    emit CashTaken(_cashbagId, participantPayoutAmount, msg.sender);
  }

  /**
   * Withdrawal of commission fee balance for owner
   */
  function withdrawCommissionFee() external isOwner {
    uint256 commissionFee = commissionFeeBalance;
    commissionFeeBalance = 0;
    (bool success, ) = msg.sender.call{value: commissionFee}('');
    require(success, 'Failed to withdraw commission fee');
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
   * Returns current phase (OPEN vs FINISHED) for a given Cashbag ID
   */
  function _getCurrentPhase(uint256 _cashbagId)
    internal
    view
    returns (CashbagPhase)
  {
    require(_cashbagId < cashbags.length, 'Cashbag not found');
    Cashbag storage cashbag = cashbags[_cashbagId];

    bool isParticipantsListNotFull = cashbag.participantAddresses.length <
      cashbag.maxParticipants;
    bool isInClaimPeriod = cashbag.claimPeriodOver >= block.timestamp;

    return
      isParticipantsListNotFull && isInClaimPeriod
        ? CashbagPhase.Open
        : CashbagPhase.Finished;
  }

  /**
   * Pick a random payout amount, and remove it from remaining payout amounts.
   */
  function _claimRandomPayoutAmount(uint256 _cashbagId)
    internal
    returns (uint256)
  {
    uint256[] storage remainingPayoutAmounts = cashbags[_cashbagId]
      .remainingPayoutAmounts;

    uint256 randomInt = uint256(
      keccak256(
        abi.encodePacked(
          block.timestamp,
          blockhash(block.number - 1),
          msg.sender
        )
      )
    );
    uint256 randomPayoutIndex = randomInt % remainingPayoutAmounts.length;

    // Take out the claimed payout and put the last element in its place.
    uint256 payoutAmount = remainingPayoutAmounts[randomPayoutIndex];
    delete remainingPayoutAmounts[randomPayoutIndex];
    remainingPayoutAmounts[randomPayoutIndex] = remainingPayoutAmounts[
      remainingPayoutAmounts.length - 1
    ];
    remainingPayoutAmounts.pop();

    return payoutAmount;
  }

  /* ========== MODIFIERS ========== */

  modifier isOwner() {
    require(owner == msg.sender, 'Only owner can call this function');
    _;
  }

  /* ========== EVENTS ========== */

  event CashbagCreated(uint256 cashbagId, address creatorAddress);
  event CashTaken(
    uint256 cashbagId,
    uint256 payoutAmount,
    address participantAddress
  );
}