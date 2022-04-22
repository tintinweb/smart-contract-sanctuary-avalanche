/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-21
*/

// File: contracts/TalentScout/PreSale.sol



/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-13
*/

/* IMPORTS */
    // File: contracts/voter-staking-new.sol

    /**
    *Submitted for verification at testnet.snowtrace.io on 2022-03-31
    */


    // File: hardhat/console.sol


    pragma solidity >= 0.4.22 <0.9.0;

    library console {
        address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

        function _sendLogPayload(bytes memory payload) private view {
            uint256 payloadLength = payload.length;
            address consoleAddress = CONSOLE_ADDRESS;
            assembly {
                let payloadStart := add(payload, 32)
                let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
            }
        }

        function log() internal view {
            _sendLogPayload(abi.encodeWithSignature("log()"));
        }

        function logInt(int p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
        }

        function logUint(uint p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
        }

        function logString(string memory p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
        }

        function logBool(bool p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
        }

        function logAddress(address p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
        }

        function logBytes(bytes memory p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
        }

        function logBytes1(bytes1 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
        }

        function logBytes2(bytes2 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
        }

        function logBytes3(bytes3 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
        }

        function logBytes4(bytes4 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
        }

        function logBytes5(bytes5 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
        }

        function logBytes6(bytes6 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
        }

        function logBytes7(bytes7 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
        }

        function logBytes8(bytes8 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
        }

        function logBytes9(bytes9 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
        }

        function logBytes10(bytes10 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
        }

        function logBytes11(bytes11 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
        }

        function logBytes12(bytes12 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
        }

        function logBytes13(bytes13 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
        }

        function logBytes14(bytes14 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
        }

        function logBytes15(bytes15 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
        }

        function logBytes16(bytes16 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
        }

        function logBytes17(bytes17 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
        }

        function logBytes18(bytes18 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
        }

        function logBytes19(bytes19 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
        }

        function logBytes20(bytes20 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
        }

        function logBytes21(bytes21 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
        }

        function logBytes22(bytes22 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
        }

        function logBytes23(bytes23 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
        }

        function logBytes24(bytes24 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
        }

        function logBytes25(bytes25 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
        }

        function logBytes26(bytes26 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
        }

        function logBytes27(bytes27 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
        }

        function logBytes28(bytes28 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
        }

        function logBytes29(bytes29 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
        }

        function logBytes30(bytes30 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
        }

        function logBytes31(bytes31 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
        }

        function logBytes32(bytes32 p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
        }

        function log(uint p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
        }

        function log(string memory p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
        }

        function log(bool p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
        }

        function log(address p0) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
        }

        function log(uint p0, uint p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
        }

        function log(uint p0, string memory p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
        }

        function log(uint p0, bool p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
        }

        function log(uint p0, address p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
        }

        function log(string memory p0, uint p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
        }

        function log(string memory p0, string memory p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
        }

        function log(string memory p0, bool p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
        }

        function log(string memory p0, address p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
        }

        function log(bool p0, uint p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
        }

        function log(bool p0, string memory p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
        }

        function log(bool p0, bool p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
        }

        function log(bool p0, address p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
        }

        function log(address p0, uint p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
        }

        function log(address p0, string memory p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
        }

        function log(address p0, bool p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
        }

        function log(address p0, address p1) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
        }

        function log(uint p0, uint p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
        }

        function log(uint p0, uint p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
        }

        function log(uint p0, uint p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
        }

        function log(uint p0, uint p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
        }

        function log(uint p0, string memory p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
        }

        function log(uint p0, string memory p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
        }

        function log(uint p0, string memory p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
        }

        function log(uint p0, string memory p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
        }

        function log(uint p0, bool p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
        }

        function log(uint p0, bool p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
        }

        function log(uint p0, bool p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
        }

        function log(uint p0, bool p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
        }

        function log(uint p0, address p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
        }

        function log(uint p0, address p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
        }

        function log(uint p0, address p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
        }

        function log(uint p0, address p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
        }

        function log(string memory p0, uint p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
        }

        function log(string memory p0, uint p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
        }

        function log(string memory p0, uint p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
        }

        function log(string memory p0, uint p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
        }

        function log(string memory p0, string memory p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
        }

        function log(string memory p0, string memory p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
        }

        function log(string memory p0, string memory p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
        }

        function log(string memory p0, string memory p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
        }

        function log(string memory p0, bool p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
        }

        function log(string memory p0, bool p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
        }

        function log(string memory p0, bool p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
        }

        function log(string memory p0, bool p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
        }

        function log(string memory p0, address p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
        }

        function log(string memory p0, address p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
        }

        function log(string memory p0, address p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
        }

        function log(string memory p0, address p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
        }

        function log(bool p0, uint p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
        }

        function log(bool p0, uint p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
        }

        function log(bool p0, uint p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
        }

        function log(bool p0, uint p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
        }

        function log(bool p0, string memory p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
        }

        function log(bool p0, string memory p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
        }

        function log(bool p0, string memory p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
        }

        function log(bool p0, string memory p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
        }

        function log(bool p0, bool p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
        }

        function log(bool p0, bool p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
        }

        function log(bool p0, bool p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
        }

        function log(bool p0, bool p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
        }

        function log(bool p0, address p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
        }

        function log(bool p0, address p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
        }

        function log(bool p0, address p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
        }

        function log(bool p0, address p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
        }

        function log(address p0, uint p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
        }

        function log(address p0, uint p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
        }

        function log(address p0, uint p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
        }

        function log(address p0, uint p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
        }

        function log(address p0, string memory p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
        }

        function log(address p0, string memory p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
        }

        function log(address p0, string memory p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
        }

        function log(address p0, string memory p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
        }

        function log(address p0, bool p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
        }

        function log(address p0, bool p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
        }

        function log(address p0, bool p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
        }

        function log(address p0, bool p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
        }

        function log(address p0, address p1, uint p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
        }

        function log(address p0, address p1, string memory p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
        }

        function log(address p0, address p1, bool p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
        }

        function log(address p0, address p1, address p2) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
        }

        function log(uint p0, uint p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, uint p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, string memory p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, bool p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
        }

        function log(uint p0, address p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, uint p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, string memory p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, bool p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
        }

        function log(string memory p0, address p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, uint p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, string memory p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, bool p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
        }

        function log(bool p0, address p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
        }

        function log(address p0, uint p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
        }

        function log(address p0, string memory p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
        }

        function log(address p0, bool p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, uint p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, uint p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, uint p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, uint p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, string memory p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, string memory p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, string memory p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, string memory p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, bool p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, bool p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, bool p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, bool p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, address p2, uint p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, address p2, string memory p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, address p2, bool p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
        }

        function log(address p0, address p1, address p2, address p3) internal view {
            _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
        }

    }

    // File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


    pragma solidity ^0.8.0;

    interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        );
    }

    // File: @openzeppelin/contracts/utils/math/SafeMath.sol


    // OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

    pragma solidity ^0.8.0;

    // CAUTION
    // This version of SafeMath should only be used with Solidity 0.8 or later,
    // because it relies on the compiler's built in overflow checks.

    /**
    * @dev Wrappers over Solidity's arithmetic operations.
    *
    * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
    * now has built in overflow checking.
    */
    library SafeMath {
        /**
        * @dev Returns the addition of two unsigned integers, with an overflow flag.
        *
        * _Available since v3.4._
        */
        function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                uint256 c = a + b;
                if (c < a) return (false, 0);
                return (true, c);
            }
        }

        /**
        * @dev Returns the substraction of two unsigned integers, with an overflow flag.
        *
        * _Available since v3.4._
        */
        function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b > a) return (false, 0);
                return (true, a - b);
            }
        }

        /**
        * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
        *
        * _Available since v3.4._
        */
        function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
                // benefit is lost if 'b' is also tested.
                // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
                if (a == 0) return (true, 0);
                uint256 c = a * b;
                if (c / a != b) return (false, 0);
                return (true, c);
            }
        }

        /**
        * @dev Returns the division of two unsigned integers, with a division by zero flag.
        *
        * _Available since v3.4._
        */
        function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b == 0) return (false, 0);
                return (true, a / b);
            }
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
        *
        * _Available since v3.4._
        */
        function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b == 0) return (false, 0);
                return (true, a % b);
            }
        }

        /**
        * @dev Returns the addition of two unsigned integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `+` operator.
        *
        * Requirements:
        *
        * - Addition cannot overflow.
        */
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            return a + b;
        }

        /**
        * @dev Returns the subtraction of two unsigned integers, reverting on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return a - b;
        }

        /**
        * @dev Returns the multiplication of two unsigned integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `*` operator.
        *
        * Requirements:
        *
        * - Multiplication cannot overflow.
        */
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            return a * b;
        }

        /**
        * @dev Returns the integer division of two unsigned integers, reverting on
        * division by zero. The result is rounded towards zero.
        *
        * Counterpart to Solidity's `/` operator.
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return a / b;
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * reverting when dividing by zero.
        *
        * Counterpart to Solidity's `%` operator. This function uses a `revert`
        * opcode (which leaves remaining gas untouched) while Solidity uses an
        * invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return a % b;
        }

        /**
        * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
        * overflow (when the result is negative).
        *
        * CAUTION: This function is deprecated because it requires allocating memory for the error
        * message unnecessarily. For custom revert reasons use {trySub}.
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
        function sub(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            unchecked {
                require(b <= a, errorMessage);
                return a - b;
            }
        }

        /**
        * @dev Returns the integer division of two unsigned integers, reverting with custom message on
        * division by zero. The result is rounded towards zero.
        *
        * Counterpart to Solidity's `/` operator. Note: this function uses a
        * `revert` opcode (which leaves remaining gas untouched) while Solidity
        * uses an invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function div(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            unchecked {
                require(b > 0, errorMessage);
                return a / b;
            }
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * reverting with custom message when dividing by zero.
        *
        * CAUTION: This function is deprecated because it requires allocating memory for the error
        * message unnecessarily. For custom revert reasons use {tryMod}.
        *
        * Counterpart to Solidity's `%` operator. This function uses a `revert`
        * opcode (which leaves remaining gas untouched) while Solidity uses an
        * invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function mod(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            unchecked {
                require(b > 0, errorMessage);
                return a % b;
            }
        }
    }

    // File: @openzeppelin/contracts/utils/Context.sol


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

    // File: @openzeppelin/contracts/access/Ownable.sol


    // OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

    pragma solidity ^0.8.0;


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

    // File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

    // File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


    // OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

    pragma solidity ^0.8.0;


    /**
    * @dev Interface for the optional metadata functions from the ERC20 standard.
    *
    * _Available since v4.1._
    */
    interface IERC20Metadata is IERC20 {
        /**
        * @dev Returns the name of the token.
        */
        function name() external view returns (string memory);

        /**
        * @dev Returns the symbol of the token.
        */
        function symbol() external view returns (string memory);

        /**
        * @dev Returns the decimals places of the token.
        */
        function decimals() external view returns (uint8);
    }

    // File: @openzeppelin/contracts/token/ERC20/ERC20.sol


    // OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

    pragma solidity ^0.8.0;




    /**
    * @dev Implementation of the {IERC20} interface.
    *
    * This implementation is agnostic to the way tokens are created. This means
    * that a supply mechanism has to be added in a derived contract using {_mint}.
    * For a generic mechanism see {ERC20PresetMinterPauser}.
    *
    * TIP: For a detailed writeup see our guide
    * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
    * to implement supply mechanisms].
    *
    * We have followed general OpenZeppelin Contracts guidelines: functions revert
    * instead returning `false` on failure. This behavior is nonetheless
    * conventional and does not conflict with the expectations of ERC20
    * applications.
    *
    * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
    * This allows applications to reconstruct the allowance for all accounts just
    * by listening to said events. Other implementations of the EIP may not emit
    * these events, as it isn't required by the specification.
    *
    * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
    * functions have been added to mitigate the well-known issues around setting
    * allowances. See {IERC20-approve}.
    */
    contract ERC20 is Context, IERC20, IERC20Metadata {
        mapping(address => uint256) private _balances;

        mapping(address => mapping(address => uint256)) private _allowances;

        uint256 private _totalSupply;

        string private _name;
        string private _symbol;

        /**
        * @dev Sets the values for {name} and {symbol}.
        *
        * The default value of {decimals} is 18. To select a different value for
        * {decimals} you should overload it.
        *
        * All two of these values are immutable: they can only be set once during
        * construction.
        */
        constructor(string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
        }

        /**
        * @dev Returns the name of the token.
        */
        function name() public view virtual override returns (string memory) {
            return _name;
        }

        /**
        * @dev Returns the symbol of the token, usually a shorter version of the
        * name.
        */
        function symbol() public view virtual override returns (string memory) {
            return _symbol;
        }

        /**
        * @dev Returns the number of decimals used to get its user representation.
        * For example, if `decimals` equals `2`, a balance of `505` tokens should
        * be displayed to a user as `5.05` (`505 / 10 ** 2`).
        *
        * Tokens usually opt for a value of 18, imitating the relationship between
        * Ether and Wei. This is the value {ERC20} uses, unless this function is
        * overridden;
        *
        * NOTE: This information is only used for _display_ purposes: it in
        * no way affects any of the arithmetic of the contract, including
        * {IERC20-balanceOf} and {IERC20-transfer}.
        */
        function decimals() public view virtual override returns (uint8) {
            return 18;
        }

        /**
        * @dev See {IERC20-totalSupply}.
        */
        function totalSupply() public view virtual override returns (uint256) {
            return _totalSupply;
        }

        /**
        * @dev See {IERC20-balanceOf}.
        */
        function balanceOf(address account) public view virtual override returns (uint256) {
            return _balances[account];
        }

        /**
        * @dev See {IERC20-transfer}.
        *
        * Requirements:
        *
        * - `to` cannot be the zero address.
        * - the caller must have a balance of at least `amount`.
        */
        function transfer(address to, uint256 amount) public virtual override returns (bool) {
            address owner = _msgSender();
            _transfer(owner, to, amount);
            return true;
        }

        /**
        * @dev See {IERC20-allowance}.
        */
        function allowance(address owner, address spender) public view virtual override returns (uint256) {
            return _allowances[owner][spender];
        }

        /**
        * @dev See {IERC20-approve}.
        *
        * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
        * `transferFrom`. This is semantically equivalent to an infinite approval.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        */
        function approve(address spender, uint256 amount) public virtual override returns (bool) {
            address owner = _msgSender();
            _approve(owner, spender, amount);
            return true;
        }

        /**
        * @dev See {IERC20-transferFrom}.
        *
        * Emits an {Approval} event indicating the updated allowance. This is not
        * required by the EIP. See the note at the beginning of {ERC20}.
        *
        * NOTE: Does not update the allowance if the current allowance
        * is the maximum `uint256`.
        *
        * Requirements:
        *
        * - `from` and `to` cannot be the zero address.
        * - `from` must have a balance of at least `amount`.
        * - the caller must have allowance for ``from``'s tokens of at least
        * `amount`.
        */
        function transferFrom(
            address from,
            address to,
            uint256 amount
        ) public virtual override returns (bool) {
            address spender = _msgSender();
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
            return true;
        }

        /**
        * @dev Atomically increases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in {IERC20-approve}.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        */
        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            address owner = _msgSender();
            _approve(owner, spender, _allowances[owner][spender] + addedValue);
            return true;
        }

        /**
        * @dev Atomically decreases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in {IERC20-approve}.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        * - `spender` must have allowance for the caller of at least
        * `subtractedValue`.
        */
        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            address owner = _msgSender();
            uint256 currentAllowance = _allowances[owner][spender];
            require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            unchecked {
                _approve(owner, spender, currentAllowance - subtractedValue);
            }

            return true;
        }

        /**
        * @dev Moves `amount` of tokens from `sender` to `recipient`.
        *
        * This internal function is equivalent to {transfer}, and can be used to
        * e.g. implement automatic token fees, slashing mechanisms, etc.
        *
        * Emits a {Transfer} event.
        *
        * Requirements:
        *
        * - `from` cannot be the zero address.
        * - `to` cannot be the zero address.
        * - `from` must have a balance of at least `amount`.
        */
        function _transfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");

            _beforeTokenTransfer(from, to, amount);

            uint256 fromBalance = _balances[from];
            require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[from] = fromBalance - amount;
            }
            _balances[to] += amount;

            emit Transfer(from, to, amount);

            _afterTokenTransfer(from, to, amount);
        }

        /** @dev Creates `amount` tokens and assigns them to `account`, increasing
        * the total supply.
        *
        * Emits a {Transfer} event with `from` set to the zero address.
        *
        * Requirements:
        *
        * - `account` cannot be the zero address.
        */
        function _mint(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");

            _beforeTokenTransfer(address(0), account, amount);

            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);

            _afterTokenTransfer(address(0), account, amount);
        }

        /**
        * @dev Destroys `amount` tokens from `account`, reducing the
        * total supply.
        *
        * Emits a {Transfer} event with `to` set to the zero address.
        *
        * Requirements:
        *
        * - `account` cannot be the zero address.
        * - `account` must have at least `amount` tokens.
        */
        function _burn(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: burn from the zero address");

            _beforeTokenTransfer(account, address(0), amount);

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
            }
            _totalSupply -= amount;

            emit Transfer(account, address(0), amount);

            _afterTokenTransfer(account, address(0), amount);
        }

        /**
        * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
        *
        * This internal function is equivalent to `approve`, and can be used to
        * e.g. set automatic allowances for certain subsystems, etc.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        *
        * - `owner` cannot be the zero address.
        * - `spender` cannot be the zero address.
        */
        function _approve(
            address owner,
            address spender,
            uint256 amount
        ) internal virtual {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }

        /**
        * @dev Spend `amount` form the allowance of `owner` toward `spender`.
        *
        * Does not update the allowance amount in case of infinite allowance.
        * Revert if not enough allowance is available.
        *
        * Might emit an {Approval} event.
        */
        function _spendAllowance(
            address owner,
            address spender,
            uint256 amount
        ) internal virtual {
            uint256 currentAllowance = allowance(owner, spender);
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "ERC20: insufficient allowance");
                unchecked {
                    _approve(owner, spender, currentAllowance - amount);
                }
            }
        }

        /**
        * @dev Hook that is called before any transfer of tokens. This includes
        * minting and burning.
        *
        * Calling conditions:
        *
        * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
        * will be transferred to `to`.
        * - when `from` is zero, `amount` tokens will be minted for `to`.
        * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
        * - `from` and `to` are never both zero.
        *
        * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
        */
        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {}

        /**
        * @dev Hook that is called after any transfer of tokens. This includes
        * minting and burning.
        *
        * Calling conditions:
        *
        * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
        * has been transferred to `to`.
        * - when `from` is zero, `amount` tokens have been minted for `to`.
        * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
        * - `from` and `to` are never both zero.
        *
        * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
        */
        function _afterTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {}
    }

    // File: @openzeppelin/contracts/security/ReentrancyGuard.sol


    // OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

    pragma solidity ^0.8.0;

    /**
    * @dev Contract module that helps prevent reentrant calls to a function.
    *
    * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
    * available, which can be applied to functions to make sure there are no nested
    * (reentrant) calls to them.
    *
    * Note that because there is a single `nonReentrant` guard, functions marked as
    * `nonReentrant` may not call one another. This can be worked around by making
    * those functions `private`, and then adding `external` `nonReentrant` entry
    * points to them.
    *
    * TIP: If you would like to learn more about reentrancy and alternative ways
    * to protect against it, check out our blog post
    * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
    */
    abstract contract ReentrancyGuard {
        // Booleans are more expensive than uint256 or any type that takes up a full
        // word because each write operation emits an extra SLOAD to first read the
        // slot's contents, replace the bits taken up by the boolean, and then write
        // back. This is the compiler's defense against contract upgrades and
        // pointer aliasing, and it cannot be disabled.

        // The values being non-zero value makes deployment a bit more expensive,
        // but in exchange the refund on every call to nonReentrant will be lower in
        // amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to
        // increase the likelihood of the full refund coming into effect.
        uint256 private constant _NOT_ENTERED = 1;
        uint256 private constant _ENTERED = 2;

        uint256 private _status;

        constructor() {
            _status = _NOT_ENTERED;
        }

        /**
        * @dev Prevents a contract from calling itself, directly or indirectly.
        * Calling a `nonReentrant` function from another `nonReentrant`
        * function is not supported. It is possible to prevent this from happening
        * by making the `nonReentrant` function external, and making it call a
        * `private` function that does the actual work.
        */
        modifier nonReentrant() {
            // On the first call to nonReentrant, _notEntered will be true
            require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

            // Any calls to nonReentrant after this point will fail
            _status = _ENTERED;

            _;

            // By storing the original value once again, a refund is triggered (see
            // https://eips.ethereum.org/EIPS/eip-2200)
            _status = _NOT_ENTERED;
        }
    }

    // File: contracts/presale.sol


    pragma solidity >=0.8.0;

    // import "@openzeppelin/contracts/access/AccessControl.sol";

