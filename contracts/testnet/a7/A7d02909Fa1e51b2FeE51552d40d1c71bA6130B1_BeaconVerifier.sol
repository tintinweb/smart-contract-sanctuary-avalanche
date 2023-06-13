// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./zk-verifiers/BlsSigVerifier.sol";
import "./zk-verifiers/CommitteeRootMappingVerifier.sol";
import "./interfaces/IBeaconVerifier.sol";

contract BeaconVerifier is IBeaconVerifier, BlsSigVerifier, CommitteeRootMappingVerifier {
    function verifySignatureProof(
        bytes32 signingRoot,
        bytes32 syncCommitteePoseidonRoot,
        uint256 participation,
        uint256 commitment,
        Proof memory p
    ) public view returns (bool) {
        uint256[35] memory input;
        uint256 root = uint256(signingRoot);
        // slice the signing root into 32 individual bytes and assign them in order to the first 32 slots of input[]
        for (uint256 i = 0; i < 32; i++) {
            input[(32 - 1 - i)] = root % 256;
            root = root / 256;
        }
        input[32] = participation;
        input[33] = uint256(syncCommitteePoseidonRoot);
        input[34] = commitment;
        return verifyBlsSigProof(p.a, p.b, p.c, p.commitment, input);
    }

    function verifySyncCommitteeRootMappingProof(
        bytes32 sszRoot,
        bytes32 poseidonRoot,
        Proof memory p
    ) public view returns (bool) {
        uint256[33] memory input;
        uint256 root = uint256(sszRoot);
        for (uint256 i = 0; i < 32; i++) {
            input[(32 - 1 - i)] = root % 256;
            root = root / 256;
        }
        input[32] = uint256(poseidonRoot);
        return verifyCommitteeRootMappingProof(p.a, p.b, p.c, input);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBeaconVerifier {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[2] commitment;
    }

    function verifySignatureProof(
        bytes32 signingRoot,
        bytes32 syncCommitteePoseidonRoot,
        uint256 participation,
        uint256 commitment,
        Proof memory p
    ) external view returns (bool);

    function verifySyncCommitteeRootMappingProof(
        bytes32 sszRoot,
        bytes32 poseidonRoot,
        Proof memory p
    ) external view returns (bool);
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

pragma solidity ^0.8.0;

import "./common/Pairing.sol";
import "./common/Constants.sol";
import "./common/Common.sol";

contract BlsSigVerifier {
    using Pairing for *;

    function verifyingKey() internal pure returns (Common.VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            uint256(21869404648590355938070204738007299921184879677994422527706836467860465229555),
            uint256(13498271808119839955057715147407595718888788089303053071109523938531313129416)
        );
        vk.beta2 = Pairing.G2Point(
            [
                uint256(7054962807852101821777521907353900534536574912206623342548135225636684065633),
                uint256(4719416372386397569789716378331929165562736304329438825528404248445356317544)
            ],
            [
                uint256(13169505134780753056527210184700054053183554009975495323937739848223108944491),
                uint256(13592098286878802627104334887812977484641971308142750321766707760557234071693)
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                uint256(11095415866555931179835746321035950972580128700079993342944687987088771893970),
                uint256(7608157602633458693059833022944239778069565713137388978977277542137468568611)
            ],
            [
                uint256(7401180895810745229430756020474788835440387402515164454484661092797156083108),
                uint256(5065358031358114712449190279086624673751222971320486961839316362446988673960)
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                uint256(2222475616788908183739316851660307727267648260775064003405822118215303226516),
                uint256(6757963293650080478631547193181808365039329301693745170213066300772412893432)
            ],
            [
                uint256(16109832433313432721291101899523165130162303404627529133543410010343809968099),
                uint256(10657128623625091271138067059727783952095522932162725865057316893805238179881)
            ]
        );
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyBlsSigProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory commit,
        uint256[35] memory input
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

        vk_x.X = uint256(6164202379403353093337803285728957014471789019875115975131401894724388184318); // vk.K[0].X
        vk_x.Y = uint256(14653739865386807698202111307501669964169649892515646451656712652300441924746); // vk.K[0].Y
        mul_input[0] = uint256(21624815114078889503955414395662096302081445496963466787344578976263660902728); // vk.K[1].X
        mul_input[1] = uint256(11975795059976038387412140269866198306105499844184502711829412068023274602635); // vk.K[1].Y
        mul_input[2] = input[0];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[1] * input[0]
        mul_input[0] = uint256(9775291361201569299414467699407168277620212957980866255045879806029778744670); // vk.K[2].X
        mul_input[1] = uint256(17233924503171010558175232794027883068335710383496735149565234989213088796768); // vk.K[2].Y
        mul_input[2] = input[1];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[2] * input[1]
        mul_input[0] = uint256(8261354145794168978236113350349424817333204461878829563010649753110739562635); // vk.K[3].X
        mul_input[1] = uint256(228648003771409636961945287326030341918541270047335109757141629333782275554); // vk.K[3].Y
        mul_input[2] = input[2];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[3] * input[2]
        mul_input[0] = uint256(17152002075022784984752660010686481854578129701150390242442680875098241592838); // vk.K[4].X
        mul_input[1] = uint256(11918344010421497075133630718996356084858247140809583870914170975825762239902); // vk.K[4].Y
        mul_input[2] = input[3];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[4] * input[3]
        mul_input[0] = uint256(6724640989773315527339379483030265695332390420189583344806142015699008773038); // vk.K[5].X
        mul_input[1] = uint256(861669679975036023917296038423011939661116903611653803520085082890905199789); // vk.K[5].Y
        mul_input[2] = input[4];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[5] * input[4]
        mul_input[0] = uint256(14251387140848206404864695272174413529185588726241264808479413090259577951538); // vk.K[6].X
        mul_input[1] = uint256(4877123074037160235642133175015361159040197060194606461929469075209090452909); // vk.K[6].Y
        mul_input[2] = input[5];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[6] * input[5]
        mul_input[0] = uint256(20478957346453652200579299273452777262775946284794283970558676720582194409443); // vk.K[7].X
        mul_input[1] = uint256(13820772652701693231224118191632029591356297457861304887694791784009996804692); // vk.K[7].Y
        mul_input[2] = input[6];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[7] * input[6]
        mul_input[0] = uint256(9234465648938974703786224967061256507261169398685469391550057760202443899331); // vk.K[8].X
        mul_input[1] = uint256(13214614408686260510380993851179383149022140264065385584700637692530775154803); // vk.K[8].Y
        mul_input[2] = input[7];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[8] * input[7]
        mul_input[0] = uint256(8322398570000964255587165898643030029017010777972305270331988207302834192671); // vk.K[9].X
        mul_input[1] = uint256(2792163176420440857016104913456882943905817335378546111765666996712066935576); // vk.K[9].Y
        mul_input[2] = input[8];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[9] * input[8]
        mul_input[0] = uint256(15797084070376204854261757656819325712271250278301568410976291761898112633721); // vk.K[10].X
        mul_input[1] = uint256(16921845299282876706614570130523339313885521170603933721890067977426560293948); // vk.K[10].Y
        mul_input[2] = input[9];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[10] * input[9]
        mul_input[0] = uint256(406216972217762516055114890594086577323982284148453070046117814489609787072); // vk.K[11].X
        mul_input[1] = uint256(19680277307775257363705979553150354779381952871529724380294836363819544498123); // vk.K[11].Y
        mul_input[2] = input[10];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[11] * input[10]
        mul_input[0] = uint256(12525306314981123491352345009709438907206215415831226491632499998999204127459); // vk.K[12].X
        mul_input[1] = uint256(1658709794415567495634480941878933577381576154054415708255836274811180964933); // vk.K[12].Y
        mul_input[2] = input[11];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[12] * input[11]
        mul_input[0] = uint256(243194178389731910341565843545971823670153019065524768068260919793967722188); // vk.K[13].X
        mul_input[1] = uint256(1539016065323199244386584217201350236710807235938447628544504644138676080000); // vk.K[13].Y
        mul_input[2] = input[12];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[13] * input[12]
        mul_input[0] = uint256(9275972589095639516678595044389709393960973430061520882565539743422692685960); // vk.K[14].X
        mul_input[1] = uint256(4472610206252234523359317365636135395350815197903460649733786399406367486575); // vk.K[14].Y
        mul_input[2] = input[13];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[14] * input[13]
        mul_input[0] = uint256(1604039017774374075569025682010500744317749653925017699242881946260024023542); // vk.K[15].X
        mul_input[1] = uint256(9410905005395438689346852685696727671986553838639094357993770247718588779274); // vk.K[15].Y
        mul_input[2] = input[14];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[15] * input[14]
        mul_input[0] = uint256(5467079506302237253715880360217400787071012184171130827989740479628417662627); // vk.K[16].X
        mul_input[1] = uint256(5224193576447153852009901997143890474156655585587640006673196987947931700778); // vk.K[16].Y
        mul_input[2] = input[15];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[16] * input[15]
        mul_input[0] = uint256(9387444906146485207075936664808214655500107570142417551032840004938425984101); // vk.K[17].X
        mul_input[1] = uint256(590813342019945519768071606508477036322091281941727992935444194199808517685); // vk.K[17].Y
        mul_input[2] = input[16];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[17] * input[16]
        mul_input[0] = uint256(19041927819469860627785730717901058973852083133163312846046958804599105964228); // vk.K[18].X
        mul_input[1] = uint256(8145703607669957376931460933689362105951308370224326599319773750727102492008); // vk.K[18].Y
        mul_input[2] = input[17];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[18] * input[17]
        mul_input[0] = uint256(14204777538249598371293791017226113964614885045747036692434310643177244084169); // vk.K[19].X
        mul_input[1] = uint256(19991551163786857983848828955926174440512514907619539468704022616567132258153); // vk.K[19].Y
        mul_input[2] = input[18];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[19] * input[18]
        mul_input[0] = uint256(12417075001679265443105210537412885798344552810848770848740273623901433226365); // vk.K[20].X
        mul_input[1] = uint256(15254102101044498161161923790765048216173887701468938517549705046497697348129); // vk.K[20].Y
        mul_input[2] = input[19];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[20] * input[19]
        mul_input[0] = uint256(10269550220001463320881104580554222531390353399943986353550597742767825203938); // vk.K[21].X
        mul_input[1] = uint256(3029115017209685411907558073483483867359830128318261715424531870119465329684); // vk.K[21].Y
        mul_input[2] = input[20];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[21] * input[20]
        mul_input[0] = uint256(14428083165341078925702200873211485650187256256509974692495884984971265925464); // vk.K[22].X
        mul_input[1] = uint256(15475503186436372842471391388091832734881597469954031845230603258731548786526); // vk.K[22].Y
        mul_input[2] = input[21];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[22] * input[21]
        mul_input[0] = uint256(21628050343072376849090277477176470142622908553816436115710816402067062636840); // vk.K[23].X
        mul_input[1] = uint256(7029190031936503335713201259562887395453755842232447142827705567066954030015); // vk.K[23].Y
        mul_input[2] = input[22];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[23] * input[22]
        mul_input[0] = uint256(18110637118732954586253866494394595281955623057396063638731715904832753062595); // vk.K[24].X
        mul_input[1] = uint256(10041565796468001571466611556015291077335046776933681659744217988421358102715); // vk.K[24].Y
        mul_input[2] = input[23];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[24] * input[23]
        mul_input[0] = uint256(4394594477670212487624118222291685582484342594449655582983945008137107825); // vk.K[25].X
        mul_input[1] = uint256(12907667141942256119052629834176444916095324468551648766101314800519980891911); // vk.K[25].Y
        mul_input[2] = input[24];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[25] * input[24]
        mul_input[0] = uint256(12264813020217849970868777479799238229912660701320711442659475763187093184540); // vk.K[26].X
        mul_input[1] = uint256(5418405552541349472839540236004659645077530645792067120765938377537697612686); // vk.K[26].Y
        mul_input[2] = input[25];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[26] * input[25]
        mul_input[0] = uint256(511205244113194326604079314682967281483973984567702129900795395158408587823); // vk.K[27].X
        mul_input[1] = uint256(13182904816261728693468832675109011780365501025377828890958755203977021114190); // vk.K[27].Y
        mul_input[2] = input[26];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[27] * input[26]
        mul_input[0] = uint256(7745322370569289256054483431857334835907602968150216319025615839493340926445); // vk.K[28].X
        mul_input[1] = uint256(802527185108559510753348953543835956246583756974633024055374364959752960622); // vk.K[28].Y
        mul_input[2] = input[27];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[28] * input[27]
        mul_input[0] = uint256(6443616155328954964370112634631799535966126116548305083954877582628003863726); // vk.K[29].X
        mul_input[1] = uint256(6748022417080637760377192763249012207074862674787085243054196391894862853769); // vk.K[29].Y
        mul_input[2] = input[28];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[29] * input[28]
        mul_input[0] = uint256(4746053807226732815609107613694422909828283203346089197433464043542316944158); // vk.K[30].X
        mul_input[1] = uint256(568459565911058268471985303141965010407745186442811181897604717750346101795); // vk.K[30].Y
        mul_input[2] = input[29];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[30] * input[29]
        mul_input[0] = uint256(6867388841298402377650181552003032287359815924707163591172560189355289362811); // vk.K[31].X
        mul_input[1] = uint256(12681153196280456072370427543675941721359193477428355329469521843056250842522); // vk.K[31].Y
        mul_input[2] = input[30];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[31] * input[30]
        mul_input[0] = uint256(11834855045548628237299252472287217659541095251983817826749302275066363050032); // vk.K[32].X
        mul_input[1] = uint256(10549551457031005862882545350575007326729695512101543170018470906439946899475); // vk.K[32].Y
        mul_input[2] = input[31];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[32] * input[31]
        mul_input[0] = uint256(21080571058062105169480371434944542317741872583578405624882037076932528614624); // vk.K[33].X
        mul_input[1] = uint256(11386667982944779644843347272450639356560600194842785817671488724791644458315); // vk.K[33].Y
        mul_input[2] = input[32];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[33] * input[32]
        mul_input[0] = uint256(8323118186735247530367920845955364944904052300793452286806441510422146880773); // vk.K[34].X
        mul_input[1] = uint256(7046818066858629220640333055452104424201007141089175803564675939513429614352); // vk.K[34].Y
        mul_input[2] = input[33];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[34] * input[33]
        mul_input[0] = uint256(12620149755261046671755404694759801128385638190500539207079026239458336064522); // vk.K[35].X
        mul_input[1] = uint256(10994846953135033560648325534438412658436366579529892185303274351838980685981); // vk.K[35].Y
        mul_input[2] = input[34];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[35] * input[34]
        if (commit[0] != 0 || commit[1] != 0) {
            vk_x = Pairing.plus(vk_x, proof.Commit);
        }

        return
            Pairing.pairing(Pairing.negate(proof.A), proof.B, vk.alfa1, vk.beta2, vk_x, vk.gamma2, proof.C, vk.delta2);
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

pragma solidity ^0.8.0;

import "./common/Pairing.sol";
import "./common/Constants.sol";
import "./common/Common.sol";

contract CommitteeRootMappingVerifier {
    using Pairing for *;

    function verifyingKey1() private pure returns (Common.VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            uint256(4625995678875839184227102343980957941553435037863367632170514069470978075482),
            uint256(7745472346822620166365670179252096531675980956628675937691452644416704349631)
        );
        vk.beta2 = Pairing.G2Point(
            [
                uint256(16133906051290029359415836500687237322258320219528941728637152470582101797559),
                uint256(9982592290591904397750372202184781412509742437847499064025507928193374812763)
            ],
            [
                uint256(20447084996628162496147084243623314997274147610235538549283479856317752366847),
                uint256(10652060452474388359080900509291122865897396777233890537481945528644944582649)
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                uint256(14205774305928561884273671177098614973303096843515928049981466843882075090453),
                uint256(6194647019556442694746623566240152360142526955447025858054760757353994166695)
            ],
            [
                uint256(720177741655577944140882804072173464461234581005085937938128202222496044348),
                uint256(15180859461535417805311870856102250988010112023636345871703449475067945282517)
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                uint256(2075341858515413383107490988194322113274273165071779395977011288835607214232),
                uint256(21779842329350845285414688998042134519611654255235365675696046856282966715158)
            ],
            [
                uint256(4310903133868833376693610009744123646701594778591654462646551313203044329349),
                uint256(8934039419334185533732134671857943150009456594043165319933471646801466475060)
            ]
        );
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyCommitteeRootMappingProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[33] memory input
    ) public view returns (bool r) {
        Common.Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

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

        Common.VerifyingKey memory vk = verifyingKey1();

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

        vk_x.X = uint256(20552480178503420105472757749758256930777503163697981232418248899738739436302); // vk.K[0].X
        vk_x.Y = uint256(21874644052683447189335205444383300629386926406593895540736254865290692175330); // vk.K[0].Y
        mul_input[0] = uint256(2419465434811246925970456918943785845329721675292263546063218305166868830301); // vk.K[1].X
        mul_input[1] = uint256(224414837900933448241244127409926533084118787014653569685139207760162770563); // vk.K[1].Y
        mul_input[2] = input[0];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[1] * input[0]
        mul_input[0] = uint256(20237582094031100903111658800543003981446659818658320070287593450545147260932); // vk.K[2].X
        mul_input[1] = uint256(9498936270692258262448475366106441134297508170417707117017418182506243810929); // vk.K[2].Y
        mul_input[2] = input[1];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[2] * input[1]
        mul_input[0] = uint256(21686431407509598771022896245105442713057757617842882639916055310118549735455); // vk.K[3].X
        mul_input[1] = uint256(18587475580363988870337779644366478839186363821430368900189877147428300473925); // vk.K[3].Y
        mul_input[2] = input[2];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[3] * input[2]
        mul_input[0] = uint256(4190323520659374373641761976155873288531237902311450285189695279890286046705); // vk.K[4].X
        mul_input[1] = uint256(8044837422277408304807431419004307582225876792722238390231063677200212676904); // vk.K[4].Y
        mul_input[2] = input[3];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[4] * input[3]
        mul_input[0] = uint256(2652622379392044318082038991710242104342228971779836360052332572087628421201); // vk.K[5].X
        mul_input[1] = uint256(406860223885500452975843681654102213552218004006375181643914225581644355831); // vk.K[5].Y
        mul_input[2] = input[4];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[5] * input[4]
        mul_input[0] = uint256(6057918943482398019697118579402810827270820344972408585195554580949838772589); // vk.K[6].X
        mul_input[1] = uint256(5060377211716517826689871487122513539243478809827924728351043431363438746264); // vk.K[6].Y
        mul_input[2] = input[5];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[6] * input[5]
        mul_input[0] = uint256(3687702938753468537462497928786246235243684882237823906440956320376037461563); // vk.K[7].X
        mul_input[1] = uint256(1208686206265801496727901652555022795816232879429721718984614404615694111083); // vk.K[7].Y
        mul_input[2] = input[6];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[7] * input[6]
        mul_input[0] = uint256(11710614008104008246282861623202747769385618500144669344475214097509828684593); // vk.K[8].X
        mul_input[1] = uint256(5065836875015911503963590142184023993405575153173968399414211124081308802733); // vk.K[8].Y
        mul_input[2] = input[7];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[8] * input[7]
        mul_input[0] = uint256(544404787870686540959136485911507545335221912755631162384362056307403363961); // vk.K[9].X
        mul_input[1] = uint256(2345869893991024974950769006226913293849021455623995373213361343160988457751); // vk.K[9].Y
        mul_input[2] = input[8];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[9] * input[8]
        mul_input[0] = uint256(2209389364146280288951908471817129375141759543141552284740145921306411049406); // vk.K[10].X
        mul_input[1] = uint256(9042259349973012497614444570261244747029883119587798835387806797437998198439); // vk.K[10].Y
        mul_input[2] = input[9];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[10] * input[9]
        mul_input[0] = uint256(5329749415213215279150815169017002879660981652478899879932293459107956198272); // vk.K[11].X
        mul_input[1] = uint256(1269241490245981774317800992176787362067828005821041854984670483140659381972); // vk.K[11].Y
        mul_input[2] = input[10];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[11] * input[10]
        mul_input[0] = uint256(4943793813361186613838184379271444100858893499387902057809188182513783485846); // vk.K[12].X
        mul_input[1] = uint256(9275690329715777324103642003412034648418070562981699307031172873365106078545); // vk.K[12].Y
        mul_input[2] = input[11];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[12] * input[11]
        mul_input[0] = uint256(12729498268013982038852548044563174517696421517428254680176367740849220266709); // vk.K[13].X
        mul_input[1] = uint256(7546589572574852665535613703939452808321148398493753492131740521875420626909); // vk.K[13].Y
        mul_input[2] = input[12];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[13] * input[12]
        mul_input[0] = uint256(9333085734209829031122997463964247926338222396225058317742956090059153031592); // vk.K[14].X
        mul_input[1] = uint256(4043123151744068929699760825751364162242644369436915556155534564396462636465); // vk.K[14].Y
        mul_input[2] = input[13];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[14] * input[13]
        mul_input[0] = uint256(3698686717106590496650986585007797659650605418055308742433506982460764492730); // vk.K[15].X
        mul_input[1] = uint256(9179617523334761636265229485895993306228474412981061346064728177636515751968); // vk.K[15].Y
        mul_input[2] = input[14];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[15] * input[14]
        mul_input[0] = uint256(15521850592660810728436432508964964041834382081916421935161893482249902884387); // vk.K[16].X
        mul_input[1] = uint256(5449901017503560405242500659614777785834634841695450826672263537767974100219); // vk.K[16].Y
        mul_input[2] = input[15];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[16] * input[15]
        mul_input[0] = uint256(20102906107256118088436001377164222872704427733042089123636772674622559816716); // vk.K[17].X
        mul_input[1] = uint256(12498854682789208487185327670228889940757953195079617884138082484806034246784); // vk.K[17].Y
        mul_input[2] = input[16];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[17] * input[16]
        mul_input[0] = uint256(9455841695606475800176819517076441035373288808813491909032241063291148788930); // vk.K[18].X
        mul_input[1] = uint256(5760837211388967374979882368837632355372021503182733102840122488409476353553); // vk.K[18].Y
        mul_input[2] = input[17];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[18] * input[17]
        mul_input[0] = uint256(1446991383552871512734012954692326283314249519870143612600792757960520781278); // vk.K[19].X
        mul_input[1] = uint256(9834470268591454131741863361237282178002203711883219940241340793939995038767); // vk.K[19].Y
        mul_input[2] = input[18];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[19] * input[18]
        mul_input[0] = uint256(1059357485615144832413353841149751938707953460935522780194084907196702253731); // vk.K[20].X
        mul_input[1] = uint256(10815569476482003993766770423385630209543201328293985898718647153832884016017); // vk.K[20].Y
        mul_input[2] = input[19];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[20] * input[19]
        mul_input[0] = uint256(7433245970798099608332042376067563625513377267096206052430761000239299269566); // vk.K[21].X
        mul_input[1] = uint256(12741834193487831964894419250386047831198155854304448707022734193570700410821); // vk.K[21].Y
        mul_input[2] = input[20];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[21] * input[20]
        mul_input[0] = uint256(8648224634225961431530490440075030243542463588893169022877288417966438069777); // vk.K[22].X
        mul_input[1] = uint256(16540610842070555034877322476339116325277917786072762919274678110762172365508); // vk.K[22].Y
        mul_input[2] = input[21];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[22] * input[21]
        mul_input[0] = uint256(16908648218709781420138074614673957046034248547088691701260866141074824824919); // vk.K[23].X
        mul_input[1] = uint256(20980273428957053574278769661356962533672481733183512384951407225298181139010); // vk.K[23].Y
        mul_input[2] = input[22];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[23] * input[22]
        mul_input[0] = uint256(20934252423600973663175987808002009495824217352345209099319606411155218995932); // vk.K[24].X
        mul_input[1] = uint256(9987927206019920292163635872827487165514620975045002130414615160938718715749); // vk.K[24].Y
        mul_input[2] = input[23];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[24] * input[23]
        mul_input[0] = uint256(9602737041922572073213386264444643405537681976425696147506639312256088109115); // vk.K[25].X
        mul_input[1] = uint256(5030838233095700558123674330813925820525997306253984515590208165812087573689); // vk.K[25].Y
        mul_input[2] = input[24];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[25] * input[24]
        mul_input[0] = uint256(20088832978375886523413495106079569725269630343909328763686584839952109161933); // vk.K[26].X
        mul_input[1] = uint256(8311397503596416021728705867174781915782892850820869993294450806608979293432); // vk.K[26].Y
        mul_input[2] = input[25];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[26] * input[25]
        mul_input[0] = uint256(15729968276421379987872047780863974781795109674620595131198333451598870913212); // vk.K[27].X
        mul_input[1] = uint256(11755585053459843437112320638816029546922021127794137048950074210155862560131); // vk.K[27].Y
        mul_input[2] = input[26];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[27] * input[26]
        mul_input[0] = uint256(5783930197610380391486193680213891260111080319012345925622032738683845648623); // vk.K[28].X
        mul_input[1] = uint256(15914052883335873414184612431500787588848752068877353731383121390711998005745); // vk.K[28].Y
        mul_input[2] = input[27];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[28] * input[27]
        mul_input[0] = uint256(13576027419855184371737615151659181815220661446877879847199764825219880625500); // vk.K[29].X
        mul_input[1] = uint256(2191728030944522062213775267825510142676636904535936426097088151735038661017); // vk.K[29].Y
        mul_input[2] = input[28];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[29] * input[28]
        mul_input[0] = uint256(17443744306907421274656073114832682866914815795994710278637727590770342132904); // vk.K[30].X
        mul_input[1] = uint256(6204265850197846880732314988280474321915051365218910504902500465319260176648); // vk.K[30].Y
        mul_input[2] = input[29];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[30] * input[29]
        mul_input[0] = uint256(7667236600173703281656707827902729453577123223272717952708859478183847798002); // vk.K[31].X
        mul_input[1] = uint256(3073364345901477288521870238026227645583520851820532416933060479253244595356); // vk.K[31].Y
        mul_input[2] = input[30];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[31] * input[30]
        mul_input[0] = uint256(9980877541970177898146397507672456369445448128646497326829193893755401659297); // vk.K[32].X
        mul_input[1] = uint256(11845859001496825643147981605740249183632753870257747701403057774143489519069); // vk.K[32].Y
        mul_input[2] = input[31];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[32] * input[31]
        mul_input[0] = uint256(12453897189547283279636360437482740153245209912090247350145743599538029507132); // vk.K[33].X
        mul_input[1] = uint256(6469937287375115226432040539121250021511388797917475330256634615436829876816); // vk.K[33].Y
        mul_input[2] = input[32];
        Common.accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[33] * input[32]

        return
            Pairing.pairing(Pairing.negate(proof.A), proof.B, vk.alfa1, vk.beta2, vk_x, vk.gamma2, proof.C, vk.delta2);
    }
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