// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IZkpVerifier {
    function verifyRaw(bytes calldata proofData) external view returns (bool r);
}

// SPDX-License-Identifier: AML

pragma solidity ^0.8.0;

import "./Pairing.sol";

library Common {
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        // []G1Point IC (K in gnark) appears directly in verifyProof
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
        Pairing.G1Point Commit;
    }

    // accumulate scalarMul(mul_input) into q
    // that is computes sets q = (mul_input[0:2] * mul_input[3]) + q
    function accumulate(
        uint256[3] memory mul_input,
        Pairing.G1Point memory p,
        uint256[4] memory buffer,
        Pairing.G1Point memory q
    ) internal view {
        // computes p = mul_input[0:2] * mul_input[3]
        Pairing.scalar_mul_raw(mul_input, p);

        // point addition inputs
        buffer[0] = q.X;
        buffer[1] = q.Y;
        buffer[2] = p.X;
        buffer[3] = p.Y;

        // q = p + q
        Pairing.plus_raw(buffer, q);
    }
}

// SPDX-License-Identifier: AML

pragma solidity ^0.8.0;

uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * Same as plus but accepts raw input instead of struct
     * @return The sum of two points of G1, one is represented as array
     */
    function plus_raw(uint256[4] memory input, G1Point memory r) internal view {
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-mul-failed");
    }

    /*
     * Same as scalar_mul but accepts raw input instead of struct,
     * Which avoid extra allocation. provided input can be allocated outside and re-used multiple times
     */
    function scalar_mul_raw(uint256[3] memory input, G1Point memory r) internal view {
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-opcode-failed");

        return out[0] != 0;
    }
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

import "../interfaces/IZkpVerifier.sol";

import "./common/Pairing.sol";
import "./common/Constants.sol";
import "./common/Common.sol";

pragma solidity ^0.8.0;