//


interface ITalentScout {
    // /**
    //  * Lock the provided amount of Scout for "relativeReleaseTime" seconds starting from now
    //  * NOTE: This method is capped
    //  * NOTE: time definition in the locks is relative!
    //  */
    // function insertPresaleLock(
    //     address account,
    //     uint256 amount,
    //     uint256 relativeReleaseTime
    // ) external;

    // function destroyPresale(
    //     uint256 amount
    // ) external;

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // function transfer(address recipient, uint256 amount) external returns (bool) ;

}

// PreSale - $0.0000125

contract TalentScoutPresale is ReentrancyGuard, Ownable {
    
    using SafeMath for uint256;

    ITalentScout public talentScout;
    AggregatorV3Interface internal avaxPriceFeed;

    uint256 public buyerBalance;
    uint256 public saleStart;
    uint256 public saleEnd;
    uint256 public supply = 10_000_000_000 ether;
    uint256 public distributed;

    uint256 public salePriceUsd = 35000000000000; //$0.000035

    uint256 public presaleSupply = 10_000_000_000 * (10**18);

    mapping(address => uint256) public toRefund;

    // address of admin
    address adminAddress;

    //address of Talent Scout
    address public tsAddress;

    // Presale Locking Mechanism
    // bytes32 public constant CROWDSALE_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000001;
    address ZERO = 0x0000000000000000000000000000000000000000;    

    struct Locks {
        uint256 locked;
        uint256 releaseTime;
        bool released;
    }

    mapping(address => Locks[]) _locks;

    mapping (address => uint256) public _balances;

    uint256 public totalPresaleLockedAmount = 0;

    // avax deposit mapping
    mapping (address => uint256) public  _avaxDeposit;
    
    // mapping user total ts lock
    mapping (address => uint256) public _totalTsLock;

    /* EVENTS */
        event Bought(address account, uint256 amount);
        event Locked(address account, uint256 amount);
        event Released(address account, uint256 amount);

        event Buy(address indexed from, uint256 amount);
        event Destroyed(uint256 burnedFunds);
        event Transferred(address indexed to, uint256 amount);

        event withdrawnAVAXDeposit(address indexed to, uint256 amount);

        event Transfer(address indexed from, address indexed to, uint256 value); // IERC20.sol: Transfer(address, address, uint256)
    // 
    
    /* CONSTRUCTOR */
        constructor(
            // address _talentScout,
            uint256 _saleStart,
            uint256 _saleEnd
        ) {
            require(
                _saleStart > block.timestamp,
                "Sale start time should be in the future"
            );
            require(
                _saleStart < _saleEnd,
                "Sale end time should be after sale start time"
            );
            // talentScout = ITalentScout(_talentScout);
            saleStart = _saleStart;
            saleEnd = _saleEnd;

            avaxPriceFeed = AggregatorV3Interface(
                0x5498BB86BC934c8D34FDA08E81D444153d0D06aD
            );
            console.log(msg.sender);
        }
    //

    /* ONLY OWNER */

        function setAdmin(address _adminAddress) external onlyOwner{
            require(_adminAddress != address(0), "!nonZero");
            adminAddress = _adminAddress;
        }

        function updateSaleStart(uint256 _saleStart) external onlyOwner {
            require(saleStart < block.timestamp, "Sale has already started");
            require(
                _saleStart > block.timestamp,
                "Sale start time should be in the future"
            );

            saleStart = _saleStart;
        }

        function updateSaleEnd(uint256 _saleEnd) external onlyOwner {
            require(
                saleStart < _saleEnd,
                "Sale end time should be after sale start time"
            );
            require(
                _saleEnd > block.timestamp,
                "Sale end time should be in the future"
            );

            saleEnd = _saleEnd;
        }

        function destroy() public onlyOwner nonReentrant {
            // permit the destruction of the contract only an hour after the end of the sale,
            // this avoid any evil miner to trigger the function before the real ending time
            require(
                block.timestamp > saleEnd.add(1 hours),
                "Destruction not enabled yet"
            );
            require(
                supply > 0,
                "Remaining supply already burned or all funds sold"
            );
            uint256 remainingSupply = supply;

            // burn all unsold Scout
            supply = 0;
            destroyPresale(remainingSupply);

            emit Destroyed(remainingSupply);
        }

        function setTalentScout(address _talentScout) public onlyOwner {
            tsAddress = _talentScout;
            talentScout = ITalentScout(_talentScout);
        }

        /**
        * Destory the remaining presale supply
        */
        function destroyPresale(uint256 amount) public onlyOwner {
            _burn(address(this), amount);
        }
    // 

    /* GETTERS */
        function isSaleActive() public view returns (bool) {
            return block.timestamp >= saleStart && block.timestamp <= saleEnd;
        }

        function avaxUSD() public view returns (uint256) {
            (, int256 avaxPriceUsd, , , ) = avaxPriceFeed.latestRoundData();
            return uint256(avaxPriceUsd);
        }

        function salePriceAvax() public view returns (uint256) {
            (, int256 avaxPriceUsd, , , ) = avaxPriceFeed.latestRoundData();
            uint256 priceInAvax = uint256(avaxPriceUsd)
                .mul(1e10)
                .mul(salePriceUsd)
                .div(1e18);
            return priceInAvax;
        }

        function computeTokensAmount(uint256 funds) public view returns (uint256, uint256) {
            uint256 salePrice = salePriceAvax();
            uint256 tokensToBuy = funds.div(salePrice).mul(1e18);
            uint256 newMinted = distributed.add(tokensToBuy);

            uint256 exceedingEther;

            if (newMinted >= supply) {
                uint256 exceedingTokens = newMinted.sub(supply);
                // Change the tokens to buy to the new number
                tokensToBuy = tokensToBuy.sub(exceedingTokens);

                // Recompute the available funds
                // Convert the exceedingTokens to ether and refund that ether
                uint256 etherUsed = funds.sub(tokensToBuy.mul(salePrice).div(1e18));
                exceedingEther = funds.sub(etherUsed);
            }
            return (tokensToBuy, exceedingEther);
        }

        /**
            * Retrieve the locks state for the account
        */
        function locksOf(address account) public view returns (Locks[] memory) {
            return _locks[account];
        }

        /**
            * Get the number of locks for an account
        */
        function getLockNumber(address account) public view returns (uint256) {
            return _locks[account].length;
        }

    //

    /* EXTERNAL OR PUBLIC */
        function refundAVAX() external {
            require(_balances[msg.sender] > 0, "Refunding zero tokens");

            uint256 amount = _balances[msg.sender];

            _basicTransfer(address(this), msg.sender, _balances[msg.sender]);

            emit Transferred(msg.sender, amount);

        }

        receive() external payable {
            // revert("Direct funds receiving not enabled, call 'buy' directly");
        }

        function buy() public payable nonReentrant {
            require(isSaleActive(), "Sale is not active");

            require(supply > 0, "Presale ended, everything was sold");

            // compute the amount of token to buy based on the current rate
            (uint256 tokensToBuy, uint256 exceedingEther) = computeTokensAmount(
                msg.value
            );

            // refund eventually exceeding eth
            if (exceedingEther > 0) {
                uint256 _toRefund = toRefund[msg.sender] + exceedingEther;
                toRefund[msg.sender] = _toRefund;
            }

            // compute buyer balance
            buyerBalance = _balances[msg.sender];

            distributed = distributed.add(tokensToBuy);
            supply = supply.sub(tokensToBuy);
            // Mint new tokens for each submission
            saleLock(msg.sender, tokensToBuy);

            // avax deposit of user is stored in _avaxDeposit
            _avaxDeposit[msg.sender] = _avaxDeposit[msg.sender].add(msg.value);

            _totalTsLock[msg.sender] = _totalTsLock[msg.sender].add(tokensToBuy); // add to user total ts lock

            emit Buy(msg.sender, tokensToBuy);
        }    

        function refund() public nonReentrant {
            require(toRefund[msg.sender] > 0, "Nothing to refund");

            uint256 _refund = toRefund[msg.sender];
            toRefund[msg.sender] = 0;

            // avoid impossibility to refund funds in case transaction are executed from a contract
            // (like gnosis safe multisig), this is a workaround for the 2300 fixed gas problem
            (bool refundSuccess, ) = msg.sender.call{value: _refund}("");
            require(refundSuccess, "Unable to refund exceeding ether");
        }

        /**
            * Get the amount of locked tokens for an account
        */

        /**
            * Release the amount of locked presale amount
        */
        function releasePresaleAmount(uint256 lock_id) public {
            require(
                _locks[msg.sender].length > 0,
                "No locks found for your account"
            );
            require(
                _locks[msg.sender].length - 1 >= lock_id,
                "Lock index too high"
            );
            require(!_locks[msg.sender][lock_id].released, "Lock already released");
            require(
                block.timestamp > _locks[msg.sender][lock_id].releaseTime,
                "Lock not yet ready to be released"
            );
            require(tsAddress != address(0), "Talent Scout not set");

            // refresh the amount of tokens locked
            totalPresaleLockedAmount -= _locks[msg.sender][lock_id].locked;

            // mark the lock as realeased
            _locks[msg.sender][lock_id].released = true;

            // transfer the tokens to the sender
            
            // payable(msg.sender).transfer(_locks[msg.sender][lock_id].locked);
            // _basicTransfer(address(talentScout), msg.sender, _locks[msg.sender][lock_id].locked);
            
            talentScout.transferFrom(tsAddress, msg.sender, _locks[msg.sender][lock_id].locked);

            payable(tsAddress).transfer(_avaxDeposit[msg.sender]);

            _avaxDeposit[msg.sender] = 0;

            _totalTsLock[msg.sender] = _totalTsLock[msg.sender].sub(_locks[msg.sender][lock_id].locked);

            emit Released(msg.sender, _locks[msg.sender][lock_id].locked);
        }


        // withdraw avax deposit
        function withdrawAVAXDeposit() external {
            
            require(block.timestamp < saleEnd, "Sale ended");
            require(_avaxDeposit[msg.sender] > 0, "No AVAX deposit to withdraw");
            
            payable(msg.sender).transfer(_avaxDeposit[msg.sender]);


            distributed = distributed.sub(_totalTsLock[msg.sender]);

            totalPresaleLockedAmount = totalPresaleLockedAmount.sub(_totalTsLock[msg.sender]);
            
            supply = supply.add(_totalTsLock[msg.sender]);

            _totalTsLock[msg.sender] = 0;

            delete _locks[msg.sender];
            
            _avaxDeposit[msg.sender] = 0;


            emit withdrawnAVAXDeposit(msg.sender, _avaxDeposit[msg.sender]);
        
        }

    //

    /* INTERNAL */
        function _burn(address account, uint256 amount) internal virtual {
            require (account != address(0), "ERC20: burn amount exceeds balance");

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

            // unchecked {
            //     _balances[account] = accountBalance.sub(amount);
            //     _balances[ZERO] = _balances[ZERO].add(amount);
            // }
    
        }

        // Release times
            // 1) 10% 180 days
            // 2) 10% 240 days
            // 3) 10% 270 days
            // 4) 10% 300 days
            // 5) 10% 330 days
            // 6) 10% 1 year
            // 7) 20% 15 months
            // 8) 20% 18 months
        function saleLock(address _account, uint256 _scoutToLock) private {
            // 10% released after 180 days
            uint256 m6Release = (_scoutToLock.mul(10)).div(100);
            // 10% released after 240 days
            uint256 m8Release = (_scoutToLock.mul(10)).div(100);
            // 10% released after 270 days
            uint256 m9Release = (_scoutToLock.mul(10)).div(100);
            // 10% released after 300 days
            uint256 m10Release = (_scoutToLock.mul(10)).div(100);
            // 10% released after 330 days
            uint256 m11Release = (_scoutToLock.mul(10)).div(100);
            // 10% released after 1 year
            uint256 m12Release = (_scoutToLock.mul(10)).div(100);
            // 20% released after 15 months
            uint256 m15Release = (_scoutToLock.mul(20)).div(100);
            // 20% released after 18 months
            uint256 m18Release = (_scoutToLock.mul(20)).div(100);
            
            insertPresaleLock(_account, m6Release, 0 days);
            insertPresaleLock(_account, m8Release, 0 days);
            insertPresaleLock(_account, m9Release, 0 days);
            insertPresaleLock(_account, m10Release, 0 days);
            insertPresaleLock(_account, m11Release, 0 days);
            insertPresaleLock(_account, m12Release, 0 days);
            insertPresaleLock(_account, m15Release, 0 days);
            insertPresaleLock(_account, m18Release, 0 days);
        }

        function _basicTransfer( address sender, address recipient, uint256 amount ) internal returns (bool) {
            
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            // if(!isReflectionExempt[recipient]) { 
            //     try reflectionDistributor.setShare(recipient, _balances[recipient]) {} catch {} 
            // }
            emit Transfer(sender, recipient, amount);
            return true;
        }

        /**
            * Lock the provided amount of Scout for "_relative_releaseTime" seconds starting from now
            * NOTE: This method is capped
            * NOTE: time definition in the locks is relative!
        */
        function insertPresaleLock( address account, uint256 _amount, uint256 _relative_releaseTime ) internal {
            
            require( totalPresaleLockedAmount + _amount <= presaleSupply, "Unable to lock the defined amount, cap exceeded" );

            Locks memory lock_ = Locks(
            {
                locked: _amount,
                releaseTime: block.timestamp + _relative_releaseTime,
                released: false
            });
            
            _locks[account].push(lock_);

            totalPresaleLockedAmount += _amount;

            emit Locked(account, _amount);
        }

    // 

}