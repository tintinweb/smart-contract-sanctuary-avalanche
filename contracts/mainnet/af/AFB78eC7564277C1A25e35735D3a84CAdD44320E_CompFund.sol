// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CompFund is Ownable, Initializable {
    using SafeERC20 for IERC20;
    address public Exc;
	address public ExcAvax;
    uint256 public claimedAmount;
	uint256 public constant VESTING_DURATION = 70 days;
	uint256 public constant VESTING_INTERVAL = 7 days;
    uint256 public VESTING_START = 1650020400;
	
	struct claimData{
		uint256 excAmount;
		uint256 excAvaxAmount;
		uint256 excAmountClaimed;
		uint256 excAvaxAmountClaimed;
		uint256 lastClaimTimestamp;
		uint256 timesClaimed;
		}
		
	mapping(address => claimData) public compensation;

    /*===================== CONSTRUCTOR =====================*/

    function initialize(address _Exc,address _ExcAvax) external initializer {
        require(_Exc != address(0) && _ExcAvax != address(0) , "Fund::constructor: Invalid address");
        Exc = _Exc;
		ExcAvax = _ExcAvax;
		
		compensation[0x8B253Fd5A359a305BB1C63222fd35B00bb2CC484].excAmount = 1600 ether;
		compensation[0xA380b9a090187d89aB14e03A8540791de5a662a1].excAmount = 1302 ether;
		compensation[0x5AF64Ba80Aaf01F81D86a16EdCB6861B93339d26].excAmount = 1160 ether;
		compensation[0xB27Bab5009F7707339c1a9e4eD8A51003dbfA723].excAmount = 989 ether;
		compensation[0xf7BA31970d894Dfe3DfC03807039b4F520547e12].excAmount = 909 ether;
		compensation[0x66435387dcE9f113Be44d5e730eb1C068B328E93].excAmount = 873 ether;
		compensation[0xEBaa9dadB418FCD4a5b6905A521C39d5df76084C].excAmount = 870 ether;
		compensation[0x5acd29efdaC786d4f5D9797158E42D2574F0d76E].excAmount = 811 ether;
		compensation[0x478DEbFE0fCE7Bc4050Dd967B319f24baEb0bCD4].excAmount = 800 ether;
		compensation[0x0Ff0541535BF4049FdD7B71133d056B011A72056].excAmount = 787 ether;
		compensation[0xFD059D49f1c7a39864a4B0524945f9Eb4Cf6F782].excAmount = 713 ether;
		compensation[0x3E504fa0Ba800fE050fD09BB55Ae274cD93a3ed7].excAmount = 680 ether;
		compensation[0x57860148eF09baA9F1cB536b6FcF6E39231b6844].excAmount = 559 ether;
		compensation[0xac703CDbE2C7E1f72Dfc45471bbBf3704847430e].excAmount = 535 ether;
		compensation[0xe1B3f8B7710B2251BcB4aC92B31a9F6A3A17e0E8].excAmount = 528 ether;
		compensation[0xbc8e98dC6a01AE9e452EFAa956A82D62d261e46C].excAmount = 523 ether;
		compensation[0x43A4bfF34c736893c0E46a21E3fAC2424e153c28].excAmount = 500 ether;
		compensation[0x9BDa81715596C44Db6D8AFdEdeB60231325671c4].excAmount = 498 ether;
		compensation[0xeF6c4192C8530A2502e153bDc2256dD72AB445e4].excAmount = 455 ether;
		compensation[0xc38660D5fF17Ec3e66ec68AD645Bd6A3DCa22647].excAmount = 447 ether;
		compensation[0x2d45114797c9d80B8fE5fe5688c75Bee06fe09f3].excAmount = 439 ether;
		compensation[0xAe4bdaA650eDfeA700938587dA2B835E008Aa965].excAmount = 438 ether;
		compensation[0x1C2F5ec4239B2d1B10617f85AAFe9c047A52698C].excAmount = 417 ether;
		compensation[0x4d7D2D9aDd39776Bba47A8F6473A6257dd897702].excAmount = 381 ether;
		compensation[0x45542d2Ac03A49af591F1d8662BBdeC72DaC7039].excAmount = 375 ether;
		compensation[0x2b47694A614fDf0EE56A206C106038e5B1928F7e].excAmount = 359 ether;
		compensation[0x727384409a15eA93b5608E9EE2bB1A3293B09e10].excAmount = 342 ether;
		compensation[0xb689A89954C04C4a238697b64379810a666287ea].excAmount = 341 ether;
		compensation[0x3e6525AddA18d36A7A57629E36Bc436735aF1a1f].excAmount = 340 ether;
		compensation[0x3E65bF392740fC28336Ec329fb885f5Bfeeb5247].excAmount = 340 ether;
		compensation[0x85eC4cD30463ABC35dC910B5E89E06E581C825A1].excAmount = 340 ether;
		compensation[0xeb1E8125Dc88c85eC29784F77272AC841d1655CD].excAmount = 340 ether;
		compensation[0x10e1Fd32f80d60A5E6f00473C8D006c8Bd6bDE13].excAmount = 339 ether;
		compensation[0x1e6D25889Ca68811cB834F7Cce9c21267c25570E].excAmount = 299 ether;
		compensation[0x6Dd407f05C032Ae2D5c1E666E4aA3570263b306f].excAmount = 267 ether;
		compensation[0x40DdC458aF13B3e0a99F24e972A80d76D04EE040].excAmount = 257 ether;
		compensation[0xf16d1c49af1D276B885253c0370Af677B46647f6].excAmount = 247 ether;
		compensation[0xEaB87E29bA6F88a6256410631e977E80F4f17486].excAmount = 240 ether;
		compensation[0x3B52350c137024056483693DfEfc990C6f93E49a].excAmount = 239 ether;
		compensation[0x7817c35727F2C048D2d7ad3E42655513987bC755].excAmount = 233 ether;
		compensation[0xaf05714BF27B6e9d7dFd590bBf0e505086844Ad0].excAmount = 225 ether;
		compensation[0x17Ffd35387521CE2021B66e7c91b3e5B5797c722].excAmount = 225 ether;
		compensation[0x16D088a79D7d36213618263184783fB4d6375e33].excAmount = 223 ether;
		compensation[0x6F41cbbaB3FFA2864fD76E4C53Cb23bDb9Caa4eb].excAmount = 221 ether;
		compensation[0xd072674B0c218EFc6f6D5972563ccDfbf78e2eFe].excAmount = 208 ether;
		compensation[0x0a4CEcbF05d06C837FfD79beDC5C03856d0297A2].excAmount = 202 ether;
		compensation[0xc90e2BA4f2B3A3Ef433f20Dd078ca8854318dc26].excAmount = 200 ether;
		compensation[0xef63bA8059C7f322D18c96F34671F4e0E3C80b05].excAmount = 195 ether;
		compensation[0xfdBcAbdeB86F6B4a2f3a906e46ADd3Fe4604AA49].excAmount = 195 ether;
		compensation[0x6D42977A60aEF0de154Dc255DE03070A690cF041].excAmount = 184 ether;
		compensation[0x34a08512dB2FB18df9b43648e6f1e0D99BcF2363].excAmount = 181 ether;
		compensation[0xf682bf6EB26fd1083f0b499d958634Fe453CF146].excAmount = 180 ether;
		compensation[0xF75AcDFbB47F05b9C6d3c203eC5DBcbeC7b94aC2].excAmount = 180 ether;
		compensation[0xa807B93C05404F9FEda93fC8c3a7c8A39FD385fC].excAmount = 178 ether;
		compensation[0xc4f107089a02E5b3e52B99f73d19eDb99e68dCC9].excAmount = 176 ether;
		compensation[0x257caF977524F2ae37e5383D6380CE287bD29c17].excAmount = 171 ether;
		compensation[0xDE0003b5C9f040F6F7eae1D09d1F05DeEf06A3FC].excAmount = 169 ether;
		compensation[0xAF8E12150334D64d5e6f6f26EBf3494D63346Aa2].excAmount = 166 ether;
		compensation[0x9174E3D463089b79a2aDbebf6E3A5fC5E143355E].excAmount = 155 ether;
		compensation[0x35D0ef0EBA43AA2751c88649b9e2163150826385].excAmount = 153 ether;
		compensation[0x13Ed9AefDaB35dB6D69A798d31904B2E9B3ac327].excAmount = 153 ether;
		compensation[0x40212820839c4c4AA85deFb0030DF7CB075e82e6].excAmount = 153 ether;
		compensation[0xD93623D2728667C616adEccF5248462e31Bf8307].excAmount = 150 ether;
		compensation[0xfBf594D6c258d8DD53860915644E15f5B788E522].excAmount = 150 ether;
		compensation[0xDaa3AE8bfBa96293a19925C47aaC90582E798D56].excAmount = 146 ether;
		compensation[0xC79C0664200C0068a8798A0b6acC2Be189D2aDB0].excAmount = 146 ether;
		compensation[0x91A109764c56e06cB069fd2Da655D1B54D42035D].excAmount = 145 ether;
		compensation[0x824CE1ff230c27d96EB86814d427a590658c2834].excAmount = 144 ether;
		compensation[0x414406b878679D96C7F0d52574505788D5039195].excAmount = 138 ether;
		compensation[0xa6f411068b1FF814BD6daf607A5d444C2f298E07].excAmount = 136 ether;
		compensation[0xC5Fe6e367742Af4d3A545d073DD310fa4842CD95].excAmount = 128 ether;
		compensation[0x76a66b018a5185Aa411491a3Ff75bF3ABCC99A6E].excAmount = 126 ether;
		compensation[0x68B531349EB44496943Be5FF15A5F510849D561f].excAmount = 120 ether;
		compensation[0x6853285716a92aF6DD07F2F6aeBCA23E5b13f8f6].excAmount = 119 ether;
		compensation[0x95Bce4F4fbfFbd4d4cd2Ca94385AdA9A82e5C683].excAmount = 118 ether;
		compensation[0xA4EBe47B1814Adb62d003C6C9B60264F780eb8Db].excAmount = 116 ether;
		compensation[0xa88361D2c0645F5d8Dd3Be72777a565059FBb139].excAmount = 112 ether;
		compensation[0xBCaB5f93313b29Cbc9f45cDeeC9299CC32Bd7273].excAmount = 104 ether;
		compensation[0x4e2A5a06934c35c83F7066bCa8Bc30f5F1685466].excAmount = 102 ether;
		compensation[0x766Affb42F5d1558f6D64cA34d59291b4ee8CE9d].excAmount = 101 ether;
		compensation[0x5b5452a7c4896114AdD3d5e3Ef72849dB458d83C].excAmount = 96 ether;
		compensation[0xf090d21e518f26074B481c5d4bcAC86d9792B9a6].excAmount = 95 ether;
		compensation[0x2A8e0ebDA46A075D77d197D21292e38D37a20AB3].excAmount = 95 ether;
		compensation[0xbE0898b872b6a54a16E1d5369a5CB7784230f67B].excAmount = 95 ether;
		compensation[0x85B6694F227C4602D2e8cea95E986272E09221E8].excAmount = 95 ether;
		compensation[0x0bC37548e2a82c21BAfa3c7f3297E3055353a39A].excAmount = 94 ether;
		compensation[0xb2130F002Bd9f577DccbEFb80986Efe03D347914].excAmount = 91 ether;
		compensation[0xecA35c5332cc4Ea6FEB295152928C80ea7d56B97].excAmount = 89 ether;
		compensation[0xbbB0D6B4c727De0E57F3017Bb096BeD0d1baa9eb].excAmount = 89 ether;
		compensation[0x192f321333B107eA800c399e5B219A2EF67Cd21C].excAmount = 89 ether;
		compensation[0xAF6f459B17F56af34d1b81edE025251D79a4F443].excAmount = 88 ether;
		compensation[0xE1a35aE293839CB014e068FEa968F44a9675d125].excAmount = 88 ether;
		compensation[0x9c5071e4081C7Def7C4E00d41C7A0352Bb0D9e8D].excAmount = 83 ether;
		compensation[0x8485Ae9606C9648B3FC8d52048c159B5C817BB84].excAmount = 81 ether;
		compensation[0xFc49434836bfE183a0042B097F993FBe2C46275e].excAmount = 80 ether;
		compensation[0xEA125ED28bE7B909F84C8BA08D1d89340100Eb5a].excAmount = 76 ether;
		compensation[0x00BCE681D5F97D9308e04F98b7C16276f89543cf].excAmount = 74 ether;
		compensation[0x12C759A7d404931d9B02212F36E33A70d2bBe4Aa].excAmount = 68 ether;
		compensation[0x3d978CF26c122E184626d1d420e1D1DA58f78102].excAmount = 65 ether;
		compensation[0x98033FAa8d226AB4aD234C4A1909b018e111C9cD].excAmount = 64 ether;
		compensation[0x697BD69B637F6B4311510A038A975CCFc0c93788].excAmount = 64 ether;
		compensation[0xc564733DFF051A3d4Fc460ab7BC44E40599E4796].excAmount = 61 ether;
		compensation[0x3Eb0FCF77A550484Fd371fd019F3c05381F59A0c].excAmount = 61 ether;
		compensation[0x3A56b3b3f778aaA38beBd26d584A900BAbCCadB4].excAmount = 57 ether;
		compensation[0xf6D6C2A6446D0f631677F19B82828D7d4D2dEE24].excAmount = 55 ether;
		compensation[0xAEE9597de68C57439953c46B02f8AC11b5145170].excAmount = 53 ether;
		compensation[0x3a52c7df1bB5e70A0A13e9C9c00f258fe9Da68fD].excAmount = 53 ether;
		compensation[0x2a6b730A5e3733Cb0D33eb266E8C93169d49b3a2].excAmount = 52 ether;
		compensation[0xB0fcB2DdAC5a2259B6F2Bf5686D638acA5Be8782].excAmount = 51 ether;
		compensation[0x6940Dd4B39ec941d2C98E82165F00F6A5f4DEe09].excAmount = 51 ether;
		compensation[0xbBBc17fC1ab7C6D96Ca434178D3E2840F984436D].excAmount = 50 ether;
		compensation[0x3d736DCB07501d01Fa543Fc3bBf2452A5Bd64d80].excAmount = 50 ether;
		compensation[0x5ec6bC92395bFE4dFb8F45cb129AC0c2F290F23d].excAmount = 50 ether;
		compensation[0x8dabC1F4Dc8b5BA2830a9e1c227879B813CCeFcD].excAmount = 48 ether;
		compensation[0xBD8F13002803301B6F6115248fdD50Ae1beA952a].excAmount = 47 ether;
		compensation[0x310eAf3f34Ae436106C05bc47464F887C05d35D8].excAmount = 47 ether;
		compensation[0xD2f01948f83c6545E3045F1bd95387a388bfA8d7].excAmount = 43 ether;
		compensation[0x0C7aee4E68c5783b50B5b68F14c89744a13AC76f].excAmount = 43 ether;
		compensation[0x8600282288C2700EC796DeDF3f882dAe307aFE2C].excAmount = 43 ether;
		compensation[0x6770fdFB53dE4CA8e629cA43e10FB6877b7e530e].excAmount = 42 ether;
		compensation[0xD6DE0B874A8f4994af955fC3b975004de59AaEbF].excAmount = 41 ether;
		compensation[0xB33CB651648A99F2FFFf076fd3f645fAC24d460F].excAmount = 39 ether;
		compensation[0xF6BFccfD77aF8372E836815892Ac0d3f98a023db].excAmount = 39 ether;
		compensation[0xAD630CdD705c9861020b7a20cF6c06F045c69C79].excAmount = 38 ether;
		compensation[0x5c054672839C653DAb8cbde3F569AaFbAD52D3fa].excAmount = 37 ether;
		compensation[0xf3e651b7e5A9Afbf8EBc5D0c0182773319Ba3e76].excAmount = 36 ether;
		compensation[0x710f215a7B05a5eA820EA1BB30A469D15eB8D54E].excAmount = 36 ether;
		compensation[0xACDc265C00D55B22e28019F50d994d6FDD871dE8].excAmount = 36 ether;
		compensation[0x230c8A697D4F2710d1F99ad8095C13Cc09C42B47].excAmount = 36 ether;
		compensation[0x3645898c56667a74E406761CFC7FD12284d821E8].excAmount = 36 ether;
		compensation[0xF4de69C1269C41F911A674d7D4326aC92C410C0D].excAmount = 35 ether;
		compensation[0x747f1214925dd83D35FfB536dd5047259BF99EB9].excAmount = 34 ether;
		compensation[0x1C094EE1Cb1013480Fd3871C7bd7ec9e24b6Bf54].excAmount = 34 ether;
		compensation[0x330AD0d38e9c12cbC34d7cfFEFCd99E5530b6bfb].excAmount = 34 ether;
		compensation[0x563178f7E9658B9ba5E9B44686f22534E7C5134A].excAmount = 33 ether;
		compensation[0x11Ce26dA6CBe7761c851024ebBECE78b9b360e25].excAmount = 32 ether;
		compensation[0x49c152bD3DC6BBCDcCE6701aF767731cc212C97D].excAmount = 31 ether;
		compensation[0xb11C10Ba8d2d9bc81148696A70B03df20DbED9b1].excAmount = 30 ether;
		compensation[0x1D6d06662742080121B35D34c2A3153307098367].excAmount = 30 ether;
		compensation[0x1162AFdd10E88a2bFd05B813Aa6a48e9BFAc3900].excAmount = 29 ether;
		compensation[0x547E462e878c6cB802b9D6095cf6393941565E4F].excAmount = 27 ether;
		compensation[0x88ECE63dE46e5F641C04323000070d6f654Ed868].excAmount = 27 ether;
		compensation[0x9E25d359BB67a5fe44c599B1D2fd0C0599046E1a].excAmount = 26 ether;
		compensation[0x4A4651320346a136E7573B1fafAD09fDA848b9Ff].excAmount = 24 ether;
		compensation[0x30AF9ED6514c943fcDEA1Cf26EEc44AaEd134825].excAmount = 24 ether;
		compensation[0x78EC2Ba25042b43143aDcB64074E1e88C6c87819].excAmount = 23 ether;
		compensation[0x025A5b1C6e97E9e6f9a93aA8aD776bc9e84F261A].excAmount = 22 ether;
		compensation[0x34D1516a1E3AEf181b58e3784e9d6CD1D155241C].excAmount = 21 ether;
		compensation[0x6dA10463F51e105aC3D15A8C4f13E1F1032EFB99].excAmount = 19 ether;
		compensation[0xe3c4C7C5fF37cE99Be342B8D37C21095ab4D26e1].excAmount = 18 ether;
		compensation[0x28e5B3A4B389bd1d921bD9C9B2Db9f2Aa04964D3].excAmount = 17 ether;
		compensation[0xE5672131Ddd8F3610070182af4290cB57DcaF6A3].excAmount = 17 ether;
		compensation[0x091E26376f89d0c6A97467cB57Eae050A43821dD].excAmount = 17 ether;
		compensation[0x570d9193187cFDed8238606626d0e2CbeEB34e83].excAmount = 17 ether;
		compensation[0x8463ebD2AA8bD16C687CE73A99b82B9F1f431D62].excAmount = 16 ether;
		compensation[0x206710759F9c6ad87490a131Ab31255b38A423EB].excAmount = 15 ether;
		compensation[0xDe047A2f608399CE684d9653616339eBF47c32BC].excAmount = 15 ether;
		compensation[0xa405681bF1915c23FE284DD90133a7EBA7f9e143].excAmount = 14 ether;
		compensation[0x1Aa658CC31883f9e3aF69d56201DCb708235F4e6].excAmount = 12 ether;
		compensation[0x1530705B363f66a464F6547A3824Eb2fC7388909].excAmount = 11 ether;
		compensation[0xAFDa97ec9E7E2a0ab53f5967a4891BD82d518cCf].excAmount = 11 ether;
		compensation[0x407E9Aa105466bE8F08e4A5A8B537A528319dDD1].excAmount = 10 ether;
		compensation[0x4A9913a900866e6C711da9256D5576b24BEc584D].excAmount = 10 ether;
		compensation[0xe3ad38D0C2AaCb7cb59ddF0f7B8aAA1B2121cDf3].excAmount = 9 ether;
		compensation[0x30D00F535C9F8be6c415f614aAF2AB12Cb6E4dcE].excAmount = 8 ether;
		compensation[0x106973Ed6e37c93D34cEaD2AF85b7a4C703Eee81].excAmount = 7 ether;
		compensation[0xDf3c6Dbc380e50Af17bcfE9626A96C626A70AB78].excAmount = 7 ether;
		compensation[0x49F0d91d9F5Ded5E486332B6B0281B41f29b92D4].excAmount = 6 ether;
		compensation[0xe13615Ab5370E755cD967faA43bCC4c79a7520fD].excAmount = 6 ether;
		compensation[0xE06Bd466f07D6C8e4224b3fC86Fa587d3265d0dF].excAmount = 5 ether;
		compensation[0x3110BfEa8876Fd84f26d323623F0Dbd8E74C14f8].excAmount = 5 ether;
		compensation[0x59d26fc8304d0D84E1ff27AC98B5473BF93e1097].excAmount = 5 ether;
		compensation[0x6CA5584a814471680d823a787EEEb58c1e03E1e0].excAmount = 4 ether;
		compensation[0xd63f243f649A2E4f33F771DC1d5C34625cAd74F9].excAmount = 4 ether;
		compensation[0xE4C89511d2F610A3AE752f77ffaccCDA0EB36903].excAmount = 4 ether;
		compensation[0x2a5Ac02BCb01A44C661129625355EF91D608A29b].excAmount = 2 ether;
		compensation[0x46fD6bDA4f0190bf3b60d31CB0D6D6711CFFf09E].excAmount = 1 ether;
		compensation[0x5113901DeF7E42Cb7A2800428fEf3B4b18BEB35d].excAmount = 1 ether;
		compensation[0xcbBFa40F36F0Fda22f28BC25E43D52573D6826dB].excAmount = 1 ether;
		compensation[0x2DdbB811F1b310EFc1D7C31b426F82d6dcF584f4].excAmount = 1 ether;
		compensation[0xdE61c2356c4aFfDB1B94fE04bECc87238fB4589E].excAmount = 1 ether;
		compensation[0xaC1a7B00C864C54c13C8a36063eaB123F383dbb0].excAvaxAmount = 629 ether;
		compensation[0x2d45114797c9d80B8fE5fe5688c75Bee06fe09f3].excAvaxAmount = 199 ether;
		compensation[0x7F3d8834fbEb6a4ebA0Ed46CB2aaCCE82B2cEEb6].excAvaxAmount = 158 ether;
		compensation[0x6f3064d973C08Dd9c88D43080549F474E5827d71].excAvaxAmount = 130 ether;
		compensation[0xc38660D5fF17Ec3e66ec68AD645Bd6A3DCa22647].excAvaxAmount = 43 ether;
		compensation[0x33d708908aF70BD27aFdAA02dC029901D3927098].excAvaxAmount = 30 ether;
		compensation[0xA380b9a090187d89aB14e03A8540791de5a662a1].excAvaxAmount = 23 ether;
		compensation[0xF548026Ea108E3B3ffe3354b8BB5015F87B2E292].excAvaxAmount = 23 ether;
		compensation[0x2e909729016eb1013a197e05210e35cE4435ABc4].excAvaxAmount = 23 ether;
		compensation[0x78486b3930A4da1922a1f25e7c3E0a24f054f3D3].excAvaxAmount = 17 ether;
		compensation[0x091E26376f89d0c6A97467cB57Eae050A43821dD].excAvaxAmount = 15 ether;
		compensation[0xeF6c4192C8530A2502e153bDc2256dD72AB445e4].excAvaxAmount = 13 ether;
		compensation[0xBF1f5E54CDD15dE2bE2c8aeC495D00D804CDd8fc].excAvaxAmount = 11 ether;
		compensation[0x40212820839c4c4AA85deFb0030DF7CB075e82e6].excAvaxAmount = 10 ether;
		compensation[0x20b7da813C3EA5Cf9032610730d1686b7660Ebc7].excAvaxAmount = 10 ether;
		compensation[0xbc8e98dC6a01AE9e452EFAa956A82D62d261e46C].excAvaxAmount = 8 ether;
		compensation[0xEA125ED28bE7B909F84C8BA08D1d89340100Eb5a].excAvaxAmount = 8 ether;
		compensation[0xac703CDbE2C7E1f72Dfc45471bbBf3704847430e].excAvaxAmount = 7 ether;
		compensation[0x82eFa90e1341c57fF7F095Ec55681B1fF6E821A7].excAvaxAmount = 7 ether;
		compensation[0x3d736DCB07501d01Fa543Fc3bBf2452A5Bd64d80].excAvaxAmount = 6 ether;
		compensation[0x5c054672839C653DAb8cbde3F569AaFbAD52D3fa].excAvaxAmount = 6 ether;
		compensation[0x6b434f8e80E8B85A63A9f4fF0A14eB9568a827c8].excAvaxAmount = 6 ether;
		compensation[0xf7BA31970d894Dfe3DfC03807039b4F520547e12].excAvaxAmount = 5 ether;
		compensation[0x697BD69B637F6B4311510A038A975CCFc0c93788].excAvaxAmount = 5 ether;
		compensation[0x221F1fF597930212bBf0Cf5904cFEBeFca537d16].excAvaxAmount = 5 ether;
		compensation[0x727384409a15eA93b5608E9EE2bB1A3293B09e10].excAvaxAmount = 4 ether;
		compensation[0xDaa3AE8bfBa96293a19925C47aaC90582E798D56].excAvaxAmount = 4 ether;
		compensation[0x9090c0C373bD61Fc7130cE53857d57463ab6A6Ea].excAvaxAmount = 3.08 ether;
		compensation[0x17Ffd35387521CE2021B66e7c91b3e5B5797c722].excAvaxAmount = 3 ether;
		compensation[0x2DdbB811F1b310EFc1D7C31b426F82d6dcF584f4].excAvaxAmount = 3 ether;
		compensation[0x58b80FF10946cFdA425c81F8619c6C1615A517B5].excAvaxAmount = 3 ether;
		compensation[0xAC586131A53D002db0B202b12f9c92b09926ea02].excAvaxAmount = 3 ether;
		compensation[0x4e2A5a06934c35c83F7066bCa8Bc30f5F1685466].excAvaxAmount = 2 ether;
		compensation[0x570d9193187cFDed8238606626d0e2CbeEB34e83].excAvaxAmount = 2 ether;
		compensation[0x85B6694F227C4602D2e8cea95E986272E09221E8].excAvaxAmount = 1 ether;
		compensation[0xB0fcB2DdAC5a2259B6F2Bf5686D638acA5Be8782].excAvaxAmount = 1 ether;
		compensation[0xF6BFccfD77aF8372E836815892Ac0d3f98a023db].excAvaxAmount = 1 ether;
		compensation[0x70575A31709f40A0536173266D9913fbd54b8194].excAvaxAmount = 1 ether;
		compensation[0x4192EC7b9288a620659A1159e18755732fB401e8].excAvaxAmount = 1 ether;
		compensation[0xDe047A2f608399CE684d9653616339eBF47c32BC].excAvaxAmount = 0.87 ether;
		compensation[0x42842C35329e504141e482cD0e30884fc5616AAc].excAvaxAmount = 0.79 ether;
		compensation[0x330AD0d38e9c12cbC34d7cfFEFCd99E5530b6bfb].excAvaxAmount = 0.78 ether;
		compensation[0x34D1516a1E3AEf181b58e3784e9d6CD1D155241C].excAvaxAmount = 0.65 ether;
		compensation[0xF2da34A196B739811a593C9Fc434f23e099a03d1].excAvaxAmount = 0.52 ether;
		compensation[0x747f1214925dd83D35FfB536dd5047259BF99EB9].excAvaxAmount = 0.44 ether;
		compensation[0x16D088a79D7d36213618263184783fB4d6375e33].excAvaxAmount = 0.38 ether;
		compensation[0xc90e2BA4f2B3A3Ef433f20Dd078ca8854318dc26].excAvaxAmount = 0.31 ether;
		compensation[0xCe0Bdca2Bb503639aE43E280fbA9a49F966f7B8A].excAvaxAmount = 0.28 ether;
		compensation[0xFc38873787d720343f10B062D52E5F495b126558].excAvaxAmount = 0.15 ether;
		compensation[0xFDb6D37687474d42Fe6F95e12b66CD156e0EA8D3].excAvaxAmount = 0.14 ether;
		compensation[0x0bC37548e2a82c21BAfa3c7f3297E3055353a39A].excAvaxAmount = 0.13 ether;
		compensation[0x0f396Be3Cb5deB65Ecd97FD699E4c05EC4474A56].excAvaxAmount = 0.13 ether;
		compensation[0x4b679ce070338d97e41E651C3D78A50C3a7979bf].excAvaxAmount = 0.11 ether;
		compensation[0xdE61c2356c4aFfDB1B94fE04bECc87238fB4589E].excAvaxAmount = 0.08 ether;
		compensation[0xc69681d5b0c499126EcBD8cf5500B50E6C821306].excAvaxAmount = 0.06 ether;
		compensation[0x2a5Ac02BCb01A44C661129625355EF91D608A29b].excAvaxAmount = 0.05 ether;
		compensation[0x3a170AA8467D44740376fFC1e1DEf3Ea22C23653].excAvaxAmount = 0.01 ether;
		compensation[0x4f7c843C48a9072D7D74382a8b5fF1e91a02eaa5].excAvaxAmount = 0.01 ether;	
		
    }

    /*===================== VIEWS =====================*/

    function allocation(address _comp) public view returns (uint256 ExcBalance, uint256 ExcAvaxBalance){
		ExcBalance = compensation[_comp].excAmount;
		ExcAvaxBalance = compensation[_comp].excAvaxAmount;
		}
		

    function vestingStart() public view returns (uint256) {
        return VESTING_START;
    }
	
    function vestingDuration() public pure returns (uint256) {
        return VESTING_DURATION;
    }
	
    function currentBalance() public view returns (uint256 ExcBalance, uint256 ExcAvaxBalance) {
        return (IERC20(Exc).balanceOf(address(this)), IERC20(ExcAvax).balanceOf(address(this)));
    }

	function initialClaim(address _comp) public view returns (bool){
		if((compensation[_comp].excAmount > 0 || compensation[_comp].excAvaxAmount > 0) &&
			(block.timestamp > VESTING_START) &&
			(block.timestamp < VESTING_START + VESTING_DURATION) &&
			(compensation[_comp].excAmountClaimed == 0 &&  compensation[_comp].excAvaxAmountClaimed == 0)&&
			(compensation[_comp].timesClaimed == 0)){
			return true;
			}
		else { 
			return false;
		}
	}
					
    function vestedBalance(address _comp) public view returns (uint256 ExcBalance, uint256 ExcAvaxBalance) {
        uint256 _start = vestingStart();
        uint256 _duration = vestingDuration();
        if (block.timestamp <= _start) {
           ExcBalance = 0;
		   ExcAvaxBalance = 0;
        }
        if (block.timestamp > _start + _duration) {
			ExcBalance = compensation[_comp].excAmount;
			ExcAvaxBalance = compensation[_comp].excAvaxAmount;
        }
		if (initialClaim(_comp)){
			ExcBalance = (compensation[_comp].excAmount * 10)/100;
			ExcAvaxBalance = (compensation[_comp].excAvaxAmount *10)/100;
		}
		
		if (!initialClaim(_comp)){
			ExcBalance = (compensation[_comp].excAmount * (block.timestamp - _start)) / _duration;
			ExcAvaxBalance = (compensation[_comp].excAvaxAmount * (block.timestamp - _start)) / _duration;
		}
	}

    function claimable(address _comp) public view returns (uint256 ExcBalance, uint256 ExcAvaxBalance) {
        (uint256 EXCVested, uint256 EXCAvaxVested) = vestedBalance(_comp);
		ExcBalance = EXCVested -  compensation[_comp].excAmountClaimed;
		ExcAvaxBalance = EXCAvaxVested - compensation[_comp].excAvaxAmountClaimed;
    }

    /*===================== MUTATIVE =====================*/
	
	 function claim() public {
        require(compensation[msg.sender].excAmount > 0 || compensation[msg.sender].excAvaxAmount > 0);
		require(block.timestamp > VESTING_START && compensation[msg.sender].lastClaimTimestamp + VESTING_INTERVAL < block.timestamp);
		uint256 amountExc;
		uint256 amountExcAvax;
		compensation[msg.sender].lastClaimTimestamp = block.timestamp;
		if(block.timestamp > VESTING_START + VESTING_DURATION){
			amountExc = compensation[msg.sender].excAmount;
			amountExcAvax = compensation[msg.sender].excAvaxAmount;
		}
		if (initialClaim(msg.sender)){
			amountExc = (compensation[msg.sender].excAmount * 10)/100;
			amountExcAvax = (compensation[msg.sender].excAvaxAmount *10)/100;
		}
		else{
			(amountExc,amountExcAvax) = claimable(msg.sender);
		}
		
		compensation[msg.sender].timesClaimed++;
		
		if (amountExc > 0){
			compensation[msg.sender].excAmountClaimed += amountExc;
			IERC20(Exc).safeTransfer(msg.sender, amountExc);
		}
		if (amountExcAvax > 0){
			compensation[msg.sender].excAvaxAmountClaimed += amountExcAvax;
			IERC20(ExcAvax).safeTransfer(msg.sender, amountExcAvax);
		} 
    }
	
	function withDrawTokens(address tokenAddress) public onlyOwner {
		IERC20 token = IERC20(tokenAddress);
        uint256 tokenAmt = token.balanceOf(address(this));
        require(tokenAmt > 0, 'balance is 0');
        token.transfer(msg.sender, tokenAmt);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}