contract EthChunkOf128Verifier is IZkpVerifier {
    using Pairing for *;

    function verifyingKey() internal pure returns (Common.VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            uint256(3731296059100206882180451755503172983109296248442025944723039592906698751900),
            uint256(259282599373131156598819103264659325586675381205265829375869139666859279077)
        );
        vk.beta2 = Pairing.G2Point(
            [
                uint256(1542547783169253521197735286554664372551314003473574629092788070944269927009),
                uint256(3442843350567772397992411822441194496033000804528083490373991767861898380921)
            ],
            [
                uint256(548716800731408953921339589333269049204399133705913270541257072650667905637),
                uint256(19884421027672845815718445738066364430735990147602958067065404264457524686219)
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                uint256(11891988479373600508373950254994848776611254114498681881881793265865565715386),
                uint256(19931296744367177659683198721889325174160042107805115279855692658605438538701)
            ],
            [
                uint256(16677912734950263118736987260922842186425341971840174170121099525719169899146),
                uint256(7417603967557513391474517980599665601132457400115579956964885296221617800673)
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                uint256(16517284527623427684849545816824631314997223078114802689115370057079771769284),
                uint256(9556334973004218826551566300456739568039857994289235505930178517047984960309)
            ],
            [
                uint256(11378844714980444222011796238800318515164232281952868936120207698945684705011),
                uint256(16717114042048232586709438632101306668327363244916399631576013967002311482733)
            ]
        );
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory commit,
        uint256[8] memory input
    ) public view returns (bool r) {
        Common.Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.Commit = Pairing.G1Point(commit[0], commit[1]);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-gte-snark-scalar-field");
        }

        Common.VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Buffer reused for addition p1 + p2 to avoid memory allocations
        // [0:2] -> p1.X, p1.Y ; [2:4] -> p2.X, p2.Y
        uint256[4] memory add_input;

        // Buffer reused for multiplication p1 * s
        // [0:2] -> p1.X, p1.Y ; [3] -> s
        uint256[3] memory mul_input;

        // temporary point to avoid extra allocations in accumulate
        Pairing.G1Point memory q = Pairing.G1Point(0, 0);

        vk_x.X = uint256(20771483654708554343899445707962704346619674363636303975277986884195939178109); // vk.K[0].X
        vk_x.Y = uint256(7136981524249642767758675836778771393360023884114860800337043409235713151709); // vk.K[0].Y
        mul_input[0] = uint256(19233685918932192923050625893183018999852678211997471298974889334412747883339); // vk.K[1].X
        mul_input[1] = uint256(10573418048246313728599286941747928760901755928929380194465994346023631757706); // vk.K[1].Y
        mul_input[2] = input[0];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[1] * input[0]
        mul_input[0] = uint256(14573802110847817293393990384189386188819275610796892844002198465549922624165); // vk.K[2].X
        mul_input[1] = uint256(6366177769334632983948241800448594297640371227299129420889272762628401203322); // vk.K[2].Y
        mul_input[2] = input[1];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[2] * input[1]
        mul_input[0] = uint256(4423470128720469023828937120320047480914076991874402659152085174133214111513); // vk.K[3].X
        mul_input[1] = uint256(16661537357790150960310016685835020561095798528309478888052879927100385369883); // vk.K[3].Y
        mul_input[2] = input[2];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[3] * input[2]
        mul_input[0] = uint256(20954264198739863123465273905250064029734563486205900387553306667464142762653); // vk.K[4].X
        mul_input[1] = uint256(15400479026677042446536213348710994852526762940505119021682575524837659837800); // vk.K[4].Y
        mul_input[2] = input[3];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[4] * input[3]
        mul_input[0] = uint256(0); // vk.K[5].X
        mul_input[1] = uint256(0); // vk.K[5].Y
        mul_input[2] = input[4];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[5] * input[4]
        mul_input[0] = uint256(0); // vk.K[6].X
        mul_input[1] = uint256(0); // vk.K[6].Y
        mul_input[2] = input[5];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[6] * input[5]
        mul_input[0] = uint256(15581619746676589215919086055186955357437498065118852273796328444039455983836); // vk.K[7].X
        mul_input[1] = uint256(2079225735174412294634686160304546497644529522569168218992038814057683036684); // vk.K[7].Y
        mul_input[2] = input[6];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[7] * input[6]
        mul_input[0] = uint256(5271944653916881751571075049622758937543583004433508630909066776841583056730); // vk.K[8].X
        mul_input[1] = uint256(5018511801199739199792530205278441732520613352432208789698314328778478334533); // vk.K[8].Y
        mul_input[2] = input[7];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[8] * input[7]
        if (commit[0] != 0 || commit[1] != 0) {
            vk_x = Pairing.plus(vk_x, proof.Commit);
        }

        return
            Pairing.pairing(Pairing.negate(proof.A), proof.B, vk.alfa1, vk.beta2, vk_x, vk.gamma2, proof.C, vk.delta2);
    }

    function verifyRaw(bytes calldata proofData) external view returns (bool) {
        uint256[2] memory a;
        a[0] = uint256(bytes32(proofData[:32]));
        a[1] = uint256(bytes32(proofData[32:64]));
        uint256[2][2] memory b;
        b[0][0] = uint256(bytes32(proofData[64:96]));
        b[0][1] = uint256(bytes32(proofData[96:128]));
        b[1][0] = uint256(bytes32(proofData[128:160]));
        b[1][1] = uint256(bytes32(proofData[160:192]));
        uint256[2] memory c;
        c[0] = uint256(bytes32(proofData[192:224]));
        c[1] = uint256(bytes32(proofData[224:256]));
        uint256[2] memory commit;
        commit[0] = uint256(bytes32(proofData[256:288]));
        commit[1] = uint256(bytes32(proofData[288:320]));
        uint256[8] memory input;
        input[0] = uint256(bytes32(proofData[320:352]));
        input[1] = uint256(bytes32(proofData[352:384]));
        input[2] = uint256(bytes32(proofData[384:416]));
        input[3] = uint256(bytes32(proofData[416:448]));
        input[4] = uint256(bytes32(proofData[448:480]));
        input[5] = uint256(bytes32(proofData[480:512]));
        input[6] = uint256(bytes32(proofData[512:544]));
        input[7] = uint256(bytes32(proofData[544:576]));

        return verifyProof(a, b, c, commit, input);
    }
}