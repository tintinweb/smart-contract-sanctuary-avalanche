// SPDX-License-Identifier: GPL-3.0-or-later

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.5.0;

contract DSTest {
    event log                    (string);
    event logs                   (bytes);

    event log_address            (address);
    event log_bytes32            (bytes32);
    event log_int                (int);
    event log_uint               (uint);
    event log_bytes              (bytes);
    event log_string             (string);

    event log_named_address      (string key, address val);
    event log_named_bytes32      (string key, bytes32 val);
    event log_named_decimal_int  (string key, int val, uint decimals);
    event log_named_decimal_uint (string key, uint val, uint decimals);
    event log_named_int          (string key, int val);
    event log_named_uint         (string key, uint val);
    event log_named_bytes        (string key, bytes val);
    event log_named_string       (string key, string val);

    bool public IS_TEST = true;
    bool private _failed;

    address constant HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    modifier mayRevert() { _; }
    modifier testopts(string memory) { _; }

    function failed() public returns (bool) {
        if (_failed) {
            return _failed;
        } else {
            bool globalFailed = false;
            if (hasHEVMContext()) {
                (, bytes memory retdata) = HEVM_ADDRESS.call(
                    abi.encodePacked(
                        bytes4(keccak256("load(address,bytes32)")),
                        abi.encode(HEVM_ADDRESS, bytes32("failed"))
                    )
                );
                globalFailed = abi.decode(retdata, (bool));
            }
            return globalFailed;
        }
    } 

    function fail() internal {
        if (hasHEVMContext()) {
            (bool status, ) = HEVM_ADDRESS.call(
                abi.encodePacked(
                    bytes4(keccak256("store(address,bytes32,bytes32)")),
                    abi.encode(HEVM_ADDRESS, bytes32("failed"), bytes32(uint256(0x01)))
                )
            );
            status; // Silence compiler warnings
        }
        _failed = true;
    }

    function hasHEVMContext() internal view returns (bool) {
        uint256 hevmCodeSize = 0;
        assembly {
            hevmCodeSize := extcodesize(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D)
        }
        return hevmCodeSize > 0;
    }

    modifier logs_gas() {
        uint startGas = gasleft();
        _;
        uint endGas = gasleft();
        emit log_named_uint("gas", startGas - endGas);
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory err) internal {
        if (!condition) {
            emit log_named_string("Error", err);
            assertTrue(condition);
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }
    function assertEq(address a, address b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bytes32]");
            emit log_named_bytes32("  Expected", b);
            emit log_named_bytes32("    Actual", a);
            fail();
        }
    }
    function assertEq(bytes32 a, bytes32 b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq32(bytes32 a, bytes32 b) internal {
        assertEq(a, b);
    }
    function assertEq32(bytes32 a, bytes32 b, string memory err) internal {
        assertEq(a, b, err);
    }

    function assertEq(int a, int b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [int]");
            emit log_named_int("  Expected", b);
            emit log_named_int("    Actual", a);
            fail();
        }
    }
    function assertEq(int a, int b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            fail();
        }
    }
    function assertEq(uint a, uint b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEqDecimal(int a, int b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal int]");
            emit log_named_decimal_int("  Expected", b, decimals);
            emit log_named_decimal_int("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Expected", b, decimals);
            emit log_named_decimal_uint("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }

    function assertGt(uint a, uint b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGt(uint a, uint b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGt(int a, int b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGt(int a, int b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGtDecimal(int a, int b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }

    function assertGe(uint a, uint b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGe(uint a, uint b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGe(int a, int b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGe(int a, int b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGeDecimal(int a, int b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertLt(uint a, uint b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLt(uint a, uint b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLt(int a, int b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLt(int a, int b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLtDecimal(int a, int b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }

    function assertLe(uint a, uint b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLe(uint a, uint b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLe(int a, int b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLe(int a, int b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLeDecimal(int a, int b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLeDecimal(a, b, decimals);
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertEq(string memory a, string memory b) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log("Error: a == b not satisfied [string]");
            emit log_named_string("  Expected", b);
            emit log_named_string("    Actual", a);
            fail();
        }
    }
    function assertEq(string memory a, string memory b, string memory err) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function checkEq0(bytes memory a, bytes memory b) internal pure returns (bool ok) {
        ok = true;
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }
    }
    function assertEq0(bytes memory a, bytes memory b) internal {
        if (!checkEq0(a, b)) {
            emit log("Error: a == b not satisfied [bytes]");
            emit log_named_bytes("  Expected", b);
            emit log_named_bytes("    Actual", a);
            fail();
        }
    }
    function assertEq0(bytes memory a, bytes memory b, string memory err) internal {
        if (!checkEq0(a, b)) {
            emit log_named_string("Error", err);
            assertEq0(a, b);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {StdStorage} from "./StdStorage.sol";
import {Vm, VmSafe} from "./Vm.sol";

abstract contract CommonBase {
    // Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    // console.sol and console2.sol work by executing a staticcall to this address.
    address internal constant CONSOLE = 0x000000000000000000636F6e736F6c652e6c6f67;
    // Default address for tx.origin and msg.sender, 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38.
    address internal constant DEFAULT_SENDER = address(uint160(uint256(keccak256("foundry default caller"))));
    // Address of the test contract, deployed by the DEFAULT_SENDER.
    address internal constant DEFAULT_TEST_CONTRACT = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
    // Deterministic deployment address of the Multicall3 contract.
    address internal constant MULTICALL3_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;

    uint256 internal constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    Vm internal constant vm = Vm(VM_ADDRESS);
    StdStorage internal stdstore;
}

abstract contract TestBase is CommonBase {}

abstract contract ScriptBase is CommonBase {
    // Used when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    address internal constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    VmSafe internal constant vmSafe = VmSafe(VM_ADDRESS);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

// 💬 ABOUT
// Standard Library's default Script.

// 🧩 MODULES
import {ScriptBase} from "./Base.sol";
import {console} from "./console.sol";
import {console2} from "./console2.sol";
import {StdChains} from "./StdChains.sol";
import {StdCheatsSafe} from "./StdCheats.sol";
import {stdJson} from "./StdJson.sol";
import {stdMath} from "./StdMath.sol";
import {StdStorage, stdStorageSafe} from "./StdStorage.sol";
import {StdUtils} from "./StdUtils.sol";
import {VmSafe} from "./Vm.sol";

// 📦 BOILERPLATE
import {ScriptBase} from "./Base.sol";

// ⭐️ SCRIPT
abstract contract Script is StdChains, StdCheatsSafe, StdUtils, ScriptBase {
    // Note: IS_SCRIPT() must return true.
    bool public IS_SCRIPT = true;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {DSTest} from "ds-test/test.sol";
import {stdMath} from "./StdMath.sol";

abstract contract StdAssertions is DSTest {
    event log_array(uint256[] val);
    event log_array(int256[] val);
    event log_array(address[] val);
    event log_named_array(string key, uint256[] val);
    event log_named_array(string key, int256[] val);
    event log_named_array(string key, address[] val);

    function fail(string memory err) internal virtual {
        emit log_named_string("Error", err);
        fail();
    }

    function assertFalse(bool data) internal virtual {
        assertTrue(!data);
    }

    function assertFalse(bool data, string memory err) internal virtual {
        assertTrue(!data, err);
    }

    function assertEq(bool a, bool b) internal virtual {
        if (a != b) {
            emit log("Error: a == b not satisfied [bool]");
            emit log_named_string("  Expected", b ? "true" : "false");
            emit log_named_string("    Actual", a ? "true" : "false");
            fail();
        }
    }

    function assertEq(bool a, bool b, string memory err) internal virtual {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes memory a, bytes memory b) internal virtual {
        assertEq0(a, b);
    }

    function assertEq(bytes memory a, bytes memory b, string memory err) internal virtual {
        assertEq0(a, b, err);
    }

    function assertEq(uint256[] memory a, uint256[] memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [uint[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(int256[] memory a, int256[] memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [int[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(address[] memory a, address[] memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [address[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(uint256[] memory a, uint256[] memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(int256[] memory a, int256[] memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(address[] memory a, address[] memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    // Legacy helper
    function assertEqUint(uint256 a, uint256 b) internal virtual {
        assertEq(uint256(a), uint256(b));
    }

    function assertApproxEqAbs(uint256 a, uint256 b, uint256 maxDelta) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            emit log_named_uint(" Max Delta", maxDelta);
            emit log_named_uint("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqAbs(uint256 a, uint256 b, uint256 maxDelta, string memory err) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string("Error", err);
            assertApproxEqAbs(a, b, maxDelta);
        }
    }

    function assertApproxEqAbsDecimal(uint256 a, uint256 b, uint256 maxDelta, uint256 decimals) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_decimal_uint("  Expected", b, decimals);
            emit log_named_decimal_uint("    Actual", a, decimals);
            emit log_named_decimal_uint(" Max Delta", maxDelta, decimals);
            emit log_named_decimal_uint("     Delta", delta, decimals);
            fail();
        }
    }

    function assertApproxEqAbsDecimal(uint256 a, uint256 b, uint256 maxDelta, uint256 decimals, string memory err)
        internal
        virtual
    {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string("Error", err);
            assertApproxEqAbsDecimal(a, b, maxDelta, decimals);
        }
    }

    function assertApproxEqAbs(int256 a, int256 b, uint256 maxDelta) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [int]");
            emit log_named_int("  Expected", b);
            emit log_named_int("    Actual", a);
            emit log_named_uint(" Max Delta", maxDelta);
            emit log_named_uint("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqAbs(int256 a, int256 b, uint256 maxDelta, string memory err) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string("Error", err);
            assertApproxEqAbs(a, b, maxDelta);
        }
    }

    function assertApproxEqAbsDecimal(int256 a, int256 b, uint256 maxDelta, uint256 decimals) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [int]");
            emit log_named_decimal_int("  Expected", b, decimals);
            emit log_named_decimal_int("    Actual", a, decimals);
            emit log_named_decimal_uint(" Max Delta", maxDelta, decimals);
            emit log_named_decimal_uint("     Delta", delta, decimals);
            fail();
        }
    }

    function assertApproxEqAbsDecimal(int256 a, int256 b, uint256 maxDelta, uint256 decimals, string memory err)
        internal
        virtual
    {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string("Error", err);
            assertApproxEqAbsDecimal(a, b, maxDelta, decimals);
        }
    }

    function assertApproxEqRel(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta // An 18 decimal fixed point number, where 1e18 == 100%
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("    Expected", b);
            emit log_named_uint("      Actual", a);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRel(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        string memory err
    ) internal virtual {
        if (b == 0) return assertEq(a, b, err); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string("Error", err);
            assertApproxEqRel(a, b, maxPercentDelta);
        }
    }

    function assertApproxEqRelDecimal(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 decimals
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_decimal_uint("    Expected", b, decimals);
            emit log_named_decimal_uint("      Actual", a, decimals);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRelDecimal(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 decimals,
        string memory err
    ) internal virtual {
        if (b == 0) return assertEq(a, b, err); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string("Error", err);
            assertApproxEqRelDecimal(a, b, maxPercentDelta, decimals);
        }
    }

    function assertApproxEqRel(int256 a, int256 b, uint256 maxPercentDelta) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [int]");
            emit log_named_int("    Expected", b);
            emit log_named_int("      Actual", a);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRel(int256 a, int256 b, uint256 maxPercentDelta, string memory err) internal virtual {
        if (b == 0) return assertEq(a, b, err); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string("Error", err);
            assertApproxEqRel(a, b, maxPercentDelta);
        }
    }

    function assertApproxEqRelDecimal(int256 a, int256 b, uint256 maxPercentDelta, uint256 decimals) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [int]");
            emit log_named_decimal_int("    Expected", b, decimals);
            emit log_named_decimal_int("      Actual", a, decimals);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRelDecimal(int256 a, int256 b, uint256 maxPercentDelta, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (b == 0) return assertEq(a, b, err); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string("Error", err);
            assertApproxEqRelDecimal(a, b, maxPercentDelta, decimals);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {VmSafe} from "./Vm.sol";

/**
 * StdChains provides information about EVM compatible chains that can be used in scripts/tests.
 * For each chain, the chain's name, chain ID, and a default RPC URL are provided. Chains are
 * identified by their alias, which is the same as the alias in the `[rpc_endpoints]` section of
 * the `foundry.toml` file. For best UX, ensure the alias in the `foundry.toml` file match the
 * alias used in this contract, which can be found as the first argument to the
 * `setChainWithDefaultRpcUrl` call in the `initialize` function.
 *
 * There are two main ways to use this contract:
 *   1. Set a chain with `setChain(string memory chainAlias, ChainData memory chain)` or
 *      `setChain(string memory chainAlias, Chain memory chain)`
 *   2. Get a chain with `getChain(string memory chainAlias)` or `getChain(uint256 chainId)`.
 *
 * The first time either of those are used, chains are initialized with the default set of RPC URLs.
 * This is done in `initialize`, which uses `setChainWithDefaultRpcUrl`. Defaults are recorded in
 * `defaultRpcUrls`.
 *
 * The `setChain` function is straightforward, and it simply saves off the given chain data.
 *
 * The `getChain` methods use `getChainWithUpdatedRpcUrl` to return a chain. For example, let's say
 * we want to retrieve `mainnet`'s RPC URL:
 *   - If you haven't set any mainnet chain info with `setChain`, you haven't specified that
 *     chain in `foundry.toml` and no env var is set, the default data and RPC URL will be returned.
 *   - If you have set a mainnet RPC URL in `foundry.toml` it will return that, if valid (e.g. if
 *     a URL is given or if an environment variable is given and that environment variable exists).
 *     Otherwise, the default data is returned.
 *   - If you specified data with `setChain` it will return that.
 *
 * Summarizing the above, the prioritization hierarchy is `setChain` -> `foundry.toml` -> environment variable -> defaults.
 */
abstract contract StdChains {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    bool private initialized;

    struct ChainData {
        string name;
        uint256 chainId;
        string rpcUrl;
    }

    struct Chain {
        // The chain name.
        string name;
        // The chain's Chain ID.
        uint256 chainId;
        // The chain's alias. (i.e. what gets specified in `foundry.toml`).
        string chainAlias;
        // A default RPC endpoint for this chain.
        // NOTE: This default RPC URL is included for convenience to facilitate quick tests and
        // experimentation. Do not use this RPC URL for production test suites, CI, or other heavy
        // usage as you will be throttled and this is a disservice to others who need this endpoint.
        string rpcUrl;
    }

    // Maps from the chain's alias (matching the alias in the `foundry.toml` file) to chain data.
    mapping(string => Chain) private chains;
    // Maps from the chain's alias to it's default RPC URL.
    mapping(string => string) private defaultRpcUrls;
    // Maps from a chain ID to it's alias.
    mapping(uint256 => string) private idToAlias;

    // The RPC URL will be fetched from config or defaultRpcUrls if possible.
    function getChain(string memory chainAlias) internal virtual returns (Chain memory chain) {
        require(bytes(chainAlias).length != 0, "StdChains getChain(string): Chain alias cannot be the empty string.");

        initialize();
        chain = chains[chainAlias];
        require(
            chain.chainId != 0,
            string(abi.encodePacked("StdChains getChain(string): Chain with alias \"", chainAlias, "\" not found."))
        );

        chain = getChainWithUpdatedRpcUrl(chainAlias, chain);
    }

    function getChain(uint256 chainId) internal virtual returns (Chain memory chain) {
        require(chainId != 0, "StdChains getChain(uint256): Chain ID cannot be 0.");
        initialize();
        string memory chainAlias = idToAlias[chainId];

        chain = chains[chainAlias];

        require(
            chain.chainId != 0,
            string(abi.encodePacked("StdChains getChain(uint256): Chain with ID ", vm.toString(chainId), " not found."))
        );

        chain = getChainWithUpdatedRpcUrl(chainAlias, chain);
    }

    // set chain info, with priority to argument's rpcUrl field.
    function setChain(string memory chainAlias, ChainData memory chain) internal virtual {
        require(
            bytes(chainAlias).length != 0,
            "StdChains setChain(string,ChainData): Chain alias cannot be the empty string."
        );

        require(chain.chainId != 0, "StdChains setChain(string,ChainData): Chain ID cannot be 0.");

        initialize();
        string memory foundAlias = idToAlias[chain.chainId];

        require(
            bytes(foundAlias).length == 0 || keccak256(bytes(foundAlias)) == keccak256(bytes(chainAlias)),
            string(
                abi.encodePacked(
                    "StdChains setChain(string,ChainData): Chain ID ",
                    vm.toString(chain.chainId),
                    " already used by \"",
                    foundAlias,
                    "\"."
                )
            )
        );

        uint256 oldChainId = chains[chainAlias].chainId;
        delete idToAlias[oldChainId];

        chains[chainAlias] =
            Chain({name: chain.name, chainId: chain.chainId, chainAlias: chainAlias, rpcUrl: chain.rpcUrl});
        idToAlias[chain.chainId] = chainAlias;
    }

    // set chain info, with priority to argument's rpcUrl field.
    function setChain(string memory chainAlias, Chain memory chain) internal virtual {
        setChain(chainAlias, ChainData({name: chain.name, chainId: chain.chainId, rpcUrl: chain.rpcUrl}));
    }

    function _toUpper(string memory str) private pure returns (string memory) {
        bytes memory strb = bytes(str);
        bytes memory copy = new bytes(strb.length);
        for (uint256 i = 0; i < strb.length; i++) {
            bytes1 b = strb[i];
            if (b >= 0x61 && b <= 0x7A) {
                copy[i] = bytes1(uint8(b) - 32);
            } else {
                copy[i] = b;
            }
        }
        return string(copy);
    }

    // lookup rpcUrl, in descending order of priority:
    // current -> config (foundry.toml) -> environment variable -> default
    function getChainWithUpdatedRpcUrl(string memory chainAlias, Chain memory chain) private returns (Chain memory) {
        if (bytes(chain.rpcUrl).length == 0) {
            try vm.rpcUrl(chainAlias) returns (string memory configRpcUrl) {
                chain.rpcUrl = configRpcUrl;
            } catch (bytes memory err) {
                chain.rpcUrl =
                    vm.envOr(string(abi.encodePacked(_toUpper(chainAlias), "_RPC_URL")), defaultRpcUrls[chainAlias]);
                // distinguish 'not found' from 'cannot read'
                bytes memory notFoundError =
                    abi.encodeWithSignature("CheatCodeError", string(abi.encodePacked("invalid rpc url ", chainAlias)));
                if (keccak256(notFoundError) != keccak256(err) || bytes(chain.rpcUrl).length == 0) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, err), mload(err))
                    }
                }
            }
        }
        return chain;
    }

    function initialize() private {
        if (initialized) return;

        initialized = true;

        // If adding an RPC here, make sure to test the default RPC URL in `testRpcs`
        setChainWithDefaultRpcUrl("anvil", ChainData("Anvil", 31337, "http://127.0.0.1:8545"));
        setChainWithDefaultRpcUrl(
            "mainnet", ChainData("Mainnet", 1, "https://mainnet.infura.io/v3/6770454bc6ea42c58aac12978531b93f")
        );
        setChainWithDefaultRpcUrl(
            "goerli", ChainData("Goerli", 5, "https://goerli.infura.io/v3/6770454bc6ea42c58aac12978531b93f")
        );
        setChainWithDefaultRpcUrl(
            "sepolia", ChainData("Sepolia", 11155111, "https://sepolia.infura.io/v3/6770454bc6ea42c58aac12978531b93f")
        );
        setChainWithDefaultRpcUrl("optimism", ChainData("Optimism", 10, "https://mainnet.optimism.io"));
        setChainWithDefaultRpcUrl("optimism_goerli", ChainData("Optimism Goerli", 420, "https://goerli.optimism.io"));
        setChainWithDefaultRpcUrl("arbitrum_one", ChainData("Arbitrum One", 42161, "https://arb1.arbitrum.io/rpc"));
        setChainWithDefaultRpcUrl(
            "arbitrum_one_goerli", ChainData("Arbitrum One Goerli", 421613, "https://goerli-rollup.arbitrum.io/rpc")
        );
        setChainWithDefaultRpcUrl("arbitrum_nova", ChainData("Arbitrum Nova", 42170, "https://nova.arbitrum.io/rpc"));
        setChainWithDefaultRpcUrl("polygon", ChainData("Polygon", 137, "https://polygon-rpc.com"));
        setChainWithDefaultRpcUrl(
            "polygon_mumbai", ChainData("Polygon Mumbai", 80001, "https://rpc-mumbai.maticvigil.com")
        );
        setChainWithDefaultRpcUrl("avalanche", ChainData("Avalanche", 43114, "https://api.avax.network/ext/bc/C/rpc"));
        setChainWithDefaultRpcUrl(
            "avalanche_fuji", ChainData("Avalanche Fuji", 43113, "https://api.avax-test.network/ext/bc/C/rpc")
        );
        setChainWithDefaultRpcUrl(
            "bnb_smart_chain", ChainData("BNB Smart Chain", 56, "https://bsc-dataseed1.binance.org")
        );
        setChainWithDefaultRpcUrl(
            "bnb_smart_chain_testnet",
            ChainData("BNB Smart Chain Testnet", 97, "https://rpc.ankr.com/bsc_testnet_chapel")
        );
        setChainWithDefaultRpcUrl("gnosis_chain", ChainData("Gnosis Chain", 100, "https://rpc.gnosischain.com"));
    }

    // set chain info, with priority to chainAlias' rpc url in foundry.toml
    function setChainWithDefaultRpcUrl(string memory chainAlias, ChainData memory chain) private {
        string memory rpcUrl = chain.rpcUrl;
        defaultRpcUrls[chainAlias] = rpcUrl;
        chain.rpcUrl = "";
        setChain(chainAlias, chain);
        chain.rpcUrl = rpcUrl; // restore argument
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {StdStorage, stdStorage} from "./StdStorage.sol";
import {Vm} from "./Vm.sol";

abstract contract StdCheatsSafe {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    bool private gasMeteringOff;

    // Data structures to parse Transaction objects from the broadcast artifact
    // that conform to EIP1559. The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct RawTx1559 {
        string[] arguments;
        address contractAddress;
        string contractName;
        // json value name = function
        string functionSig;
        bytes32 hash;
        // json value name = tx
        RawTx1559Detail txDetail;
        // json value name = type
        string opcode;
    }

    struct RawTx1559Detail {
        AccessList[] accessList;
        bytes data;
        address from;
        bytes gas;
        bytes nonce;
        address to;
        bytes txType;
        bytes value;
    }

    struct Tx1559 {
        string[] arguments;
        address contractAddress;
        string contractName;
        string functionSig;
        bytes32 hash;
        Tx1559Detail txDetail;
        string opcode;
    }

    struct Tx1559Detail {
        AccessList[] accessList;
        bytes data;
        address from;
        uint256 gas;
        uint256 nonce;
        address to;
        uint256 txType;
        uint256 value;
    }

    // Data structures to parse Transaction objects from the broadcast artifact
    // that DO NOT conform to EIP1559. The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct TxLegacy {
        string[] arguments;
        address contractAddress;
        string contractName;
        string functionSig;
        string hash;
        string opcode;
        TxDetailLegacy transaction;
    }

    struct TxDetailLegacy {
        AccessList[] accessList;
        uint256 chainId;
        bytes data;
        address from;
        uint256 gas;
        uint256 gasPrice;
        bytes32 hash;
        uint256 nonce;
        bytes1 opcode;
        bytes32 r;
        bytes32 s;
        uint256 txType;
        address to;
        uint8 v;
        uint256 value;
    }

    struct AccessList {
        address accessAddress;
        bytes32[] storageKeys;
    }

    // Data structures to parse Receipt objects from the broadcast artifact.
    // The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct RawReceipt {
        bytes32 blockHash;
        bytes blockNumber;
        address contractAddress;
        bytes cumulativeGasUsed;
        bytes effectiveGasPrice;
        address from;
        bytes gasUsed;
        RawReceiptLog[] logs;
        bytes logsBloom;
        bytes status;
        address to;
        bytes32 transactionHash;
        bytes transactionIndex;
    }

    struct Receipt {
        bytes32 blockHash;
        uint256 blockNumber;
        address contractAddress;
        uint256 cumulativeGasUsed;
        uint256 effectiveGasPrice;
        address from;
        uint256 gasUsed;
        ReceiptLog[] logs;
        bytes logsBloom;
        uint256 status;
        address to;
        bytes32 transactionHash;
        uint256 transactionIndex;
    }

    // Data structures to parse the entire broadcast artifact, assuming the
    // transactions conform to EIP1559.

    struct EIP1559ScriptArtifact {
        string[] libraries;
        string path;
        string[] pending;
        Receipt[] receipts;
        uint256 timestamp;
        Tx1559[] transactions;
        TxReturn[] txReturns;
    }

    struct RawEIP1559ScriptArtifact {
        string[] libraries;
        string path;
        string[] pending;
        RawReceipt[] receipts;
        TxReturn[] txReturns;
        uint256 timestamp;
        RawTx1559[] transactions;
    }

    struct RawReceiptLog {
        // json value = address
        address logAddress;
        bytes32 blockHash;
        bytes blockNumber;
        bytes data;
        bytes logIndex;
        bool removed;
        bytes32[] topics;
        bytes32 transactionHash;
        bytes transactionIndex;
        bytes transactionLogIndex;
    }

    struct ReceiptLog {
        // json value = address
        address logAddress;
        bytes32 blockHash;
        uint256 blockNumber;
        bytes data;
        uint256 logIndex;
        bytes32[] topics;
        uint256 transactionIndex;
        uint256 transactionLogIndex;
        bool removed;
    }

    struct TxReturn {
        string internalType;
        string value;
    }

    function assumeNoPrecompiles(address addr) internal virtual {
        // Assembly required since `block.chainid` was introduced in 0.8.0.
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        assumeNoPrecompiles(addr, chainId);
    }

    function assumeNoPrecompiles(address addr, uint256 chainId) internal pure virtual {
        // Note: For some chains like Optimism these are technically predeploys (i.e. bytecode placed at a specific
        // address), but the same rationale for excluding them applies so we include those too.

        // These should be present on all EVM-compatible chains.
        vm.assume(addr < address(0x1) || addr > address(0x9));

        // forgefmt: disable-start
        if (chainId == 10 || chainId == 420) {
            // https://github.com/ethereum-optimism/optimism/blob/eaa371a0184b56b7ca6d9eb9cb0a2b78b2ccd864/op-bindings/predeploys/addresses.go#L6-L21
            vm.assume(addr < address(0x4200000000000000000000000000000000000000) || addr > address(0x4200000000000000000000000000000000000800));
        } else if (chainId == 42161 || chainId == 421613) {
            // https://developer.arbitrum.io/useful-addresses#arbitrum-precompiles-l2-same-on-all-arb-chains
            vm.assume(addr < address(0x0000000000000000000000000000000000000064) || addr > address(0x0000000000000000000000000000000000000068));
        } else if (chainId == 43114 || chainId == 43113) {
            // https://github.com/ava-labs/subnet-evm/blob/47c03fd007ecaa6de2c52ea081596e0a88401f58/precompile/params.go#L18-L59
            vm.assume(addr < address(0x0100000000000000000000000000000000000000) || addr > address(0x01000000000000000000000000000000000000ff));
            vm.assume(addr < address(0x0200000000000000000000000000000000000000) || addr > address(0x02000000000000000000000000000000000000FF));
            vm.assume(addr < address(0x0300000000000000000000000000000000000000) || addr > address(0x03000000000000000000000000000000000000Ff));
        }
        // forgefmt: disable-end
    }

    function readEIP1559ScriptArtifact(string memory path)
        internal
        view
        virtual
        returns (EIP1559ScriptArtifact memory)
    {
        string memory data = vm.readFile(path);
        bytes memory parsedData = vm.parseJson(data);
        RawEIP1559ScriptArtifact memory rawArtifact = abi.decode(parsedData, (RawEIP1559ScriptArtifact));
        EIP1559ScriptArtifact memory artifact;
        artifact.libraries = rawArtifact.libraries;
        artifact.path = rawArtifact.path;
        artifact.timestamp = rawArtifact.timestamp;
        artifact.pending = rawArtifact.pending;
        artifact.txReturns = rawArtifact.txReturns;
        artifact.receipts = rawToConvertedReceipts(rawArtifact.receipts);
        artifact.transactions = rawToConvertedEIPTx1559s(rawArtifact.transactions);
        return artifact;
    }

    function rawToConvertedEIPTx1559s(RawTx1559[] memory rawTxs) internal pure virtual returns (Tx1559[] memory) {
        Tx1559[] memory txs = new Tx1559[](rawTxs.length);
        for (uint256 i; i < rawTxs.length; i++) {
            txs[i] = rawToConvertedEIPTx1559(rawTxs[i]);
        }
        return txs;
    }

    function rawToConvertedEIPTx1559(RawTx1559 memory rawTx) internal pure virtual returns (Tx1559 memory) {
        Tx1559 memory transaction;
        transaction.arguments = rawTx.arguments;
        transaction.contractName = rawTx.contractName;
        transaction.functionSig = rawTx.functionSig;
        transaction.hash = rawTx.hash;
        transaction.txDetail = rawToConvertedEIP1559Detail(rawTx.txDetail);
        transaction.opcode = rawTx.opcode;
        return transaction;
    }

    function rawToConvertedEIP1559Detail(RawTx1559Detail memory rawDetail)
        internal
        pure
        virtual
        returns (Tx1559Detail memory)
    {
        Tx1559Detail memory txDetail;
        txDetail.data = rawDetail.data;
        txDetail.from = rawDetail.from;
        txDetail.to = rawDetail.to;
        txDetail.nonce = _bytesToUint(rawDetail.nonce);
        txDetail.txType = _bytesToUint(rawDetail.txType);
        txDetail.value = _bytesToUint(rawDetail.value);
        txDetail.gas = _bytesToUint(rawDetail.gas);
        txDetail.accessList = rawDetail.accessList;
        return txDetail;
    }

    function readTx1559s(string memory path) internal view virtual returns (Tx1559[] memory) {
        string memory deployData = vm.readFile(path);
        bytes memory parsedDeployData = vm.parseJson(deployData, ".transactions");
        RawTx1559[] memory rawTxs = abi.decode(parsedDeployData, (RawTx1559[]));
        return rawToConvertedEIPTx1559s(rawTxs);
    }

    function readTx1559(string memory path, uint256 index) internal view virtual returns (Tx1559 memory) {
        string memory deployData = vm.readFile(path);
        string memory key = string(abi.encodePacked(".transactions[", vm.toString(index), "]"));
        bytes memory parsedDeployData = vm.parseJson(deployData, key);
        RawTx1559 memory rawTx = abi.decode(parsedDeployData, (RawTx1559));
        return rawToConvertedEIPTx1559(rawTx);
    }

    // Analogous to readTransactions, but for receipts.
    function readReceipts(string memory path) internal view virtual returns (Receipt[] memory) {
        string memory deployData = vm.readFile(path);
        bytes memory parsedDeployData = vm.parseJson(deployData, ".receipts");
        RawReceipt[] memory rawReceipts = abi.decode(parsedDeployData, (RawReceipt[]));
        return rawToConvertedReceipts(rawReceipts);
    }

    function readReceipt(string memory path, uint256 index) internal view virtual returns (Receipt memory) {
        string memory deployData = vm.readFile(path);
        string memory key = string(abi.encodePacked(".receipts[", vm.toString(index), "]"));
        bytes memory parsedDeployData = vm.parseJson(deployData, key);
        RawReceipt memory rawReceipt = abi.decode(parsedDeployData, (RawReceipt));
        return rawToConvertedReceipt(rawReceipt);
    }

    function rawToConvertedReceipts(RawReceipt[] memory rawReceipts) internal pure virtual returns (Receipt[] memory) {
        Receipt[] memory receipts = new Receipt[](rawReceipts.length);
        for (uint256 i; i < rawReceipts.length; i++) {
            receipts[i] = rawToConvertedReceipt(rawReceipts[i]);
        }
        return receipts;
    }

    function rawToConvertedReceipt(RawReceipt memory rawReceipt) internal pure virtual returns (Receipt memory) {
        Receipt memory receipt;
        receipt.blockHash = rawReceipt.blockHash;
        receipt.to = rawReceipt.to;
        receipt.from = rawReceipt.from;
        receipt.contractAddress = rawReceipt.contractAddress;
        receipt.effectiveGasPrice = _bytesToUint(rawReceipt.effectiveGasPrice);
        receipt.cumulativeGasUsed = _bytesToUint(rawReceipt.cumulativeGasUsed);
        receipt.gasUsed = _bytesToUint(rawReceipt.gasUsed);
        receipt.status = _bytesToUint(rawReceipt.status);
        receipt.transactionIndex = _bytesToUint(rawReceipt.transactionIndex);
        receipt.blockNumber = _bytesToUint(rawReceipt.blockNumber);
        receipt.logs = rawToConvertedReceiptLogs(rawReceipt.logs);
        receipt.logsBloom = rawReceipt.logsBloom;
        receipt.transactionHash = rawReceipt.transactionHash;
        return receipt;
    }

    function rawToConvertedReceiptLogs(RawReceiptLog[] memory rawLogs)
        internal
        pure
        virtual
        returns (ReceiptLog[] memory)
    {
        ReceiptLog[] memory logs = new ReceiptLog[](rawLogs.length);
        for (uint256 i; i < rawLogs.length; i++) {
            logs[i].logAddress = rawLogs[i].logAddress;
            logs[i].blockHash = rawLogs[i].blockHash;
            logs[i].blockNumber = _bytesToUint(rawLogs[i].blockNumber);
            logs[i].data = rawLogs[i].data;
            logs[i].logIndex = _bytesToUint(rawLogs[i].logIndex);
            logs[i].topics = rawLogs[i].topics;
            logs[i].transactionIndex = _bytesToUint(rawLogs[i].transactionIndex);
            logs[i].transactionLogIndex = _bytesToUint(rawLogs[i].transactionLogIndex);
            logs[i].removed = rawLogs[i].removed;
        }
        return logs;
    }

    // Deploy a contract by fetching the contract bytecode from
    // the artifacts directory
    // e.g. `deployCode(code, abi.encode(arg1,arg2,arg3))`
    function deployCode(string memory what, bytes memory args) internal virtual returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,bytes): Deployment failed.");
    }

    function deployCode(string memory what) internal virtual returns (address addr) {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string): Deployment failed.");
    }

    /// @dev deploy contract with value on construction
    function deployCode(string memory what, bytes memory args, uint256 val) internal virtual returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,bytes,uint256): Deployment failed.");
    }

    function deployCode(string memory what, uint256 val) internal virtual returns (address addr) {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,uint256): Deployment failed.");
    }

    // creates a labeled address and the corresponding private key
    function makeAddrAndKey(string memory name) internal virtual returns (address addr, uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        addr = vm.addr(privateKey);
        vm.label(addr, name);
    }

    // creates a labeled address
    function makeAddr(string memory name) internal virtual returns (address addr) {
        (addr,) = makeAddrAndKey(name);
    }

    function deriveRememberKey(string memory mnemonic, uint32 index)
        internal
        virtual
        returns (address who, uint256 privateKey)
    {
        privateKey = vm.deriveKey(mnemonic, index);
        who = vm.rememberKey(privateKey);
    }

    function _bytesToUint(bytes memory b) private pure returns (uint256) {
        require(b.length <= 32, "StdCheats _bytesToUint(bytes): Bytes length exceeds 32.");
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }

    function isFork() internal view virtual returns (bool status) {
        try vm.activeFork() {
            status = true;
        } catch (bytes memory) {}
    }

    modifier skipWhenForking() {
        if (!isFork()) {
            _;
        }
    }

    modifier skipWhenNotForking() {
        if (isFork()) {
            _;
        }
    }

    modifier noGasMetering() {
        vm.pauseGasMetering();
        // To prevent turning gas monitoring back on with nested functions that use this modifier,
        // we check if gasMetering started in the off position. If it did, we don't want to turn
        // it back on until we exit the top level function that used the modifier
        //
        // i.e. funcA() noGasMetering { funcB() }, where funcB has noGasMetering as well.
        // funcA will have `gasStartedOff` as false, funcB will have it as true,
        // so we only turn metering back on at the end of the funcA
        bool gasStartedOff = gasMeteringOff;
        gasMeteringOff = true;

        _;

        // if gas metering was on when this modifier was called, turn it back on at the end
        if (!gasStartedOff) {
            gasMeteringOff = false;
            vm.resumeGasMetering();
        }
    }

    // a cheat for fuzzing addresses that are payable only
    // see https://github.com/foundry-rs/foundry/issues/3631
    function assumePayable(address addr) internal virtual {
        (bool success,) = payable(addr).call{value: 0}("");
        vm.assume(success);
    }
}

// Wrappers around cheatcodes to avoid footguns
abstract contract StdCheats is StdCheatsSafe {
    using stdStorage for StdStorage;

    StdStorage private stdstore;
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // Skip forward or rewind time by the specified number of seconds
    function skip(uint256 time) internal virtual {
        vm.warp(block.timestamp + time);
    }

    function rewind(uint256 time) internal virtual {
        vm.warp(block.timestamp - time);
    }

    // Setup a prank from an address that has some ether
    function hoax(address who) internal virtual {
        vm.deal(who, 1 << 128);
        vm.prank(who);
    }

    function hoax(address who, uint256 give) internal virtual {
        vm.deal(who, give);
        vm.prank(who);
    }

    function hoax(address who, address origin) internal virtual {
        vm.deal(who, 1 << 128);
        vm.prank(who, origin);
    }

    function hoax(address who, address origin, uint256 give) internal virtual {
        vm.deal(who, give);
        vm.prank(who, origin);
    }

    // Start perpetual prank from an address that has some ether
    function startHoax(address who) internal virtual {
        vm.deal(who, 1 << 128);
        vm.startPrank(who);
    }

    function startHoax(address who, uint256 give) internal virtual {
        vm.deal(who, give);
        vm.startPrank(who);
    }

    // Start perpetual prank from an address that has some ether
    // tx.origin is set to the origin parameter
    function startHoax(address who, address origin) internal virtual {
        vm.deal(who, 1 << 128);
        vm.startPrank(who, origin);
    }

    function startHoax(address who, address origin, uint256 give) internal virtual {
        vm.deal(who, give);
        vm.startPrank(who, origin);
    }

    function changePrank(address who) internal virtual {
        vm.stopPrank();
        vm.startPrank(who);
    }

    // The same as Vm's `deal`
    // Use the alternative signature for ERC20 tokens
    function deal(address to, uint256 give) internal virtual {
        vm.deal(to, give);
    }

    // Set the balance of an account for any ERC20 token
    // Use the alternative signature to update `totalSupply`
    function deal(address token, address to, uint256 give) internal virtual {
        deal(token, to, give, false);
    }

    function deal(address token, address to, uint256 give, bool adjust) internal virtual {
        // get current balance
        (, bytes memory balData) = token.call(abi.encodeWithSelector(0x70a08231, to));
        uint256 prevBal = abi.decode(balData, (uint256));

        // update balance
        stdstore.target(token).sig(0x70a08231).with_key(to).checked_write(give);

        // update total supply
        if (adjust) {
            (, bytes memory totSupData) = token.call(abi.encodeWithSelector(0x18160ddd));
            uint256 totSup = abi.decode(totSupData, (uint256));
            if (give < prevBal) {
                totSup -= (prevBal - give);
            } else {
                totSup += (give - prevBal);
            }
            stdstore.target(token).sig(0x18160ddd).checked_write(totSup);
        }
    }
}

// SPDX-License-Identifier: MIT
// Panics work for versions >=0.8.0, but we lowered the pragma to make this compatible with Test
pragma solidity >=0.6.2 <0.9.0;

library stdError {
    bytes public constant assertionError = abi.encodeWithSignature("Panic(uint256)", 0x01);
    bytes public constant arithmeticError = abi.encodeWithSignature("Panic(uint256)", 0x11);
    bytes public constant divisionError = abi.encodeWithSignature("Panic(uint256)", 0x12);
    bytes public constant enumConversionError = abi.encodeWithSignature("Panic(uint256)", 0x21);
    bytes public constant encodeStorageError = abi.encodeWithSignature("Panic(uint256)", 0x22);
    bytes public constant popError = abi.encodeWithSignature("Panic(uint256)", 0x31);
    bytes public constant indexOOBError = abi.encodeWithSignature("Panic(uint256)", 0x32);
    bytes public constant memOverflowError = abi.encodeWithSignature("Panic(uint256)", 0x41);
    bytes public constant zeroVarError = abi.encodeWithSignature("Panic(uint256)", 0x51);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

pragma experimental ABIEncoderV2;

import {VmSafe} from "./Vm.sol";

// Helpers for parsing and writing JSON files
// To parse:
// ```
// using stdJson for string;
// string memory json = vm.readFile("some_peth");
// json.parseUint("<json_path>");
// ```
// To write:
// ```
// using stdJson for string;
// string memory json = "deploymentArtifact";
// Contract contract = new Contract();
// json.serialize("contractAddress", address(contract));
// json = json.serialize("deploymentTimes", uint(1));
// // store the stringified JSON to the 'json' variable we have been using as a key
// // as we won't need it any longer
// string memory json2 = "finalArtifact";
// string memory final = json2.serialize("depArtifact", json);
// final.write("<some_path>");
// ```

library stdJson {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function parseRaw(string memory json, string memory key) internal pure returns (bytes memory) {
        return vm.parseJson(json, key);
    }

    function readUint(string memory json, string memory key) internal pure returns (uint256) {
        return abi.decode(vm.parseJson(json, key), (uint256));
    }

    function readUintArray(string memory json, string memory key) internal pure returns (uint256[] memory) {
        return abi.decode(vm.parseJson(json, key), (uint256[]));
    }

    function readInt(string memory json, string memory key) internal pure returns (int256) {
        return abi.decode(vm.parseJson(json, key), (int256));
    }

    function readIntArray(string memory json, string memory key) internal pure returns (int256[] memory) {
        return abi.decode(vm.parseJson(json, key), (int256[]));
    }

    function readBytes32(string memory json, string memory key) internal pure returns (bytes32) {
        return abi.decode(vm.parseJson(json, key), (bytes32));
    }

    function readBytes32Array(string memory json, string memory key) internal pure returns (bytes32[] memory) {
        return abi.decode(vm.parseJson(json, key), (bytes32[]));
    }

    function readString(string memory json, string memory key) internal pure returns (string memory) {
        return abi.decode(vm.parseJson(json, key), (string));
    }

    function readStringArray(string memory json, string memory key) internal pure returns (string[] memory) {
        return abi.decode(vm.parseJson(json, key), (string[]));
    }

    function readAddress(string memory json, string memory key) internal pure returns (address) {
        return abi.decode(vm.parseJson(json, key), (address));
    }

    function readAddressArray(string memory json, string memory key) internal pure returns (address[] memory) {
        return abi.decode(vm.parseJson(json, key), (address[]));
    }

    function readBool(string memory json, string memory key) internal pure returns (bool) {
        return abi.decode(vm.parseJson(json, key), (bool));
    }

    function readBoolArray(string memory json, string memory key) internal pure returns (bool[] memory) {
        return abi.decode(vm.parseJson(json, key), (bool[]));
    }

    function readBytes(string memory json, string memory key) internal pure returns (bytes memory) {
        return abi.decode(vm.parseJson(json, key), (bytes));
    }

    function readBytesArray(string memory json, string memory key) internal pure returns (bytes[] memory) {
        return abi.decode(vm.parseJson(json, key), (bytes[]));
    }

    function serialize(string memory jsonKey, string memory key, bool value) internal returns (string memory) {
        return vm.serializeBool(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bool[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBool(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, uint256 value) internal returns (string memory) {
        return vm.serializeUint(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, uint256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeUint(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, int256 value) internal returns (string memory) {
        return vm.serializeInt(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, int256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeInt(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, address value) internal returns (string memory) {
        return vm.serializeAddress(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, address[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeAddress(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes32 value) internal returns (string memory) {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes32[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes memory value) internal returns (string memory) {
        return vm.serializeBytes(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, string memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, string[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    function write(string memory jsonKey, string memory path) internal {
        vm.writeJson(jsonKey, path);
    }

    function write(string memory jsonKey, string memory path, string memory valueKey) internal {
        vm.writeJson(jsonKey, path, valueKey);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

library stdMath {
    int256 private constant INT256_MIN = -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function abs(int256 a) internal pure returns (uint256) {
        // Required or it will fail when `a = type(int256).min`
        if (a == INT256_MIN) {
            return 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        }

        return uint256(a > 0 ? a : -a);
    }

    function delta(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function delta(int256 a, int256 b) internal pure returns (uint256) {
        // a and b are of the same sign
        // this works thanks to two's complement, the left-most bit is the sign bit
        if ((a ^ b) > -1) {
            return delta(abs(a), abs(b));
        }

        // a and b are of opposite signs
        return abs(a) + abs(b);
    }

    function percentDelta(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);

        return absDelta * 1e18 / b;
    }

    function percentDelta(int256 a, int256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);
        uint256 absB = abs(b);

        return absDelta * 1e18 / absB;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {Vm} from "./Vm.sol";

struct StdStorage {
    mapping(address => mapping(bytes4 => mapping(bytes32 => uint256))) slots;
    mapping(address => mapping(bytes4 => mapping(bytes32 => bool))) finds;
    bytes32[] _keys;
    bytes4 _sig;
    uint256 _depth;
    address _target;
    bytes32 _set;
}

library stdStorageSafe {
    event SlotFound(address who, bytes4 fsig, bytes32 keysHash, uint256 slot);
    event WARNING_UninitedSlot(address who, uint256 slot);

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function sigs(string memory sigStr) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sigStr)));
    }

    /// @notice find an arbitrary storage slot given a function sig, input data, address of the contract and a value to check against
    // slot complexity:
    //  if flat, will be bytes32(uint256(uint));
    //  if map, will be keccak256(abi.encode(key, uint(slot)));
    //  if deep map, will be keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))));
    //  if map struct, will be bytes32(uint256(keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))))) + structFieldDepth);
    function find(StdStorage storage self) internal returns (uint256) {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        // calldata to test against
        if (self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
        }
        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        vm.record();
        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32 * field_depth);
        }

        (bytes32[] memory reads,) = vm.accesses(address(who));
        if (reads.length == 1) {
            bytes32 curr = vm.load(who, reads[0]);
            if (curr == bytes32(0)) {
                emit WARNING_UninitedSlot(who, uint256(reads[0]));
            }
            if (fdat != curr) {
                require(
                    false,
                    "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported."
                );
            }
            emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[0]));
            self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[0]);
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
        } else if (reads.length > 1) {
            for (uint256 i = 0; i < reads.length; i++) {
                bytes32 prev = vm.load(who, reads[i]);
                if (prev == bytes32(0)) {
                    emit WARNING_UninitedSlot(who, uint256(reads[i]));
                }
                // store
                vm.store(who, reads[i], bytes32(hex"1337"));
                bool success;
                bytes memory rdat;
                {
                    (success, rdat) = who.staticcall(cald);
                    fdat = bytesToBytes32(rdat, 32 * field_depth);
                }

                if (success && fdat == bytes32(hex"1337")) {
                    // we found which of the slots is the actual one
                    emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[i]));
                    self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[i]);
                    self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
                    vm.store(who, reads[i], prev);
                    break;
                }
                vm.store(who, reads[i], prev);
            }
        } else {
            revert("stdStorage find(StdStorage): No storage use detected for target.");
        }

        require(
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))],
            "stdStorage find(StdStorage): Slot(s) not found."
        );

        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;

        return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        self._target = _target;
        return self;
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        self._sig = _sig;
        return self;
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        self._sig = sigs(_sig);
        return self;
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        self._keys.push(bytes32(uint256(uint160(who))));
        return self;
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        self._keys.push(bytes32(amt));
        return self;
    }

    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        self._keys.push(key);
        return self;
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        self._depth = _depth;
        return self;
    }

    function read(StdStorage storage self) private returns (bytes memory) {
        address t = self._target;
        uint256 s = find(self);
        return abi.encode(vm.load(t, bytes32(s)));
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return abi.decode(read(self), (bytes32));
    }

    function read_bool(StdStorage storage self) internal returns (bool) {
        int256 v = read_int(self);
        if (v == 0) return false;
        if (v == 1) return true;
        revert("stdStorage read_bool(StdStorage): Cannot decode. Make sure you are reading a bool.");
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return abi.decode(read(self), (address));
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return abi.decode(read(self), (uint256));
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return abi.decode(read(self), (int256));
    }

    function bytesToBytes32(bytes memory b, uint256 offset) private pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint256 i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function flatten(bytes32[] memory b) private pure returns (bytes memory) {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

library stdStorage {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function sigs(string memory sigStr) internal pure returns (bytes4) {
        return stdStorageSafe.sigs(sigStr);
    }

    function find(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.find(self);
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        return stdStorageSafe.target(self, _target);
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        return stdStorageSafe.sig(self, _sig);
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        return stdStorageSafe.sig(self, _sig);
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, who);
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, amt);
    }

    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, key);
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        return stdStorageSafe.depth(self, _depth);
    }

    function checked_write(StdStorage storage self, address who) internal {
        checked_write(self, bytes32(uint256(uint160(who))));
    }

    function checked_write(StdStorage storage self, uint256 amt) internal {
        checked_write(self, bytes32(amt));
    }

    function checked_write(StdStorage storage self, bool write) internal {
        bytes32 t;
        /// @solidity memory-safe-assembly
        assembly {
            t := write
        }
        checked_write(self, t);
    }

    function checked_write(StdStorage storage self, bytes32 set) internal {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        if (!self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            find(self);
        }
        bytes32 slot = bytes32(self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]);

        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32 * field_depth);
        }
        bytes32 curr = vm.load(who, slot);

        if (fdat != curr) {
            require(
                false,
                "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported."
            );
        }
        vm.store(who, slot, set);
        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return stdStorageSafe.read_bytes32(self);
    }

    function read_bool(StdStorage storage self) internal returns (bool) {
        return stdStorageSafe.read_bool(self);
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return stdStorageSafe.read_address(self);
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.read_uint(self);
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return stdStorageSafe.read_int(self);
    }

    // Private function so needs to be copied over
    function bytesToBytes32(bytes memory b, uint256 offset) private pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint256 i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    // Private function so needs to be copied over
    function flatten(bytes32[] memory b) private pure returns (bytes memory) {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {IMulticall3} from "./interfaces/IMulticall3.sol";
// TODO Remove import.
import {VmSafe} from "./Vm.sol";

abstract contract StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IMulticall3 private constant multicall =
        IMulticall3(0xcA11bde05977b3631167028862bE2a173976CA11);
    VmSafe private constant vm =
        VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant CONSOLE2_ADDRESS =
        0x000000000000000000636F6e736F6c652e6c6f67;
    uint256 private constant INT256_MIN_ABS =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    uint256 private constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // Used by default when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    address private constant CREATE2_FACTORY =
        0x4e59b44847b379578588920cA78FbF26c0B4956C;

    /*//////////////////////////////////////////////////////////////////////////
                                 INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _bound(
        uint256 x,
        uint256 min,
        uint256 max
    ) internal pure virtual returns (uint256 result) {
        require(
            min <= max,
            "StdUtils bound(uint256,uint256,uint256): Max is less than min."
        );
        // If x is between min and max, return x directly. This is to ensure that dictionary values
        // do not get shifted if the min is nonzero. More info: https://github.com/foundry-rs/forge-std/issues/188
        if (x >= min && x <= max) return x;

        uint256 size = max - min + 1;

        // If the value is 0, 1, 2, 3, warp that to min, min+1, min+2, min+3. Similarly for the UINT256_MAX side.
        // This helps ensure coverage of the min/max values.
        if (x <= 3 && size > x) return min + x;
        if (x >= UINT256_MAX - 3 && size > UINT256_MAX - x)
            return max - (UINT256_MAX - x);

        // Otherwise, wrap x into the range [min, max], i.e. the range is inclusive.
        if (x > max) {
            uint256 diff = x - max;
            uint256 rem = diff % size;
            if (rem == 0) return max;
            result = min + rem - 1;
        } else if (x < min) {
            uint256 diff = min - x;
            uint256 rem = diff % size;
            if (rem == 0) return min;
            result = max - rem + 1;
        }
    }

    function bound(
        uint256 x,
        uint256 min,
        uint256 max
    ) internal view virtual returns (uint256 result) {
        result = _bound(x, min, max);
        console2_log("Bound Result", result);
    }

    function bound(
        int256 x,
        int256 min,
        int256 max
    ) internal view virtual returns (int256 result) {
        require(
            min <= max,
            "StdUtils bound(int256,int256,int256): Max is less than min."
        );

        // Shifting all int256 values to uint256 to use _bound function. The range of two types are:
        // int256 : -(2**255) ~ (2**255 - 1)
        // uint256:     0     ~ (2**256 - 1)
        // So, add 2**255, INT256_MIN_ABS to the integer values.
        //
        // If the given integer value is -2**255, we cannot use `-uint256(-x)` because of the overflow.
        // So, use `~uint256(x) + 1` instead.
        uint256 _x = x < 0
            ? (INT256_MIN_ABS - ~uint256(x) - 1)
            : (uint256(x) + INT256_MIN_ABS);
        uint256 _min = min < 0
            ? (INT256_MIN_ABS - ~uint256(min) - 1)
            : (uint256(min) + INT256_MIN_ABS);
        uint256 _max = max < 0
            ? (INT256_MIN_ABS - ~uint256(max) - 1)
            : (uint256(max) + INT256_MIN_ABS);

        uint256 y = _bound(_x, _min, _max);

        // To move it back to int256 value, subtract INT256_MIN_ABS at here.
        result = y < INT256_MIN_ABS
            ? int256(~(INT256_MIN_ABS - y) + 1)
            : int256(y - INT256_MIN_ABS);
        console2_log("Bound result", vm.toString(result));
    }

    function bytesToUint(bytes memory b)
        internal
        pure
        virtual
        returns (uint256)
    {
        require(
            b.length <= 32,
            "StdUtils bytesToUint(bytes): Bytes length exceeds 32."
        );
        return
            abi.decode(
                abi.encodePacked(new bytes(32 - b.length), b),
                (uint256)
            );
    }

    /// @dev Compute the address a contract will be deployed at for a given deployer address and nonce
    /// @notice adapted from Solmate implementation (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibRLP.sol)
    function computeCreateAddress(address deployer, uint256 nonce)
        internal
        pure
        virtual
        returns (address)
    {
        // forgefmt: disable-start
        // The integer zero is treated as an empty byte string, and as a result it only has a length prefix, 0x80, computed via 0x80 + 0.
        // A one byte integer uses its own value as its length prefix, there is no additional "0x80 + length" prefix that comes before it.
        if (nonce == 0x00)
            return
                addressFromLast20Bytes(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            deployer,
                            bytes1(0x80)
                        )
                    )
                );
        if (nonce <= 0x7f)
            return
                addressFromLast20Bytes(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            deployer,
                            uint8(nonce)
                        )
                    )
                );

        // Nonces greater than 1 byte all follow a consistent encoding scheme, where each value is preceded by a prefix of 0x80 + length.
        if (nonce <= 2**8 - 1)
            return
                addressFromLast20Bytes(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd7),
                            bytes1(0x94),
                            deployer,
                            bytes1(0x81),
                            uint8(nonce)
                        )
                    )
                );
        if (nonce <= 2**16 - 1)
            return
                addressFromLast20Bytes(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd8),
                            bytes1(0x94),
                            deployer,
                            bytes1(0x82),
                            uint16(nonce)
                        )
                    )
                );
        if (nonce <= 2**24 - 1)
            return
                addressFromLast20Bytes(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd9),
                            bytes1(0x94),
                            deployer,
                            bytes1(0x83),
                            uint24(nonce)
                        )
                    )
                );
        // forgefmt: disable-end

        // More details about RLP encoding can be found here: https://eth.wiki/fundamentals/rlp
        // 0xda = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x84 ++ nonce)
        // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
        // 0x84 = 0x80 + 0x04 (0x04 = the bytes length of the nonce, 4 bytes, in hex)
        // We assume nobody can have a nonce large enough to require more than 32 bytes.
        return
            addressFromLast20Bytes(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xda),
                        bytes1(0x94),
                        deployer,
                        bytes1(0x84),
                        uint32(nonce)
                    )
                )
            );
    }

    function computeCreate2Address(
        bytes32 salt,
        bytes32 initcodeHash,
        address deployer
    ) internal pure virtual returns (address) {
        return
            addressFromLast20Bytes(
                keccak256(
                    abi.encodePacked(bytes1(0xff), deployer, salt, initcodeHash)
                )
            );
    }

    /// @dev returns the address of a contract created with CREATE2 using the default CREATE2 deployer
    function computeCreate2Address(bytes32 salt, bytes32 initCodeHash)
        internal
        pure
        returns (address)
    {
        return computeCreate2Address(salt, initCodeHash, CREATE2_FACTORY);
    }

    /// @dev returns the hash of the init code (creation code + no args) used in CREATE2 with no constructor arguments
    /// @param creationCode the creation code of a contract C, as returned by type(C).creationCode
    function hashInitCode(bytes memory creationCode)
        internal
        pure
        returns (bytes32)
    {
        return hashInitCode(creationCode, "");
    }

    /// @dev returns the hash of the init code (creation code + ABI-encoded args) used in CREATE2
    /// @param creationCode the creation code of a contract C, as returned by type(C).creationCode
    /// @param args the ABI-encoded arguments to the constructor of C
    function hashInitCode(bytes memory creationCode, bytes memory args)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(creationCode, args));
    }

    // Performs a single call with Multicall3 to query the ERC-20 token balances of the given addresses.
    function getTokenBalances(address token, address[] memory addresses)
        internal
        virtual
        returns (uint256[] memory balances)
    {
        uint256 tokenCodeSize;
        assembly {
            tokenCodeSize := extcodesize(token)
        }
        require(
            tokenCodeSize > 0,
            "StdUtils getTokenBalances(address,address[]): Token address is not a contract."
        );

        // ABI encode the aggregate call to Multicall3.
        uint256 length = addresses.length;
        IMulticall3.Call[] memory calls = new IMulticall3.Call[](length);
        for (uint256 i = 0; i < length; ++i) {
            // 0x70a08231 = bytes4("balanceOf(address)"))
            calls[i] = IMulticall3.Call({
                target: token,
                callData: abi.encodeWithSelector(0x70a08231, (addresses[i]))
            });
        }

        // Make the aggregate call.
        (, bytes[] memory returnData) = multicall.aggregate(calls);

        // ABI decode the return data and return the balances.
        balances = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            balances[i] = abi.decode(returnData[i], (uint256));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function addressFromLast20Bytes(bytes32 bytesValue)
        private
        pure
        returns (address)
    {
        return address(uint160(uint256(bytesValue)));
    }

    // Used to prevent the compilation of console, which shortens the compilation time when console is not used elsewhere.

    function console2_log(string memory p0, uint256 p1) private view {
        (bool status, ) = address(CONSOLE2_ADDRESS).staticcall(
            abi.encodeWithSignature("log(string,uint256)", p0, p1)
        );
        status;
    }

    function console2_log(string memory p0, string memory p1) private view {
        (bool status, ) = address(CONSOLE2_ADDRESS).staticcall(
            abi.encodeWithSignature("log(string,string)", p0, p1)
        );
        status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

// 💬 ABOUT
// Standard Library's default Test

// 🧩 MODULES
import {console} from "./console.sol";
import {console2} from "./console2.sol";
import {StdAssertions} from "./StdAssertions.sol";
import {StdChains} from "./StdChains.sol";
import {StdCheats} from "./StdCheats.sol";
import {stdError} from "./StdError.sol";
import {stdJson} from "./StdJson.sol";
import {stdMath} from "./StdMath.sol";
import {StdStorage, stdStorage} from "./StdStorage.sol";
import {StdUtils} from "./StdUtils.sol";
import {Vm} from "./Vm.sol";

// 📦 BOILERPLATE
import {TestBase} from "./Base.sol";
import {DSTest} from "ds-test/test.sol";

// ⭐️ TEST
abstract contract Test is DSTest, StdAssertions, StdChains, StdCheats, StdUtils, TestBase {
// Note: IS_TEST() must return true.
// Note: Must have failure system, https://github.com/dapphub/ds-test/blob/cd98eff28324bfac652e63a239a60632a761790b/src/test.sol#L39-L76.
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

// Cheatcodes are marked as view/pure/none using the following rules:
// 0. A call's observable behaviour includes its return value, logs, reverts and state writes,
// 1. If you can influence a later call's observable behaviour, you're neither `view` nor `pure (you are modifying some state be it the EVM, interpreter, filesystem, etc),
// 2. Otherwise if you can be influenced by an earlier call, or if reading some state, you're `view`,
// 3. Otherwise you're `pure`.

interface VmSafe {
    struct Log {
        bytes32[] topics;
        bytes data;
        address emitter;
    }

    struct Rpc {
        string key;
        string url;
    }

    struct FsMetadata {
        bool isDir;
        bool isSymlink;
        uint256 length;
        bool readOnly;
        uint256 modified;
        uint256 accessed;
        uint256 created;
    }

    // Loads a storage slot from an address
    function load(address target, bytes32 slot) external view returns (bytes32 data);
    // Signs data
    function sign(uint256 privateKey, bytes32 digest) external pure returns (uint8 v, bytes32 r, bytes32 s);
    // Gets the address for a given private key
    function addr(uint256 privateKey) external pure returns (address keyAddr);
    // Gets the nonce of an account
    function getNonce(address account) external view returns (uint64 nonce);
    // Performs a foreign function call via the terminal
    function ffi(string[] calldata commandInput) external returns (bytes memory result);
    // Sets environment variables
    function setEnv(string calldata name, string calldata value) external;
    // Reads environment variables, (name) => (value)
    function envBool(string calldata name) external view returns (bool value);
    function envUint(string calldata name) external view returns (uint256 value);
    function envInt(string calldata name) external view returns (int256 value);
    function envAddress(string calldata name) external view returns (address value);
    function envBytes32(string calldata name) external view returns (bytes32 value);
    function envString(string calldata name) external view returns (string memory value);
    function envBytes(string calldata name) external view returns (bytes memory value);
    // Reads environment variables as arrays
    function envBool(string calldata name, string calldata delim) external view returns (bool[] memory value);
    function envUint(string calldata name, string calldata delim) external view returns (uint256[] memory value);
    function envInt(string calldata name, string calldata delim) external view returns (int256[] memory value);
    function envAddress(string calldata name, string calldata delim) external view returns (address[] memory value);
    function envBytes32(string calldata name, string calldata delim) external view returns (bytes32[] memory value);
    function envString(string calldata name, string calldata delim) external view returns (string[] memory value);
    function envBytes(string calldata name, string calldata delim) external view returns (bytes[] memory value);
    // Read environment variables with default value
    function envOr(string calldata name, bool defaultValue) external returns (bool value);
    function envOr(string calldata name, uint256 defaultValue) external returns (uint256 value);
    function envOr(string calldata name, int256 defaultValue) external returns (int256 value);
    function envOr(string calldata name, address defaultValue) external returns (address value);
    function envOr(string calldata name, bytes32 defaultValue) external returns (bytes32 value);
    function envOr(string calldata name, string calldata defaultValue) external returns (string memory value);
    function envOr(string calldata name, bytes calldata defaultValue) external returns (bytes memory value);
    // Read environment variables as arrays with default value
    function envOr(string calldata name, string calldata delim, bool[] calldata defaultValue)
        external
        returns (bool[] memory value);
    function envOr(string calldata name, string calldata delim, uint256[] calldata defaultValue)
        external
        returns (uint256[] memory value);
    function envOr(string calldata name, string calldata delim, int256[] calldata defaultValue)
        external
        returns (int256[] memory value);
    function envOr(string calldata name, string calldata delim, address[] calldata defaultValue)
        external
        returns (address[] memory value);
    function envOr(string calldata name, string calldata delim, bytes32[] calldata defaultValue)
        external
        returns (bytes32[] memory value);
    function envOr(string calldata name, string calldata delim, string[] calldata defaultValue)
        external
        returns (string[] memory value);
    function envOr(string calldata name, string calldata delim, bytes[] calldata defaultValue)
        external
        returns (bytes[] memory value);
    // Records all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address target) external returns (bytes32[] memory readSlots, bytes32[] memory writeSlots);
    // Gets the _creation_ bytecode from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata artifactPath) external view returns (bytes memory creationBytecode);
    // Gets the _deployed_ bytecode from an artifact file. Takes in the relative path to the json file
    function getDeployedCode(string calldata artifactPath) external view returns (bytes memory runtimeBytecode);
    // Labels an address in call traces
    function label(address account, string calldata newLabel) external;
    // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
    function broadcast() external;
    // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
    function broadcast(address signer) external;
    // Has the next call (at this call depth only) create a transaction with the private key provided as the sender that can later be signed and sent onchain
    function broadcast(uint256 privateKey) external;
    // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;
    // Has all subsequent calls (at this call depth only) create transactions with the address provided that can later be signed and sent onchain
    function startBroadcast(address signer) external;
    // Has all subsequent calls (at this call depth only) create transactions with the private key provided that can later be signed and sent onchain
    function startBroadcast(uint256 privateKey) external;
    // Stops collecting onchain transactions
    function stopBroadcast() external;
    // Reads the entire content of file to string
    function readFile(string calldata path) external view returns (string memory data);
    // Reads the entire content of file as binary. Path is relative to the project root.
    function readFileBinary(string calldata path) external view returns (bytes memory data);
    // Get the path of the current project root
    function projectRoot() external view returns (string memory path);
    // Get the metadata for a file/directory
    function fsMetadata(string calldata fileOrDir) external returns (FsMetadata memory metadata);
    // Reads next line of file to string
    function readLine(string calldata path) external view returns (string memory line);
    // Writes data to file, creating a file if it does not exist, and entirely replacing its contents if it does.
    function writeFile(string calldata path, string calldata data) external;
    // Writes binary data to a file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // Path is relative to the project root.
    function writeFileBinary(string calldata path, bytes calldata data) external;
    // Writes line to file, creating a file if it does not exist.
    function writeLine(string calldata path, string calldata data) external;
    // Closes file for reading, resetting the offset and allowing to read it from beginning with readLine.
    function closeFile(string calldata path) external;
    // Removes file. This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - Path points to a directory.
    // - The file doesn't exist.
    // - The user lacks permissions to remove the file.
    function removeFile(string calldata path) external;
    // Convert values to a string
    function toString(address value) external pure returns (string memory stringifiedValue);
    function toString(bytes calldata value) external pure returns (string memory stringifiedValue);
    function toString(bytes32 value) external pure returns (string memory stringifiedValue);
    function toString(bool value) external pure returns (string memory stringifiedValue);
    function toString(uint256 value) external pure returns (string memory stringifiedValue);
    function toString(int256 value) external pure returns (string memory stringifiedValue);
    // Convert values from a string
    function parseBytes(string calldata stringifiedValue) external pure returns (bytes memory parsedValue);
    function parseAddress(string calldata stringifiedValue) external pure returns (address parsedValue);
    function parseUint(string calldata stringifiedValue) external pure returns (uint256 parsedValue);
    function parseInt(string calldata stringifiedValue) external pure returns (int256 parsedValue);
    function parseBytes32(string calldata stringifiedValue) external pure returns (bytes32 parsedValue);
    function parseBool(string calldata stringifiedValue) external pure returns (bool parsedValue);
    // Record all the transaction logs
    function recordLogs() external;
    // Gets all the recorded logs
    function getRecordedLogs() external returns (Log[] memory logs);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path m/44'/60'/0'/0/{index}
    function deriveKey(string calldata mnemonic, uint32 index) external pure returns (uint256 privateKey);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at {derivationPath}{index}
    function deriveKey(string calldata mnemonic, string calldata derivationPath, uint32 index)
        external
        pure
        returns (uint256 privateKey);
    // Adds a private key to the local forge wallet and returns the address
    function rememberKey(uint256 privateKey) external returns (address keyAddr);
    //
    // parseJson
    //
    // ----
    // In case the returned value is a JSON object, it's encoded as a ABI-encoded tuple. As JSON objects
    // don't have the notion of ordered, but tuples do, they JSON object is encoded with it's fields ordered in
    // ALPHABETICAL order. That means that in order to successfully decode the tuple, we need to define a tuple that
    // encodes the fields in the same order, which is alphabetical. In the case of Solidity structs, they are encoded
    // as tuples, with the attributes in the order in which they are defined.
    // For example: json = { 'a': 1, 'b': 0xa4tb......3xs}
    // a: uint256
    // b: address
    // To decode that json, we need to define a struct or a tuple as follows:
    // struct json = { uint256 a; address b; }
    // If we defined a json struct with the opposite order, meaning placing the address b first, it would try to
    // decode the tuple in that order, and thus fail.
    // ----
    // Given a string of JSON, return it as ABI-encoded
    function parseJson(string calldata json, string calldata key) external pure returns (bytes memory abiEncodedData);
    function parseJson(string calldata json) external pure returns (bytes memory abiEncodedData);

    // The following parseJson cheatcodes will do type coercion, for the type that they indicate.
    // For example, parseJsonUint will coerce all values to a uint256. That includes stringified numbers '12'
    // and hex numbers '0xEF'.
    // Type coercion works ONLY for discrete values or arrays. That means that the key must return a value or array, not
    // a JSON object.
    function parseJsonUint(string calldata, string calldata) external returns (uint256);
    function parseJsonUintArray(string calldata, string calldata) external returns (uint256[] memory);
    function parseJsonInt(string calldata, string calldata) external returns (int256);
    function parseJsonIntArray(string calldata, string calldata) external returns (int256[] memory);
    function parseJsonBool(string calldata, string calldata) external returns (bool);
    function parseJsonBoolArray(string calldata, string calldata) external returns (bool[] memory);
    function parseJsonAddress(string calldata, string calldata) external returns (address);
    function parseJsonAddressArray(string calldata, string calldata) external returns (address[] memory);
    function parseJsonString(string calldata, string calldata) external returns (string memory);
    function parseJsonStringArray(string calldata, string calldata) external returns (string[] memory);
    function parseJsonBytes(string calldata, string calldata) external returns (bytes memory);
    function parseJsonBytesArray(string calldata, string calldata) external returns (bytes[] memory);
    function parseJsonBytes32(string calldata, string calldata) external returns (bytes32);
    function parseJsonBytes32Array(string calldata, string calldata) external returns (bytes32[] memory);

    // Serialize a key and value to a JSON object stored in-memory that can be later written to a file
    // It returns the stringified version of the specific JSON file up to that moment.
    function serializeBool(string calldata objectKey, string calldata valueKey, bool value)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256 value)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256 value)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address value)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32 value)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string calldata value)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes calldata value)
        external
        returns (string memory json);

    function serializeBool(string calldata objectKey, string calldata valueKey, bool[] calldata values)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256[] calldata values)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256[] calldata values)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address[] calldata values)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32[] calldata values)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string[] calldata values)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes[] calldata values)
        external
        returns (string memory json);

    //
    // writeJson
    //
    // ----
    // Write a serialized JSON object to a file. If the file exists, it will be overwritten.
    // Let's assume we want to write the following JSON to a file:
    //
    // { "boolean": true, "number": 342, "object": { "title": "finally json serialization" } }
    //
    // ```
    //  string memory json1 = "some key";
    //  vm.serializeBool(json1, "boolean", true);
    //  vm.serializeBool(json1, "number", uint256(342));
    //  json2 = "some other key";
    //  string memory output = vm.serializeString(json2, "title", "finally json serialization");
    //  string memory finalJson = vm.serialize(json1, "object", output);
    //  vm.writeJson(finalJson, "./output/example.json");
    // ```
    // The critical insight is that every invocation of serialization will return the stringified version of the JSON
    // up to that point. That means we can construct arbitrary JSON objects and then use the return stringified version
    // to serialize them as values to another JSON object.
    //
    // json1 and json2 are simply keys used by the backend to keep track of the objects. So vm.serializeJson(json1,..)
    // will find the object in-memory that is keyed by "some key".
    function writeJson(string calldata json, string calldata path) external;
    // Write a serialized JSON object to an **existing** JSON file, replacing a value with key = <value_key>
    // This is useful to replace a specific value of a JSON file, without having to parse the entire thing
    function writeJson(string calldata json, string calldata path, string calldata valueKey) external;
    // Returns the RPC url for the given alias
    function rpcUrl(string calldata rpcAlias) external view returns (string memory json);
    // Returns all rpc urls and their aliases `[alias, url][]`
    function rpcUrls() external view returns (string[2][] memory urls);
    // Returns all rpc urls and their aliases as structs.
    function rpcUrlStructs() external view returns (Rpc[] memory urls);
    // If the condition is false, discard this run's fuzz inputs and generate new ones.
    function assume(bool condition) external pure;
    // Pauses gas metering (i.e. gas usage is not counted). Noop if already paused.
    function pauseGasMetering() external;
    // Resumes gas metering (i.e. gas usage is counted again). Noop if already on.
    function resumeGasMetering() external;
}

interface Vm is VmSafe {
    // Sets block.timestamp
    function warp(uint256 newTimestamp) external;
    // Sets block.height
    function roll(uint256 newHeight) external;
    // Sets block.basefee
    function fee(uint256 newBasefee) external;
    // Sets block.difficulty
    function difficulty(uint256 newDifficulty) external;
    // Sets block.chainid
    function chainId(uint256 newChainId) external;
    // Stores a value to an address' storage slot.
    function store(address target, bytes32 slot, bytes32 value) external;
    // Sets the nonce of an account; must be higher than the current nonce of the account
    function setNonce(address account, uint64 newNonce) external;
    // Sets the *next* call's msg.sender to be the input address
    function prank(address msgSender) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address msgSender) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address msgSender, address txOrigin) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address msgSender, address txOrigin) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Sets an address' balance
    function deal(address account, uint256 newBalance) external;
    // Sets an address' code
    function etch(address target, bytes calldata newRuntimeBytecode) external;
    // Expects an error on next call
    function expectRevert(bytes calldata revertData) external;
    function expectRevert(bytes4 revertData) external;
    function expectRevert() external;
    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter)
        external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address callee, bytes calldata data, bytes calldata returnData) external;
    // Mocks a call to an address with a specific msg.value, returning specified data.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address callee, uint256 msgValue, bytes calldata data, bytes calldata returnData) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expects a call to an address with the specified calldata.
    // Calldata can either be a strict or a partial match
    function expectCall(address callee, bytes calldata data) external;
    // Expects a call to an address with the specified msg.value and calldata
    function expectCall(address callee, uint256 msgValue, bytes calldata data) external;
    // Sets block.coinbase
    function coinbase(address newCoinbase) external;
    // Snapshot the current state of the evm.
    // Returns the id of the snapshot that was created.
    // To revert a snapshot use `revertTo`
    function snapshot() external returns (uint256 snapshotId);
    // Revert the state of the EVM to a previous snapshot
    // Takes the snapshot id to revert to.
    // This deletes the snapshot and all snapshots taken after the given snapshot id.
    function revertTo(uint256 snapshotId) external returns (bool success);
    // Creates a new fork with the given endpoint and block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);
    // Creates a new fork with the given endpoint and the _latest_ block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias) external returns (uint256 forkId);
    // Creates a new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before the transaction,
    // and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);
    // Creates _and_ also selects a new fork with the given endpoint and block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);
    // Creates _and_ also selects new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before
    // the transaction, returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);
    // Creates _and_ also selects a new fork with the given endpoint and the latest block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias) external returns (uint256 forkId);
    // Takes a fork identifier created by `createFork` and sets the corresponding forked state as active.
    function selectFork(uint256 forkId) external;
    /// Returns the identifier of the currently active fork. Reverts if no fork is currently active.
    function activeFork() external view returns (uint256 forkId);
    // Updates the currently active fork to given block number
    // This is similar to `roll` but for the currently active fork
    function rollFork(uint256 blockNumber) external;
    // Updates the currently active fork to given transaction
    // this will `rollFork` with the number of the block the transaction was mined in and replays all transaction mined before it in the block
    function rollFork(bytes32 txHash) external;
    // Updates the given fork to given block number
    function rollFork(uint256 forkId, uint256 blockNumber) external;
    // Updates the given fork to block number of the given transaction and replays all transaction mined before it in the block
    function rollFork(uint256 forkId, bytes32 txHash) external;
    // Marks that the account(s) should use persistent storage across fork swaps in a multifork setup
    // Meaning, changes made to the state of this account will be kept when switching forks
    function makePersistent(address account) external;
    function makePersistent(address account0, address account1) external;
    function makePersistent(address account0, address account1, address account2) external;
    function makePersistent(address[] calldata accounts) external;
    // Revokes persistent status from the address, previously added via `makePersistent`
    function revokePersistent(address account) external;
    function revokePersistent(address[] calldata accounts) external;
    // Returns true if the account is marked as persistent
    function isPersistent(address account) external view returns (bool persistent);
    // In forking mode, explicitly grant the given address cheatcode access
    function allowCheatcodes(address account) external;
    // Fetches the given transaction from the active fork and executes it on the current state
    function transact(bytes32 txHash) external;
    // Fetches the given transaction from the given fork and executes it on the current state
    function transact(uint256 forkId, bytes32 txHash) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @dev The original console.sol uses `int` and `uint` for computing function selectors, but it should
/// use `int256` and `uint256`. This modified version fixes that. This version is recommended
/// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
/// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
/// Reference: https://github.com/NomicFoundation/hardhat/issues/2178
library console2 {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
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

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, int256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,int256)", p0, p1));
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

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
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

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
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

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
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

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
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

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
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

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
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

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
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

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
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

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
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

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
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

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
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

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
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

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
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

    function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
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

    function log(address p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
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

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
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

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
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

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

interface IMulticall3 {
    struct Call {
        address target;
        bytes callData;
    }

    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes[] memory returnData);

    function aggregate3(Call3[] calldata calls) external payable returns (Result[] memory returnData);

    function aggregate3Value(Call3Value[] calldata calls) external payable returns (Result[] memory returnData);

    function blockAndAggregate(Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);

    function getBasefee() external view returns (uint256 basefee);

    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);

    function getBlockNumber() external view returns (uint256 blockNumber);

    function getChainId() external view returns (uint256 chainid);

    function getCurrentBlockCoinbase() external view returns (address coinbase);

    function getCurrentBlockDifficulty() external view returns (uint256 difficulty);

    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);

    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

    function getEthBalance(address addr) external view returns (uint256 balance);

    function getLastBlockHash() external view returns (bytes32 blockHash);

    function tryAggregate(bool requireSuccess, Call[] calldata calls)
        external
        payable
        returns (Result[] memory returnData);

    function tryBlockAndAggregate(bool requireSuccess, Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {OperatorFilterRegistryErrorsAndEvents} from "./OperatorFilterRegistryErrorsAndEvents.sol";

/**
 * @title  OperatorFilterRegistry
 * @notice Borrows heavily from the QQL BlacklistOperatorFilter contract:
 *         https://github.com/qql-art/contracts/blob/main/contracts/BlacklistOperatorFilter.sol
 * @notice This contracts allows tokens or token owners to register specific addresses or codeHashes that may be
 * *       restricted according to the isOperatorAllowed function.
 */
contract OperatorFilterRegistry is IOperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @dev initialized accounts have a nonzero codehash (see https://eips.ethereum.org/EIPS/eip-1052)
    /// Note that this will also be a smart contract's codehash when making calls from its constructor.
    bytes32 constant EOA_CODEHASH = keccak256("");

    mapping(address => EnumerableSet.AddressSet) private _filteredOperators;
    mapping(address => EnumerableSet.Bytes32Set) private _filteredCodeHashes;
    mapping(address => address) private _registrations;
    mapping(address => EnumerableSet.AddressSet) private _subscribers;

    /**
     * @notice Restricts method caller to the address or EIP-173 "owner()"
     */
    modifier onlyAddressOrOwner(address addr) {
        if (msg.sender != addr) {
            try Ownable(addr).owner() returns (address owner) {
                if (msg.sender != owner) {
                    revert OnlyAddressOrOwner();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NotOwnable();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        _;
    }

    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     *         Note that this method will *revert* if an operator or its codehash is filtered with an error that is
     *         more informational than a false boolean, so smart contracts that query this method for informational
     *         purposes will need to wrap in a try/catch or perform a low-level staticcall in order to handle the case
     *         that an operator is filtered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            EnumerableSet.AddressSet storage filteredOperatorsRef;
            EnumerableSet.Bytes32Set storage filteredCodeHashesRef;

            filteredOperatorsRef = _filteredOperators[registration];
            filteredCodeHashesRef = _filteredCodeHashes[registration];

            if (filteredOperatorsRef.contains(operator)) {
                revert AddressFiltered(operator);
            }
            if (operator.code.length > 0) {
                bytes32 codeHash = operator.codehash;
                if (filteredCodeHashesRef.contains(codeHash)) {
                    revert CodeHashFiltered(operator, codeHash);
                }
            }
        }
        return true;
    }

    //////////////////
    // AUTH METHODS //
    //////////////////

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external onlyAddressOrOwner(registrant) {
        if (_registrations[registrant] != address(0)) {
            revert AlreadyRegistered();
        }
        _registrations[registrant] = registrant;
        emit RegistrationUpdated(registrant, true);
    }

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address registrant) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            _subscribers[registration].remove(registrant);
            emit SubscriptionUpdated(registrant, registration, false);
        }
        _registrations[registrant] = address(0);
        emit RegistrationUpdated(registrant, false);
    }

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            revert AlreadyRegistered();
        }
        if (registrant == subscription) {
            revert CannotSubscribeToSelf();
        }
        address subscriptionRegistration = _registrations[subscription];
        if (subscriptionRegistration == address(0)) {
            revert NotRegistered(subscription);
        }
        if (subscriptionRegistration != subscription) {
            revert CannotSubscribeToRegistrantWithSubscription(subscription);
        }

        _registrations[registrant] = subscription;
        _subscribers[subscription].add(registrant);
        emit RegistrationUpdated(registrant, true);
        emit SubscriptionUpdated(registrant, subscription, true);
    }

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy)
        external
        onlyAddressOrOwner(registrant)
    {
        if (registrantToCopy == registrant) {
            revert CannotCopyFromSelf();
        }
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            revert AlreadyRegistered();
        }
        address registrantRegistration = _registrations[registrantToCopy];
        if (registrantRegistration == address(0)) {
            revert NotRegistered(registrantToCopy);
        }
        _registrations[registrant] = registrant;
        emit RegistrationUpdated(registrant, true);
        _copyEntries(registrant, registrantToCopy);
    }

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered)
        external
        onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrant];

        if (!filtered) {
            bool removed = filteredOperatorsRef.remove(operator);
            if (!removed) {
                revert AddressNotFiltered(operator);
            }
        } else {
            bool added = filteredOperatorsRef.add(operator);
            if (!added) {
                revert AddressAlreadyFiltered(operator);
            }
        }
        emit OperatorUpdated(registrant, operator, filtered);
    }

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     *         Note that this will allow adding the bytes32(0) codehash, which could result in unexpected behavior,
     *         since calling `isCodeHashFiltered` will return true for bytes32(0), which is the codeHash of any
     *         un-initialized account. Since un-initialized accounts have no code, the registry will not validate
     *         that an un-initalized account's codeHash is not filtered. By the time an account is able to
     *         act as an operator (an account is initialized or a smart contract exclusively in the context of its
     *         constructor),  it will have a codeHash of EOA_CODEHASH, which cannot be filtered.
     */
    function updateCodeHash(address registrant, bytes32 codeHash, bool filtered)
        external
        onlyAddressOrOwner(registrant)
    {
        if (codeHash == EOA_CODEHASH) {
            revert CannotFilterEOAs();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrant];

        if (!filtered) {
            bool removed = filteredCodeHashesRef.remove(codeHash);
            if (!removed) {
                revert CodeHashNotFiltered(codeHash);
            }
        } else {
            bool added = filteredCodeHashesRef.add(codeHash);
            if (!added) {
                revert CodeHashAlreadyFiltered(codeHash);
            }
        }
        emit CodeHashUpdated(registrant, codeHash, filtered);
    }

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered)
        external
        onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrant];
        uint256 operatorsLength = operators.length;
        if (!filtered) {
            for (uint256 i = 0; i < operatorsLength;) {
                address operator = operators[i];
                bool removed = filteredOperatorsRef.remove(operator);
                if (!removed) {
                    revert AddressNotFiltered(operator);
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < operatorsLength;) {
                address operator = operators[i];
                bool added = filteredOperatorsRef.add(operator);
                if (!added) {
                    revert AddressAlreadyFiltered(operator);
                }
                unchecked {
                    ++i;
                }
            }
        }
        emit OperatorsUpdated(registrant, operators, filtered);
    }

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     *         Note that this will allow adding the bytes32(0) codehash, which could result in unexpected behavior,
     *         since calling `isCodeHashFiltered` will return true for bytes32(0), which is the codeHash of any
     *         un-initialized account. Since un-initialized accounts have no code, the registry will not validate
     *         that an un-initalized account's codeHash is not filtered. By the time an account is able to
     *         act as an operator (an account is initialized or a smart contract exclusively in the context of its
     *         constructor),  it will have a codeHash of EOA_CODEHASH, which cannot be filtered.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered)
        external
        onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrant];
        uint256 codeHashesLength = codeHashes.length;
        if (!filtered) {
            for (uint256 i = 0; i < codeHashesLength;) {
                bytes32 codeHash = codeHashes[i];
                bool removed = filteredCodeHashesRef.remove(codeHash);
                if (!removed) {
                    revert CodeHashNotFiltered(codeHash);
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < codeHashesLength;) {
                bytes32 codeHash = codeHashes[i];
                if (codeHash == EOA_CODEHASH) {
                    revert CannotFilterEOAs();
                }
                bool added = filteredCodeHashesRef.add(codeHash);
                if (!added) {
                    revert CodeHashAlreadyFiltered(codeHash);
                }
                unchecked {
                    ++i;
                }
            }
        }
        emit CodeHashesUpdated(registrant, codeHashes, filtered);
    }

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address newSubscription) external onlyAddressOrOwner(registrant) {
        if (registrant == newSubscription) {
            revert CannotSubscribeToSelf();
        }
        if (newSubscription == address(0)) {
            revert CannotSubscribeToZeroAddress();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration == newSubscription) {
            revert AlreadySubscribed(newSubscription);
        }
        address newSubscriptionRegistration = _registrations[newSubscription];
        if (newSubscriptionRegistration == address(0)) {
            revert NotRegistered(newSubscription);
        }
        if (newSubscriptionRegistration != newSubscription) {
            revert CannotSubscribeToRegistrantWithSubscription(newSubscription);
        }

        if (registration != registrant) {
            _subscribers[registration].remove(registrant);
            emit SubscriptionUpdated(registrant, registration, false);
        }
        _registrations[registrant] = newSubscription;
        _subscribers[newSubscription].add(registrant);
        emit SubscriptionUpdated(registrant, newSubscription, true);
    }

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration == registrant) {
            revert NotSubscribed();
        }
        _subscribers[registration].remove(registrant);
        _registrations[registrant] = registrant;
        emit SubscriptionUpdated(registrant, registration, false);
        if (copyExistingEntries) {
            _copyEntries(registrant, registration);
        }
    }

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external onlyAddressOrOwner(registrant) {
        if (registrant == registrantToCopy) {
            revert CannotCopyFromSelf();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        address registrantRegistration = _registrations[registrantToCopy];
        if (registrantRegistration == address(0)) {
            revert NotRegistered(registrantToCopy);
        }
        _copyEntries(registrant, registrantToCopy);
    }

    /// @dev helper to copy entries from registrantToCopy to registrant and emit events
    function _copyEntries(address registrant, address registrantToCopy) private {
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrantToCopy];
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrantToCopy];
        uint256 filteredOperatorsLength = filteredOperatorsRef.length();
        uint256 filteredCodeHashesLength = filteredCodeHashesRef.length();
        for (uint256 i = 0; i < filteredOperatorsLength;) {
            address operator = filteredOperatorsRef.at(i);
            bool added = _filteredOperators[registrant].add(operator);
            if (added) {
                emit OperatorUpdated(registrant, operator, true);
            }
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < filteredCodeHashesLength;) {
            bytes32 codehash = filteredCodeHashesRef.at(i);
            bool added = _filteredCodeHashes[registrant].add(codehash);
            if (added) {
                emit CodeHashUpdated(registrant, codehash, true);
            }
            unchecked {
                ++i;
            }
        }
    }

    //////////////////
    // VIEW METHODS //
    //////////////////

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address registrant) external view returns (address subscription) {
        subscription = _registrations[registrant];
        if (subscription == address(0)) {
            revert NotRegistered(registrant);
        } else if (subscription == registrant) {
            subscription = address(0);
        }
    }

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external view returns (address[] memory) {
        return _subscribers[registrant].values();
    }

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external view returns (address) {
        return _subscribers[registrant].at(index);
    }

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].contains(operator);
        }
        return _filteredOperators[registrant].contains(operator);
    }

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].contains(codeHash);
        }
        return _filteredCodeHashes[registrant].contains(codeHash);
    }

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external view returns (bool) {
        bytes32 codeHash = operatorWithCode.codehash;
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].contains(codeHash);
        }
        return _filteredCodeHashes[registrant].contains(codeHash);
    }

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address registrant) external view returns (bool) {
        return _registrations[registrant] != address(0);
    }

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address registrant) external view returns (address[] memory) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].values();
        }
        return _filteredOperators[registrant].values();
    }

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address registrant) external view returns (bytes32[] memory) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].values();
        }
        return _filteredCodeHashes[registrant].values();
    }

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external view returns (address) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].at(index);
        }
        return _filteredOperators[registrant].at(index);
    }

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external view returns (bytes32) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].at(index);
        }
        return _filteredCodeHashes[registrant].at(index);
    }

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address a) external view returns (bytes32) {
        return a.codehash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract OperatorFilterRegistryErrorsAndEvents {
    /// @notice Emitted when trying to register an address that has no code.
    error CannotFilterEOAs();

    /// @notice Emitted when trying to add an address that is already filtered.
    error AddressAlreadyFiltered(address operator);

    /// @notice Emitted when trying to remove an address that is not filtered.
    error AddressNotFiltered(address operator);

    /// @notice Emitted when trying to add a codehash that is already filtered.
    error CodeHashAlreadyFiltered(bytes32 codeHash);

    /// @notice Emitted when trying to remove a codehash that is not filtered.
    error CodeHashNotFiltered(bytes32 codeHash);

    /// @notice Emitted when the caller is not the address or EIP-173 "owner()"
    error OnlyAddressOrOwner();

    /// @notice Emitted when the registrant is not registered.
    error NotRegistered(address registrant);

    /// @notice Emitted when the registrant is already registered.
    error AlreadyRegistered();

    /// @notice Emitted when the registrant is already subscribed.
    error AlreadySubscribed(address subscription);

    /// @notice Emitted when the registrant is not subscribed.
    error NotSubscribed();

    /// @notice Emitted when trying to update a registration where the registrant is already subscribed.
    error CannotUpdateWhileSubscribed(address subscription);

    /// @notice Emitted when trying to subscribe to itself.
    error CannotSubscribeToSelf();

    /// @notice Emitted when trying to subscribe to the zero address.
    error CannotSubscribeToZeroAddress();

    /// @notice Emitted when trying to register and the contract is not ownable (EIP-173 "owner()")
    error NotOwnable();

    /// @notice Emitted when an address is filtered.
    error AddressFiltered(address filtered);

    /// @notice Emitted when a codeHash is filtered.
    error CodeHashFiltered(address account, bytes32 codeHash);

    /// @notice Emited when trying to register to a registrant with a subscription.
    error CannotSubscribeToRegistrantWithSubscription(address registrant);

    /// @notice Emitted when trying to copy a registration from itself.
    error CannotCopyFromSelf();

    /// @notice Emitted when a registration is updated.
    event RegistrationUpdated(address indexed registrant, bool indexed registered);

    /// @notice Emitted when an operator is updated.
    event OperatorUpdated(address indexed registrant, address indexed operator, bool indexed filtered);

    /// @notice Emitted when multiple operators are updated.
    event OperatorsUpdated(address indexed registrant, address[] operators, bool indexed filtered);

    /// @notice Emitted when a codeHash is updated.
    event CodeHashUpdated(address indexed registrant, bytes32 indexed codeHash, bool indexed filtered);

    /// @notice Emitted when multiple codeHashes are updated.
    event CodeHashesUpdated(address indexed registrant, bytes32[] codeHashes, bool indexed filtered);

    /// @notice Emitted when a subscription is updated.
    event SubscriptionUpdated(address indexed registrant, address indexed subscription, bool indexed subscribed);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ILayerZeroUserApplicationConfigUpgradeable.sol";

interface ILayerZeroEndpointUpgradeable is ILayerZeroUserApplicationConfigUpgradeable {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ILayerZeroReceiverUpgradeable {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ILayerZeroUserApplicationConfigUpgradeable {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/ILayerZeroReceiverUpgradeable.sol";
import "../interfaces/ILayerZeroUserApplicationConfigUpgradeable.sol";
import "../interfaces/ILayerZeroEndpointUpgradeable.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzAppUpgradeable is Initializable, OwnableUpgradeable, ILayerZeroReceiverUpgradeable, ILayerZeroUserApplicationConfigUpgradeable {
    ILayerZeroEndpointUpgradeable public lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint => uint)) public minDstGasLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);
    event SetMinDstGasLookup(uint16 _dstChainId, uint _type, uint _dstGasAmount);

    function __LzAppUpgradeable_init(address _endpoint) internal onlyInitializing {
        __LzAppUpgradeable_init_unchained(_endpoint);
    }

    function __LzAppUpgradeable_init_unchained(address _endpoint) internal onlyInitializing {
        lzEndpoint = ILayerZeroEndpointUpgradeable(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        lzEndpoint.send{value: msg.value}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(uint16 _dstChainId, uint _type, bytes memory _adapterParams, uint _extraGas) internal view {
        uint providedGasLimit = getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function getGasLimit(bytes memory _adapterParams) public pure returns (uint gasLimit) {
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function setMinDstGasLookup(uint16 _dstChainId, uint _type, uint _dstGasAmount) external onlyOwner {
        require(_dstGasAmount > 0, "LzApp: invalid _dstGasAmount");
        minDstGasLookup[_dstChainId][_type] = _dstGasAmount;
        emit SetMinDstGasLookup(_dstChainId, _type, _dstGasAmount);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./LzAppUpgradeable.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzAppUpgradeable is Initializable, LzAppUpgradeable {
    function __NonblockingLzAppUpgradeable_init(address _endpoint) internal onlyInitializing {
        __NonblockingLzAppUpgradeable_init_unchained(_endpoint);
    }

    function __NonblockingLzAppUpgradeable_init_unchained(address _endpoint) internal onlyInitializing {
        __LzAppUpgradeable_init_unchained(_endpoint);
    }

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        // try-catch all errors/exceptions
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/**
 * @dev Interface of the ONFT Core standard
 */
interface IONFT721CoreUpgradeable is IERC165Upgradeable {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _tokenId - token Id to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParams - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes calldata _toAddress, uint _tokenId, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    /**
     * @dev Emitted when `_tokenId` are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce from
     */
    event SendToChain(address indexed _sender, uint16 indexed _dstChainId, bytes indexed _toAddress, uint _tokenId, uint64 _nonce);

    /**
     * @dev Emitted when `_tokenId` are sent from `_srcChainId` to the `_toAddress` at this chain. `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, bytes indexed _srcAddress, address indexed _toAddress, uint _tokenId, uint64 _nonce);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IONFT721CoreUpgradeable.sol";

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT721Upgradeable is IONFT721CoreUpgradeable, IERC721Upgradeable {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "../../lzApp/NonblockingLzAppUpgradeable.sol";
import "./IONFT721CoreUpgradeable.sol";

abstract contract ONFT721CoreUpgradeable is Initializable, NonblockingLzAppUpgradeable, ERC165Upgradeable, IONFT721CoreUpgradeable {
    uint public constant NO_EXTRA_GAS = 0;
    uint public constant FUNCTION_TYPE_SEND = 1;
    bool public useCustomAdapterParams;

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

    function __ONFT721CoreUpgradeable_init(address _lzEndpoint) internal onlyInitializing {
        __ONFT721CoreUpgradeable_init_unchained(_lzEndpoint);
    }

    function __ONFT721CoreUpgradeable_init_unchained(address _lzEndpoint) internal onlyInitializing {
        __NonblockingLzAppUpgradeable_init_unchained(_lzEndpoint);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IONFT721CoreUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, bool _useZro, bytes memory _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(_toAddress, _tokenId);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function sendFrom(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _tokenId, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _send(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual {
        _debitFrom(_from, _dstChainId, _toAddress, _tokenId);

        bytes memory payload = abi.encode(_toAddress, _tokenId);
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, FUNCTION_TYPE_SEND, _adapterParams, NO_EXTRA_GAS);
        } else {
            require(_adapterParams.length == 0, "LzApp: _adapterParams must be empty.");
        }
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams);

        uint64 nonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendToChain(_from, _dstChainId, _toAddress, _tokenId, nonce);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint tokenId) = abi.decode(_payload, (bytes, uint));
        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        _creditTo(_srcChainId, toAddress, tokenId);

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenId, _nonce);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId) internal virtual;

    function _creditTo(uint16 _srcChainId, address _toAddress, uint _tokenId) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "./ONFT721CoreUpgradeable.sol";
import "./IONFT721Upgradeable.sol";

// NOTE: this ONFT contract has no public minting logic.
// must implement your own minting logic in child classes
contract ONFT721Upgradeable is Initializable, ONFT721CoreUpgradeable, ERC721Upgradeable, IONFT721Upgradeable {
    function __ONFT721Upgradeable_init(string memory _name, string memory _symbol, address _lzEndpoint) internal onlyInitializing {
        __ERC721_init_unchained(_name, _symbol);
        __ONFT721CoreUpgradeable_init_unchained(_lzEndpoint);
    }

    function __ONFT721Upgradeable_init_unchained(string memory _name, string memory _symbol, address _lzEndpoint) internal onlyInitializing {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ONFT721CoreUpgradeable, ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IONFT721Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ONFT721: send caller is not owner nor approved");
        require(ERC721Upgradeable.ownerOf(_tokenId) == _from, "ONFT721: send from incorrect owner");
        _transfer(_from, address(this), _tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual override {
        require(!_exists(_tokenId) || (_exists(_tokenId) && ERC721Upgradeable.ownerOf(_tokenId) == address(this)));
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
        } else {
            _transfer(address(this), _toAddress, _tokenId);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

library LzLib {
    // LayerZero communication
    struct CallParams {
        address payable refundAddress;
        address zroPaymentAddress;
    }

    //---------------------------------------------------------------------------
    // Address type handling

    struct AirdropParams {
        uint airdropAmount;
        bytes32 airdropAddress;
    }

    function buildAdapterParams(LzLib.AirdropParams memory _airdropParams, uint _uaGasLimit) internal pure returns (bytes memory adapterParams) {
        if (_airdropParams.airdropAmount == 0 && _airdropParams.airdropAddress == bytes32(0x0)) {
            adapterParams = buildDefaultAdapterParams(_uaGasLimit);
        } else {
            adapterParams = buildAirdropAdapterParams(_uaGasLimit, _airdropParams);
        }
    }

    // Build Adapter Params
    function buildDefaultAdapterParams(uint _uaGas) internal pure returns (bytes memory) {
        // txType 1
        // bytes  [2       32      ]
        // fields [txType  extraGas]
        return abi.encodePacked(uint16(1), _uaGas);
    }

    function buildAirdropAdapterParams(uint _uaGas, AirdropParams memory _params) internal pure returns (bytes memory) {
        require(_params.airdropAmount > 0, "Airdrop amount must be greater than 0");
        require(_params.airdropAddress != bytes32(0x0), "Airdrop address must be set");

        // txType 2
        // bytes  [2       32        32            bytes[]         ]
        // fields [txType  extraGas  dstNativeAmt  dstNativeAddress]
        return abi.encodePacked(uint16(2), _uaGas, _params.airdropAmount, _params.airdropAddress);
    }

    function getGasLimit(bytes memory _adapterParams) internal pure returns (uint gasLimit) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    // Decode Adapter Params
    function decodeAdapterParams(bytes memory _adapterParams) internal pure returns (uint16 txType, uint uaGas, uint airdropAmount, address payable airdropAddress) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            txType := mload(add(_adapterParams, 2))
            uaGas := mload(add(_adapterParams, 34))
        }
        require(txType == 1 || txType == 2, "Unsupported txType");
        require(uaGas > 0, "Gas too low");

        if (txType == 2) {
            assembly {
                airdropAmount := mload(add(_adapterParams, 66))
                airdropAddress := mload(add(_adapterParams, 86))
            }
        }
    }

    //---------------------------------------------------------------------------
    // Address type handling
    function bytes32ToAddress(bytes32 _bytes32Address) internal pure returns (address _address) {
        return address(uint160(uint(_bytes32Address)));
    }

    function addressToBytes32(address _address) internal pure returns (bytes32 _bytes32Address) {
        return bytes32(uint(uint160(_address)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

/* solhint-disable max-states-count */
contract BaseDeployer is Script {
    bytes32 internal saltDescriptor;
    bytes32 internal saltDBDImplementation;
    bytes32 internal saltDBD;

    uint256 internal deployerPrivateKey;

    address internal ownerAddress;
    address internal proxyCounterAddress;

    enum Chains {
        LocalFuji,
        LocalBSCTest,
        BscTest,
        Fuji,
        Bsc,
        Avalanche
    }

    enum Cycle {
        Dev,
        Test,
        Prod
    }

    /// @dev Mapping of chain enum to rpc url
    mapping(Chains => string) public forks;

    /// @dev environment variable setup for deployment
    /// @param cycle deployment cycle (dev, test, prod)
    modifier setEnvDeploy(Cycle cycle) {
        if (cycle == Cycle.Dev) {
            deployerPrivateKey = vm.envUint("LOCAL_DEPLOYER_KEY");
            ownerAddress = vm.envAddress("LOCAL_OWNER_ADDRESS");
        } else if (cycle == Cycle.Test) {
            deployerPrivateKey = vm.envUint("TEST_DEPLOYER_KEY");
            ownerAddress = vm.envAddress("TEST_OWNER_ADDRESS");
        } else {
            deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
            ownerAddress = vm.envAddress("OWNER_ADDRESS");
        }

        _;
    }

    /// @dev environment variable setup for upgrade
    /// @param cycle deployment cycle (dev, test, prod)
    modifier setEnvUpgrade(Cycle cycle) {
        if (cycle == Cycle.Dev) {
            deployerPrivateKey = vm.envUint("LOCAL_DEPLOYER_KEY");
            proxyCounterAddress = vm.envAddress("LOCAL_COUNTER_PROXY_ADDRESS");
        } else if (cycle == Cycle.Test) {
            deployerPrivateKey = vm.envUint("TEST_DEPLOYER_KEY");
            proxyCounterAddress = vm.envAddress("TEST_COUNTER_PROXY_ADDRESS");
        } else {
            deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
            proxyCounterAddress = vm.envAddress("COUNTER_PROXY_ADDRESS");
        }

        _;
    }

    /// @dev broadcast transaction modifier
    /// @param pk private key to broadcast transaction
    modifier broadcast(uint256 pk) {
        vm.startBroadcast(pk);

        _;

        vm.stopBroadcast();
    }

    constructor() {
        // Local
        forks[Chains.LocalFuji] = "localFuji";
        forks[Chains.LocalBSCTest] = "localBSCTest";

        // Testnet
        forks[Chains.BscTest] = "bsctest";
        forks[Chains.Fuji] = "fuji";

        // Mainnet
        forks[Chains.Bsc] = "bsc";
        forks[Chains.Avalanche] = "avalanche";
    }

    function createFork(Chains chain) public {
        vm.createFork(forks[chain]);
    }

    function createSelectFork(Chains chain) public {
        vm.createSelectFork(forks[chain]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";
import "forge-std/StdJson.sol";

import {DownbadDonkeys} from "../src/DownbadDonkeys.sol";
import {Descriptor} from "../src/Descriptor.sol";
import {IDownbadDonkeys} from "../src/interfaces/IDownbadDonkeys.sol";
import "../src/interfaces/VRFCoordinatorV2Interface.sol";

import {BaseDeployer} from "./BaseDeployer.s.sol";

contract DeployDBD is Script, BaseDeployer {
    using stdJson for string;

    struct DeployCreationData {
        uint256 donkeysBatchRevealSize;
        uint256 donkeysCollectionSize;
        bool isChainWithVRF;
        uint256 maxPerAddressDuringMint;
        address vrfCoordinator;
    }

    struct DeploySetupData {
        uint256 amountForDevs;
        uint256 amountForPremint;
        string baseURI;
        uint16 destChainId;
        uint256 endMintId;
        bytes32 keyhash;
        address lzEndpoint;
        uint256 maxPerAddressDuringMint;
        uint256 maxPerAddressDuringPremint;
        uint256 maxPerAddressDuringPublicMint;
        uint256 premintPhaseDuration;
        uint256 premintPrice;
        uint256 publicPhaseDuration;
        uint256 publicPrice;
        uint256 startMintId;
        uint256 unrevealedTime;
        string unrevealedURI;
    }

    DeployCreationData deployCreationData;
    DeploySetupData deploySetupData;

    address private create2addrDescriptor;
    address private create2addrDBDImplementation;
    address private cloneDeterministicDBD;

    DownbadDonkeys downbadDonkeys;
    Descriptor descriptor;

    IDownbadDonkeys.CollectionData collectionData;
    IDownbadDonkeys.CollectionOwnerData collectionOwnerData;

    /// @dev Compute the CREATE2 addresses for contracts
    /// @param saltDescriptor The salt for the descriptor contract.
    /// @param saltDBDImplementation The salt for the DBD implementation contract.
    /// @param saltDBD The salt for the DBD contract.
    function computeCreate2(bytes32 saltDescriptor, bytes32 saltDBDImplementation, bytes32 saltDBD) private {
        uint256 _donkeysBatchRevealSize = deployCreationData.donkeysBatchRevealSize;
        uint256 _donkeysCollectionSize = deployCreationData.donkeysCollectionSize;
        address _vrfCoordinator = deployCreationData.vrfCoordinator;
        bool _isChainWithVRF = deployCreationData.isChainWithVRF;

        create2addrDBDImplementation = computeCreate2Address(
            saltDBDImplementation, keccak256(abi.encodePacked(type(DownbadDonkeys).creationCode, ""))
        );

        cloneDeterministicDBD =
            Clones.predictDeterministicAddress(create2addrDBDImplementation, saltDBD, CREATE2_FACTORY);
        bytes memory constructorArgs = abi.encode(
            cloneDeterministicDBD, _donkeysBatchRevealSize, _donkeysCollectionSize, _vrfCoordinator, _isChainWithVRF
        );

        create2addrDescriptor = computeCreate2Address(
            saltDescriptor, keccak256(abi.encodePacked(type(Descriptor).creationCode, constructorArgs)), CREATE2_FACTORY
        );

        // console2.log("downbadDonkeysImplementation predicted", create2addrDBDImplementation);

        // console2.log("saltDescriptor", uint256(saltDescriptor));
        // console2.log("saltDBDImplementation", uint256(saltDBDImplementation));
        // console2.log("saltDBD", uint256(saltDBD));

        // console2.log("downbadDonkeysAddress predicted", cloneDeterministicDBD);
        // console2.log("Descriptor predicted", create2addrDescriptor, "\n");
        // console2.log("ownerAddress", vm.addr(deployerPrivateKey));
    }

    /// @dev Deploy contracts to mainnet.
    function deployContractsMainnet() external setEnvDeploy(Cycle.Prod) {
        Chains[] memory deployForks = new Chains[](2);

        saltDescriptor = bytes32(uint256(333));
        saltDBDImplementation = bytes32(uint256(444));
        saltDBD = bytes32(uint256(555));

        deployForks[0] = Chains.Bsc;
        deployForks[1] = Chains.Avalanche;

        createDeployMultichain(deployForks);
    }

    /// @dev Deploy contracts to testnet.
    function deployContractsTestnet() public setEnvDeploy(Cycle.Test) {
        Chains[] memory deployForks = new Chains[](2);

        saltDBD = bytes32(uint256(555));
        saltDBDImplementation = bytes32(uint256(444));
        saltDescriptor = bytes32(uint256(333));

        deployForks[0] = Chains.BscTest;
        deployForks[1] = Chains.Fuji;

        createDeployMultichain(deployForks);
    }

    /// @dev Deploy contracts to local.
    function deployContractsLocal() external setEnvDeploy(Cycle.Dev) {
        Chains[] memory deployForks = new Chains[](2);
        saltDescriptor = bytes32(uint256(1));
        saltDBDImplementation = bytes32(uint256(2));

        deployForks[0] = Chains.LocalFuji;
        deployForks[1] = Chains.LocalBSCTest;

        createDeployMultichain(deployForks);
    }

    /// @dev Deploy contracts to selected chains.
    /// @param _saltDescriptor The salt for the descriptor contract.
    /// @param _saltDBDImplementation The salt for the DBD implementation contract.
    /// @param deployForks The chains to deploy to.
    /// @param cycle The development cycle to set env variables (dev, test, prod).
    function deployContractsSelectedChains(
        uint256 _saltDescriptor,
        uint256 _saltDBDImplementation,
        Chains[] calldata deployForks,
        Cycle cycle
    ) external setEnvDeploy(cycle) {
        saltDescriptor = bytes32(_saltDescriptor);
        saltDBDImplementation = bytes32(_saltDBDImplementation);

        createDeployMultichain(deployForks);
    }

    /// @dev Helper to iterate over chains and select fork.
    /// @param deployForks The chains to deploy to.
    function createDeployMultichain(Chains[] memory deployForks) private {
        //string memory root = ;
        string memory path = string.concat(vm.projectRoot(), "/script/deployData.json");
        string memory jsonDeployData = vm.readFile(path);
        for (uint256 i; i < deployForks.length;) {
            console2.log("Deploying contracts to chain: ", forks[deployForks[i]], "\n");
            string memory creationName = string.concat(".", forks[deployForks[i]], ".creation");
            string memory setupName = string.concat(".", forks[deployForks[i]], ".setup");
            bytes memory bytesCreationData = jsonDeployData.parseRaw(creationName);
            bytes memory bytesSetupData = jsonDeployData.parseRaw(setupName);
            deployCreationData = abi.decode(bytesCreationData, (DeployCreationData));

            deploySetupData = abi.decode(bytesSetupData, (DeploySetupData));

            computeCreate2(saltDescriptor, saltDBDImplementation, saltDBD);

            createSelectFork(deployForks[i]);

            //chainDeployContracts();
            chainSetupContracts();

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to perform actual deployment.
    function chainDeployContracts() private broadcast(deployerPrivateKey) {
        uint256 _donkeysBatchRevealSize = deployCreationData.donkeysBatchRevealSize;
        uint256 _donkeysCollectionSize = deployCreationData.donkeysCollectionSize;
        address _vrfCoordinator = deployCreationData.vrfCoordinator;
        bool _isChainWithVRF = deployCreationData.isChainWithVRF;

        DownbadDonkeys downbadDonkeysImplementation = new DownbadDonkeys{
            salt: saltDBDImplementation
        }();

        address downbadDonkeysAddress = Clones.cloneDeterministic(address(downbadDonkeysImplementation), saltDBD);

        downbadDonkeys = DownbadDonkeys(downbadDonkeysAddress);

        collectionData =
            IDownbadDonkeys.CollectionData("DownbadDonkeys", "DBD", address(0), 0, _donkeysCollectionSize, 0, 0, 0);
        collectionOwnerData = IDownbadDonkeys.CollectionOwnerData(
            vm.addr(deployerPrivateKey), address(0), vm.addr(deployerPrivateKey), address(0), 0
        );

        downbadDonkeys.initialize(collectionData, collectionOwnerData);

        descriptor = new Descriptor{salt: saltDescriptor}(
            downbadDonkeysAddress,
            _donkeysBatchRevealSize,
            _donkeysCollectionSize,
            _vrfCoordinator,
            _isChainWithVRF
        );

        require(create2addrDescriptor == address(descriptor), "Address mismatch Descriptor");
        require(create2addrDBDImplementation == address(downbadDonkeysImplementation), "Address mismatch DBD");
        require(cloneDeterministicDBD == address(downbadDonkeys), "Address mismatch DBD");
    }

    function chainSetupContracts() private broadcast(deployerPrivateKey) {
        downbadDonkeys = DownbadDonkeys(cloneDeterministicDBD);

        console2.log("setDescriptor");
        downbadDonkeys.setDescriptor(address(create2addrDescriptor));
        console2.log("startNewPhases");
        downbadDonkeys.startNewPhases(
            block.timestamp + 120,
            block.timestamp + deploySetupData.premintPhaseDuration,
            block.timestamp + deploySetupData.premintPhaseDuration + deploySetupData.publicPhaseDuration,
            deploySetupData.premintPrice,
            deploySetupData.publicPrice,
            deploySetupData.amountForDevs,
            deploySetupData.amountForPremint,
            deploySetupData.maxPerAddressDuringMint,
            deploySetupData.startMintId,
            deploySetupData.endMintId
        );
        console2.log("setLZEndpoint");
        downbadDonkeys.setLZEndpoint(deploySetupData.lzEndpoint);
        console2.log("setTrustedRemote");
        downbadDonkeys.setTrustedRemote(
            deploySetupData.destChainId,
            abi.encodePacked(address(cloneDeterministicDBD), address(cloneDeterministicDBD))
        );

        descriptor = Descriptor(create2addrDescriptor);
        descriptor.setBaseURI(deploySetupData.baseURI);
        descriptor.setUnrevealedURI(deploySetupData.unrevealedURI);
        descriptor.setRevealStartTime(block.timestamp + deploySetupData.unrevealedTime);

        if (deployCreationData.isChainWithVRF) {
            VRFCoordinatorV2Interface vrfCoordinator = VRFCoordinatorV2Interface(deployCreationData.vrfCoordinator);
            uint64 subId = vrfCoordinator.createSubscription();
            vrfCoordinator.addConsumer(subId, create2addrDescriptor);

            descriptor.setVRF(deploySetupData.keyhash, subId, 2000000);
            console2.log("VRF setup");
        }
    }
}

//SPDX-License-Identifier: CC0
pragma solidity ^0.8.4;

//import "openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./chainlink/VRFConsumerBaseV2.sol";

import "src/interfaces/VRFCoordinatorV2Interface.sol";
import "src/interfaces/IBatchReveal.sol";

// Creator: Tubby Cats
/// https://github.com/tubby-cats/batch-nft-reveal

/// @title BatchReveal
/// @notice Implements a gas efficient way of revealing NFT URIs gradually
abstract contract BatchReveal is IBatchReveal, VRFConsumerBaseV2 {
    /// @dev Initialized on parent contract creation
    uint256 private collectionSize;
    int128 private intCollectionSize;

    /// @notice Size of the batch reveal
    /// @dev Must divide collectionSize
    uint256 public override revealBatchSize;

    /// @notice Randomized seeds used to shuffle TokenURIs
    mapping(uint256 => uint256) public override batchToSeed;

    /// @notice Last token that has been revealed
    uint256 public override lastTokenRevealed = 0;

    /// @dev Size of the array that will store already taken URIs numbers
    uint256 private _rangeLength;

    /// @notice Timestamp for the start of the reveal process
    /// @dev Can be set to zero for immediate reveal after token mint
    uint256 public override revealStartTime;

    /// @notice Time interval for gradual reveal
    /// @dev Can be set to zero in order to reveal the collection all at once
    uint256 public override revealInterval;

    /// @notice Contract uses VRF or pseudo-randomness
    bool public override useVRF;

    /// @notice Chainlink subscription ID
    uint64 public override subscriptionId;

    /// @notice The gas lane to use, which specifies the maximum gas price to bump to.
    /// For a list of available gas lanes on each network,
    /// see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 public override keyHash;

    /// @notice Depends on the number of requested values that you want sent to the
    /// fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    /// so 100,000 is a safe default for this example contract. Test and adjust
    /// this limit based on the network that you select, the size of the request,
    /// and the processing of the callback request in the fulfillRandomWords()
    /// function.
    uint32 public override callbackGasLimit;

    /// @notice Number of block confirmations that the coordinator will wait before triggering the callback
    /// The default is 3
    uint16 public constant override requestConfirmations = 3;

    /// @notice Next batch that will be revealed by VRF, if activated
    uint256 public override nextBatchToReveal;

    /// @notice Has a batch been force revealed
    /// @dev VRF will not be used anymore if a batch has been force revealed
    bool public override hasBeenForceRevealed;

    /// @notice Has the random number for a batch already been asked
    /// @dev Prevents people from spamming the random words request
    /// and therefore reveal more batches than expected
    mapping(uint256 => bool) public override vrfRequestedForBatch;

    struct Range {
        int128 start;
        int128 end;
    }

    /// @dev Emitted on revealNextBatch() and forceReveal()
    /// @param batchNumber The batch revealed
    /// @param batchSeed The random number drawn
    event Reveal(uint256 batchNumber, uint256 batchSeed);

    /// @dev BatchReveal initialization
    /// @param _revealBatchSize Size of the batch reveal
    /// @param _collectionSize Needs to be sent by child contract
    constructor(uint256 _revealBatchSize, uint256 _collectionSize) {
        if (_collectionSize % _revealBatchSize != 0 || _revealBatchSize == 0 || _revealBatchSize > _collectionSize) {
            revert BatchReveal__InvalidBatchRevealSize();
        }
        revealBatchSize = _revealBatchSize;
        collectionSize = _collectionSize;
        _rangeLength = (_collectionSize / _revealBatchSize) * 2;
        intCollectionSize = int128(int256(_collectionSize));
    }

    // Forked from openzeppelin
    /// @dev Returns the smallest of two numbers.
    /// @param _a First number to consider
    /// @param _b Second number to consider
    /// @return min Minimum between the two params
    function _min(int128 _a, int128 _b) internal pure returns (int128) {
        return _a < _b ? _a : _b;
    }

    /// @notice Fills the range array
    /// @dev Ranges include the start but not the end [start, end)
    /// @param _ranges initial range array
    /// @param _start beginning of the array to be added
    /// @param _end end of the array to be added
    /// @param _lastIndex last position in the range array to consider
    /// @return newLastIndex new lastIndex to consider for the future range to be added
    function _addRange(Range[] memory _ranges, int128 _start, int128 _end, uint256 _lastIndex)
        private
        view
        returns (uint256)
    {
        uint256 positionToAssume = _lastIndex;
        for (uint256 j; j < _lastIndex; j++) {
            int128 rangeStart = _ranges[j].start;
            int128 rangeEnd = _ranges[j].end;
            if (_start < rangeStart && positionToAssume == _lastIndex) {
                positionToAssume = j;
            }
            if (
                (_start < rangeStart && _end > rangeStart) || (rangeStart <= _start && _end <= rangeEnd)
                    || (_start < rangeEnd && _end > rangeEnd)
            ) {
                int128 length = _end - _start;
                _start = _min(_start, rangeStart);
                _end = _start + length + (rangeEnd - rangeStart);
                _ranges[j] = Range(-1, -1); // Delete
            }
        }
        for (uint256 pos = _lastIndex; pos > positionToAssume; pos--) {
            _ranges[pos] = _ranges[pos - 1];
        }
        _ranges[positionToAssume] = Range(_start, _min(_end, intCollectionSize));
        _lastIndex++;
        if (_end > intCollectionSize) {
            _addRange(_ranges, 0, _end - intCollectionSize, _lastIndex);
            _lastIndex++;
        }
        return _lastIndex;
    }

    /// @dev Adds the last batch into the ranges array
    /// @param _lastBatch Batch number to consider
    /// @return ranges Ranges array filled with every URI taken by batches smaller or equal to lastBatch
    function _buildJumps(uint256 _lastBatch) private view returns (Range[] memory) {
        Range[] memory ranges = new Range[](_rangeLength);
        uint256 lastIndex;
        for (uint256 i; i < _lastBatch; i++) {
            int128 start = int128(int256(_getFreeTokenId(batchToSeed[i], ranges)));
            int128 end = start + int128(int256(revealBatchSize));
            lastIndex = _addRange(ranges, start, end, lastIndex);
        }
        return ranges;
    }

    /// @dev Gets the random token URI number from tokenId
    /// @param _startId Token Id to consider
    /// @return uriId Revealed Token URI Id
    function _getShuffledTokenId(uint256 _startId) internal view returns (uint256) {
        uint256 batch = _startId / revealBatchSize;
        Range[] memory ranges = new Range[](_rangeLength);

        ranges = _buildJumps(batch);

        uint256 positionsToMove = (_startId % revealBatchSize) + batchToSeed[batch];

        return _getFreeTokenId(positionsToMove, ranges);
    }

    /// @dev Gets the shifted URI number from tokenId and range array
    /// @param _positionsToMoveStart Token URI offset if none of the URI Ids were taken
    /// @param _ranges Ranges array built by _buildJumps()
    /// @return uriId Revealed Token URI Id
    function _getFreeTokenId(uint256 _positionsToMoveStart, Range[] memory _ranges) private view returns (uint256) {
        int128 positionsToMove = int128(int256(_positionsToMoveStart));
        int128 id;

        for (uint256 round = 0; round < 2; round++) {
            for (uint256 i; i < _rangeLength; i++) {
                int128 start = _ranges[i].start;
                int128 end = _ranges[i].end;
                if (id < start) {
                    int128 finalId = id + positionsToMove;
                    if (finalId < start) {
                        return uint256(uint128(finalId));
                    } else {
                        positionsToMove -= start - id;
                        id = end;
                    }
                } else if (id < end) {
                    id = end;
                }
            }
            if ((id + positionsToMove) >= intCollectionSize) {
                positionsToMove -= intCollectionSize - id;
                id = 0;
            }
        }
        return uint256(uint128(id + positionsToMove));
    }

    /// @dev Sets batch seed for specified batch number
    /// @param _batchNumber Batch number that needs to be revealed
    function _setBatchSeed(uint256 _batchNumber) internal {
        uint256 randomness = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );

        // not perfectly random since the folding doesn't match bounds perfectly, but difference is small
        batchToSeed[_batchNumber] = randomness % (collectionSize - (_batchNumber * revealBatchSize));
    }

    /// @dev Returns true if a batch can be revealed
    /// @param _totalSupply Number of token already minted
    /// @return hasToRevealInfo Returns a bool saying whether a reveal can be triggered or not
    /// and the number of the next batch that will be revealed
    function _hasBatchToReveal(uint256 _totalSupply) internal view returns (bool, uint256) {
        uint256 batchNumber;
        unchecked {
            batchNumber = lastTokenRevealed / revealBatchSize;
        }

        // We don't want to reveal other batches if a VRF random words request is pending
        if (
            block.timestamp < revealStartTime + batchNumber * revealInterval
                || _totalSupply < lastTokenRevealed + revealBatchSize || vrfRequestedForBatch[batchNumber]
        ) {
            return (false, batchNumber);
        }

        return (true, batchNumber);
    }

    /// @dev Reveals next batch if possible
    /// @dev If using VRF, the reveal happens on the coordinator callback call
    /// @param _totalSupply Number of token already minted
    /// @return isRevealed Returns false if it is not possible to reveal the next batch
    function _revealNextBatch(uint256 _totalSupply) internal returns (bool) {
        uint256 batchNumber;
        bool canReveal;
        (canReveal, batchNumber) = _hasBatchToReveal(_totalSupply);

        if (!canReveal) {
            return false;
        }

        if (useVRF) {
            VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(
                keyHash, subscriptionId, requestConfirmations, callbackGasLimit, 1
            );
            vrfRequestedForBatch[batchNumber] = true;
        } else {
            lastTokenRevealed += revealBatchSize;
            _setBatchSeed(batchNumber);
            emit Reveal(batchNumber, batchToSeed[batchNumber]);
        }

        return true;
    }

    /// @dev Callback triggered by the VRF coordinator
    /// @param _randomWords Array of random numbers provided by the VRF coordinator
    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory _randomWords) internal override {
        if (hasBeenForceRevealed) {
            revert BatchReveal__HasBeenForceRevealed();
        }

        uint256 _batchToReveal = nextBatchToReveal++;
        uint256 _revealBatchSize = revealBatchSize;
        uint256 _seed = _randomWords[0] % (collectionSize - (_batchToReveal * _revealBatchSize));

        batchToSeed[_batchToReveal] = _seed;
        lastTokenRevealed += _revealBatchSize;

        emit Reveal(_batchToReveal, batchToSeed[_batchToReveal]);
    }

    /// @dev Force reveal, should be restricted to owner
    function _forceReveal() internal {
        uint256 batchNumber;
        unchecked {
            batchNumber = lastTokenRevealed / revealBatchSize;
            lastTokenRevealed += revealBatchSize;
        }

        _setBatchSeed(batchNumber);
        hasBeenForceRevealed = true;
        emit Reveal(batchNumber, batchToSeed[batchNumber]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin/utils/Strings.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/access/Ownable.sol";

import "./BatchReveal.sol";

import "src/interfaces/IDescriptor.sol";
import "src/interfaces/IDownbadDonkeys.sol";

contract Descriptor is Ownable, Pausable, BatchReveal, IDescriptor {
    using Strings for uint256;

    /// @dev Emitted on setVRF()
    /// @param _keyHash Keyhash of the gas lane wanted
    /// @param _subscriptionId Chainlink subscription ID
    /// @param _callbackGasLimit Max gas used by the coordinator callback
    event VRFSet(bytes32 _keyHash, uint64 _subscriptionId, uint32 _callbackGasLimit);

    /// @dev Emitted on setBaseURI()
    /// @param baseURI The new base URI
    event BaseURISet(string baseURI);

    /// @dev Emitted on setUnrevealedURI()
    /// @param unrevealedURI The new base URI
    event UnrevealedURISet(string unrevealedURI);

    //* Public variables */

    /// @notice Address of DownbadDonkeys contract
    IDownbadDonkeys public downbadDonkeys;

    /// @notice Full reveal is unlocked
    bool public fullRevealUnlocked;

    /// @notice Last token that can be revealed, based on tokens minted on another chain
    /// @dev can be modified by the owner
    uint256 public lastTokenMintedOnAnyChain;

    /// @notice If this contract will call VRF for randomness (true) or if VRF will be seeded from another chain's VRF response (false)
    bool public isChainWithVRF;

    /// @notice Token URI after collection reveal
    string public baseURI;

    /// @notice Token URI before the collection reveal
    string public unrevealedURI;

    //* Constructor */
    /// @param _downbadDonkeys Address of DownbadDonkeys contract
    /// @param _vrfCoordinator Address of VRF coordinator
    /// @param _isChainWithVRF If this contract will call VRF for randomness (true) or if VRF will be seeded from another chain's VRF response (false)
    constructor(
        address _downbadDonkeys,
        uint256 _donkeysBatchRevealSize,
        uint256 _donkeysCollectionSize,
        address _vrfCoordinator,
        bool _isChainWithVRF
    ) VRFConsumerBaseV2(_vrfCoordinator) BatchReveal(_donkeysBatchRevealSize, _donkeysCollectionSize) {
        if (_vrfCoordinator == address(0)) {
            revert Descriptor__InvalidCoordinator();
        }
        isChainWithVRF = _isChainWithVRF;
        downbadDonkeys = IDownbadDonkeys(_downbadDonkeys);

        if (downbadDonkeys.collectionSize() != _donkeysCollectionSize) {
            revert Descriptor__InvalidBatchRevealSetup();
        }
        _transferOwnership(tx.origin);
    }

    /// @notice Reveals the next batch if the reveal conditions are met
    /// @dev To request VRF randomness for tokens minted on another chain, the owner must call setLastTokenMintedForReveal() first with max token that can be revealed as an argument
    /// Otherwise, only tokens up to startMintId can be revealed
    function revealNextBatch() external whenNotPaused {
        if (!isChainWithVRF) {
            revert Descriptor__InvalidChain();
        }
        uint256 maxTokenIdToReveal = lastTokenMintedOnAnyChain > downbadDonkeys.startMintId()
            ? lastTokenMintedOnAnyChain
            : downbadDonkeys.startMintId();
        if (!_revealNextBatch(maxTokenIdToReveal)) {
            revert Descriptor__RevealNextBatchNotAvailable();
        }
        _emitMetadataBatchUpdated(lastTokenRevealed, lastTokenRevealed + revealBatchSize - 1);
    }

    //* External Owner functions */

    /// @notice This function can be called to reveal next batches, when tokens on another chain were minted
    /// @dev if _lastTokenMintedOnAnyChain is equal to collection size - 1, the full reveal is unlocked
    /// @dev Only callable by the owner.
    function setLastTokenMintedForReveal(uint256 _lastTokenMintedOnAnyChain) external onlyOwner {
        if (!isChainWithVRF) {
            revert Descriptor__InvalidChain();
        }
        if (_lastTokenMintedOnAnyChain > downbadDonkeys.collectionSize()) {
            revert Descriptor__InvalidTokenToReveal();
        }
        lastTokenMintedOnAnyChain = _lastTokenMintedOnAnyChain;
    }

    /// @notice Set the base URI for all tokens
    /// @dev Only callable by the owner.
    /// @param _baseURI Base URI for all tokens
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        if (lastTokenRevealed > 0) {
            _emitMetadataBatchUpdated(0, lastTokenRevealed - 1);
        }
        emit BaseURISet(baseURI);
    }

    /// @notice Set the unrevealed URI for all tokens
    /// @dev Only callable by the owner.
    /// @param _unrevealedURI Unrevealed URI for all tokens
    function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
        _emitMetadataBatchUpdated(lastTokenRevealed, downbadDonkeys.collectionSize() - 1);

        emit UnrevealedURISet(unrevealedURI);
    }

    /// @notice Set VRF configuration
    /// @param _keyHash Keyhash of the gas lane wanted
    /// @param _subscriptionId Chainlink subscription ID
    /// @param _callbackGasLimit Max gas used by the coordinator callback
    function setVRF(bytes32 _keyHash, uint64 _subscriptionId, uint32 _callbackGasLimit) external onlyOwner {
        if (!isChainWithVRF) {
            revert Descriptor__InvalidChain();
        }
        (, uint32 _maxGasLimit, bytes32[] memory s_provingKeyHashes) =
            VRFCoordinatorV2Interface(vrfCoordinator).getRequestConfig();

        // 20_000 is the cost of storing one word, callback cost will never be lower than that
        if (_callbackGasLimit > _maxGasLimit || _callbackGasLimit < 20_000) {
            revert Descriptor__InvalidCallbackGasLimit();
        }

        bool keyHashFound;
        for (uint256 i; i < s_provingKeyHashes.length; i++) {
            if (s_provingKeyHashes[i] == _keyHash) {
                keyHashFound = true;
                break;
            }
        }

        if (!keyHashFound) {
            revert Descriptor__InvalidKeyHash();
        }

        (,,, address[] memory consumers) = VRFCoordinatorV2Interface(vrfCoordinator).getSubscription(_subscriptionId);

        bool isInConsumerList;
        for (uint256 i; i < consumers.length; i++) {
            if (consumers[i] == address(this)) {
                isInConsumerList = true;
                break;
            }
        }

        if (!isInConsumerList) {
            revert Descriptor__IsNotInTheConsumerList();
        }

        useVRF = true;

        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;

        emit VRFSet(_keyHash, _subscriptionId, _callbackGasLimit);
    }

    function setRevealStartTime(uint256 _revealStartTime) external onlyOwner {
        revealStartTime = _revealStartTime;
    }

    /// @notice Seed random seeds on chain, that relies on another chain's VRF response
    /// @dev Only callable by the owner.
    /// @dev Input to this function can be taken from getRandomSeeds() function on chain with fullfilled VRF response
    /// @param randomSeeds Random seeds to seed
    function seedRandomSeeds(uint256[] calldata randomSeeds) external onlyOwner {
        if (isChainWithVRF) {
            revert Descriptor__InvalidChain();
        }
        uint256 seedsAmount = randomSeeds.length;
        for (uint256 i; i < seedsAmount; i++) {
            batchToSeed[i] = randomSeeds[i];
        }
        uint256 previousLastTokenRevealed = lastTokenRevealed;
        lastTokenRevealed = seedsAmount * revealBatchSize;
        _emitMetadataBatchUpdated(previousLastTokenRevealed, lastTokenRevealed - 1);
    }

    //* External view functions */

    /// @notice Returns token URI for a given token ID
    /// @param _id Token ID
    /// @return Token URI
    function tokenURI(uint256 _id) public view returns (string memory) {
        if (_id >= lastTokenRevealed) {
            return unrevealedURI;
        } else {
            return string(abi.encodePacked(baseURI, _getShuffledTokenId(_id).toString()));
        }
    }

    /// @notice Returns random seeds that were fed to this contract, either by VRF or by seedRandomSeeds()
    /// @dev Can be used to retrieve input to seedRandomSeeds() and to verify, that it returns the same values on all chains
    /// @return randomSeeds array of random seeds that are used to determine token IDs
    function getRandomSeeds() external view returns (uint256[] memory randomSeeds) {
        uint256 maxTokenIdToReveal = lastTokenMintedOnAnyChain > downbadDonkeys.startMintId()
            ? lastTokenMintedOnAnyChain
            : downbadDonkeys.startMintId();

        (, uint256 nextBatchToReveal) = _hasBatchToReveal(maxTokenIdToReveal);
        randomSeeds = new uint256[](nextBatchToReveal);
        for (uint256 i; i < nextBatchToReveal; i++) {
            randomSeeds[i] = batchToSeed[i];
        }
    }

    // * Internal functions */

    function _emitMetadataBatchUpdated(uint256 _fromTokenId, uint256 _toTokenId) internal {
        downbadDonkeys.metadataBatchUpdated(_fromTokenId, _toTokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";
import "openzeppelin-upgradeable/security/PausableUpgradeable.sol";
import "operator-filter-registry/IOperatorFilterRegistry.sol";
import "solidity-examples-upgradeable/token/ONFT721/ONFT721Upgradeable.sol";
import "src/interfaces/IDescriptor.sol";
import "src/interfaces/IDownbadDonkeys.sol";
import "src/interfaces/IERC4906.sol";

contract DownbadDonkeys is ONFT721Upgradeable, ERC2981Upgradeable, PausableUpgradeable, IERC4906, IDownbadDonkeys {
    //* Public variables */

    /// @notice The starting mint number on this chain
    /// @dev It increases with each mint. After all items are minted, it will be equal to `endMintId + 1`
    uint256 public startMintId;

    /// @notice The last mint number on this chain
    uint256 public endMintId;

    /// @notice If new phases can be added (false) or not (true)
    /// @dev Once set true, cannot be changed back
    bool public creatingNewPhasesLocked;

    /// @notice Amount of tokens minted on this chain
    uint256 public amountMintedOnThisChain;

    /// @notice Amount of tokens existing on this chain
    uint256 public totalSupply;

    /// @notice Tracks the amount of pre-minted NFTs that have been claimed
    uint256 public amountClaimedDuringPreMint;

    /// @notice Tracks the amount of NFTs minted on Public Sale phase
    uint256 public amountMintedDuringPublicSale;

    /// @notice Start time of the pre-mint in seconds
    uint256 public preMintStartTime;

    /// @notice Start time of the public sale in seconds
    /// @dev A timestamp greater than the premint start
    uint256 public publicSaleStartTime;

    /// @notice End time of the public sale in seconds
    /// @dev A timestamp greater than the public sale start
    uint256 public publicSaleEndTime;

    /// @notice Tracks the amount of NFTs minted in the Pre-Mint phase
    uint256 public amountMintedDuringPreMint;

    /// @notice Max amount of NFTs an address can mint in public phases
    uint256 public maxPerAddressDuringMint;

    /// @notice Tracks the amount of NFTs minted by owner
    uint256 public amountMintedByDevs;

    // @notice Amount of NFTs reserved for premint (e.g 1000)
    uint256 public amountForAllowlist;

    /// @notice Amount of NFTs reserved for the owner (e.g 200)
    /// @dev It can be minted any time via `devMint`
    uint256 public amountForDevs;

    /// @notice The amount of NFTs each allowed address can mint during pre-mint
    mapping(address => uint256) public premintList;

    /// @notice The amount of NFTs each address has minted
    mapping(address => uint256) public amountMintedByAddress;

    /// @notice Price of one NFT for people on the mint list
    /// @dev allowlistPrice is scaled to 1e18
    uint256 public allowlistPrice;

    /// @notice Price of one NFT during the public sale
    /// @dev salePrice is scaled to 1e18
    uint256 public salePrice;

    /// @notice The collection size (e.g. 10000)
    uint256 public collectionSize;

    /// @notice Descriptor contract
    IDescriptor public descriptor;

    /// @notice Contract filtering allowed operators, preventing unauthorized contract to transfer NFTs
    /// By default, DownbadDonkeys contract is subscribed to OpenSea's Curated Subscription Address at 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
    IOperatorFilterRegistry public operatorFilterRegistry;

    //* Private variables */

    /// @dev Set of pending pre-mint data (user address and quantity)
    PreMintDataSet private _pendingPreMints;

    //* Events */

    /// @dev Emitted on preMint()
    /// @param sender The address that minted
    /// @param quantity Amount of NFTs minted
    /// @param price Price of 1 NFT
    event PreMint(address indexed sender, uint256 quantity, uint256 price);

    /// @dev Emitted on devMint()
    /// @param sender The address that minted
    /// @param quantity Amount of NFTs minted
    event DevMint(address indexed sender, uint256 quantity);

    /// @dev Emitted on setRoyaltyInfo()
    /// @param receiver Royalty fee collector
    /// @param feePercent Royalty fee percent in basis point
    event DefaultRoyaltySet(address indexed receiver, uint256 feePercent);

    /// @dev Emitted on _setMintPrices()
    /// @param allowlistPrice Price of 1 NFT for people on the mint list
    /// @param salePrice Price of 1 NFT during the public sale
    event MintPricesSet(uint256 allowlistPrice, uint256 salePrice);

    /// @dev Emitted on  claimPreMint(), batchClaimPreMint(), publicSaleMint()
    /// @param sender The address that minted
    /// @param quantity Amount of NFTs minted
    /// @param price Price in native token for the NFTs
    /// @param startTokenId The token ID of the first minted NFT:
    /// if `startTokenId` = 100 and `quantity` = 2, `sender` minted 100 and 101
    /// @param phase The phase in which the mint occurs
    event Mint(address indexed sender, uint256 quantity, uint256 price, uint256 startTokenId, Phase phase);

    /// @dev Emitted on setPreMintStartTime()
    /// @param preMintStartTime New pre-mint start time
    event PreMintStartTimeSet(uint256 preMintStartTime);

    /// @dev Emitted on setPublicSaleStartTime()
    /// @param publicSaleStartTime New public sale start time
    event PublicSaleStartTimeSet(uint256 publicSaleStartTime);

    /// @dev Emitted on setPublicSaleEndTime()
    /// @param publicSaleEndTime New public sale end time
    event PublicSaleEndTimeSet(uint256 publicSaleEndTime);

    /// @dev Emitted on seedPremintlist()
    event PremintlistSeeded();

    /// @dev Emitted on withdrawNative()
    /// @param sender The address that withdrew the tokens
    /// @param amount Amount of native token transfered to `sender`
    event Withdraw(address indexed sender, uint256 amount);

    /// @dev Emitted on setLZEndpoint()
    event LZEndpointSet(address endpoint);

    /// @dev Emitted on updateOperatorFilterRegistryAddress()
    /// @param operatorFilterRegistry New operator filter registry
    event OperatorFilterRegistryUpdated(IOperatorFilterRegistry indexed operatorFilterRegistry);

    //* Modifiers */

    /// @notice Pre-mints can be claimed starting from the public phase
    /// (including after sale ends)
    modifier isClaimPreMintAvailable() {
        if (block.timestamp < publicSaleStartTime) {
            revert DownbadDonkeys__WrongPhase();
        }
        _;
    }

    /// @notice Checks if the current phase matches the required phase
    modifier atPhase(Phase _phase) {
        if (currentPhase() != _phase) {
            revert DownbadDonkeys__WrongPhase();
        }
        _;
    }

    /// @notice Checks if function is called from a contract
    modifier isEOA() {
        if (tx.origin != msg.sender) {
            revert DownbadDonkeys__Unauthorized();
        }
        _;
    }

    /// @notice Phase time can be updated if it has been initialized and
    // the time has not passed
    /// @dev Enables updating phase times after the sale has ended
    modifier isTimeUpdateAllowed(uint256 _phaseTime) {
        if (_phaseTime == 0) {
            revert DownbadDonkeys__NotInitialized();
        }
        if (currentPhase() == Phase.Ended) {
            _;
        }
        if (_phaseTime <= block.timestamp) {
            revert DownbadDonkeys__WrongPhase();
        }
        _;
    }

    modifier onlyDescriptor() {
        if (msg.sender != address(descriptor)) {
            revert DownbadDonkeys__OnlyDescriptor();
        }
        _;
    }

    /// @notice Allow spending tokens from addresses with balance
    /// Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
    /// from an EOA.
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /// @notice Allow approving tokens transfers
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /// @dev Disable initializers in contract implementation
    constructor() {
        _disableInitializers();
    }

    function initialize(CollectionData calldata _collectionData, CollectionOwnerData calldata _ownerData)
        external
        initializer
    {
        __ERC2981_init();
        __Pausable_init();
        __ONFT721Upgradeable_init(_collectionData.name, _collectionData.symbol, address(0));
        collectionSize = 10_000;
        _setDefaultRoyalty(_ownerData.royaltyReceiver, 500);
        // Initialize the operator filter registry and subcribe to OpenSea's list
        IOperatorFilterRegistry _operatorFilterRegistry =
            IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
        if (address(_operatorFilterRegistry).code.length > 0) {
            _operatorFilterRegistry.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
        }
        _updateOperatorFilterRegistryAddress(_operatorFilterRegistry);
        _transferOwnership(_ownerData.owner);
    }

    //* External functions */

    /// @notice Mint NFTs during the public sale
    /// @param _quantity Quantity of NFTs to mint
    function publicSaleMint(uint256 _quantity) external payable isEOA whenNotPaused atPhase(Phase.PublicSale) {
        if (numberMintedWithPreMint(msg.sender) + _quantity > maxPerAddressDuringMint) {
            revert DownbadDonkeys__CanNotMintThisMany();
        }
        // ensure sufficient supply for devs. note we can skip this check
        // in prior phases as long as they do not exceed the phase allocation
        // and the total phase allocations do not exceed collection size
        uint256 remainingDevAmt = amountForDevs - amountMintedByDevs;
        if (_currentTokenIdWithPremint() + remainingDevAmt + _quantity > endMintId + 1) {
            revert DownbadDonkeys__MaxSupplyReached();
        }
        uint256 price = salePrice;
        uint256 total = price * _quantity;

        amountMintedDuringPublicSale += _quantity;
        _batchMint(msg.sender, _quantity);
        emit Mint(msg.sender, _quantity, price, startMintId - _quantity, Phase.PreMint);

        _refundIfOver(total);
    }

    /// @notice Mint NFTs during the pre-mint
    /// @param _quantity Quantity of NFTs to mint
    function preMint(uint96 _quantity) external payable whenNotPaused atPhase(Phase.PreMint) {
        if (_quantity == 0) {
            revert DownbadDonkeys__InvalidQuantity();
        }
        if (_quantity > premintList[msg.sender]) {
            revert DownbadDonkeys__NotEligibleForPreMint();
        }
        if (amountMintedDuringPreMint + _quantity > amountForAllowlist) {
            revert DownbadDonkeys__MaxSupplyReached();
        }
        premintList[msg.sender] -= _quantity;
        amountMintedDuringPreMint += _quantity;
        _addPreMint(msg.sender, _quantity);
        uint256 price = allowlistPrice;
        uint256 totalCost = price * _quantity;
        emit PreMint(msg.sender, _quantity, price);
        _refundIfOver(totalCost);
    }

    /// @notice Claim pre-minted NFTs
    function claimPreMint() external whenNotPaused isClaimPreMintAvailable {
        uint256 quantity = userPendingPreMints(msg.sender);
        if (quantity == 0) {
            revert DownbadDonkeys__InvalidClaim();
        }
        _removePreMint(msg.sender, uint96(quantity));
        amountClaimedDuringPreMint += quantity;

        uint256 price = allowlistPrice;
        _batchMint(msg.sender, quantity);
        emit Mint(msg.sender, quantity, price, startMintId - quantity, Phase.PreMint);
    }

    /// @notice Claim pre-minted NFTs for users
    /// @param _maxQuantity Max quantity of NFTs to mint
    function batchClaimPreMint(uint96 _maxQuantity) external whenNotPaused isClaimPreMintAvailable {
        if (_maxQuantity == 0) {
            revert DownbadDonkeys__InvalidQuantity();
        }
        if (amountMintedDuringPreMint == amountClaimedDuringPreMint) {
            revert DownbadDonkeys__InvalidClaim();
        }
        uint256 price = allowlistPrice;
        uint96 remQuantity = _maxQuantity;
        uint96 mintQuantity;
        for (uint256 len = _pendingPreMints.preMintDataArr.length; len > 0 && remQuantity > 0;) {
            PreMintData memory preMintData = _pendingPreMints.preMintDataArr[len - 1];
            if (preMintData.quantity > remQuantity) {
                mintQuantity = remQuantity;
            } else {
                mintQuantity = preMintData.quantity;
                --len;
            }
            _removePreMint(preMintData.sender, mintQuantity);
            remQuantity -= mintQuantity;

            _batchMint(preMintData.sender, mintQuantity);
            emit Mint(preMintData.sender, mintQuantity, price, startMintId - mintQuantity, Phase.PreMint);
        }
        amountClaimedDuringPreMint += (_maxQuantity - remQuantity);
    }

    function revealNextBatch() external {
        descriptor.revealNextBatch();
    }

    //* External Owner functions */

    /// @notice Start the two phases of the sale
    /// @dev Calling this function resets amountMintedByDevs, amountMintedDuringPreMint,
    /// amountClaimedDuringPreMint and amountMintedDuringPublicSale to 0
    /// @dev This will not reset mapping `amountMintedByAddress`
    /// @dev Can be called only after all preminted tokens are claimed
    /// @dev SETTING WRONG _startMintId OR _endMintId MIGHT RESULT IN MINTING DOUBLE TOKEN IDS
    /// ON DIFFERENT CHAINS OR NOT BEING ABLE TO MINT PLANNED TOKEN IDs
    /// USE WITH CAUTION, AS CONTRACT DOESN'T ENFORCE PROPER PARAMETERS
    /// @param _preMintStartTime Pre-mint start time in seconds
    /// @param _publicSaleStartTime Public sale start time in seconds
    /// @param _publicSaleEndTime Public sale end time in seconds
    /// @param _allowlistPrice Price of the premint sale in native token
    /// @param _salePrice Price of the public sale in native token
    /// @param _amountForDevs Amount of NFTs to mint for devs
    /// @param _amountForAllowlist Amount of NFTs to mint for allowlist
    /// @param _maxPerAddressDuringMint Max NFTs per address during mint
    /// @param _startMintId Start mint id
    /// @param _endMintId End mint id
    function startNewPhases(
        uint256 _preMintStartTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _allowlistPrice,
        uint256 _salePrice,
        uint256 _amountForDevs,
        uint256 _amountForAllowlist,
        uint256 _maxPerAddressDuringMint,
        uint256 _startMintId,
        uint256 _endMintId
    ) external onlyOwner {
        if (creatingNewPhasesLocked) {
            revert DownbadDonkeys__CantAddNewPhasesAnymore();
        }

        if (amountMintedDuringPreMint - amountClaimedDuringPreMint > 0) {
            revert DownbadDonkeys__UnclaimedTokensExist();
        }

        _setMintTimes(_preMintStartTime, _publicSaleStartTime, _publicSaleEndTime);

        _setMintPrices(_allowlistPrice, _salePrice);

        amountMintedByDevs = 0;
        amountMintedDuringPreMint = 0;
        amountClaimedDuringPreMint = 0;
        amountMintedDuringPublicSale = 0;

        _setTokensToMint(_amountForDevs, _amountForAllowlist, _maxPerAddressDuringMint, _startMintId, _endMintId);
    }

    /// @notice Mint NFTs to the project owner
    /// @dev Can only mint up to `amountForDevs`
    /// @param _quantity Quantity of NFTs to mint
    function devMint(uint256 _quantity) external onlyOwner whenNotPaused {
        if (_currentTokenIdWithPremint() + _quantity > endMintId + 1) {
            revert DownbadDonkeys__InvalidQuantity();
        }
        if (amountMintedByDevs + _quantity > amountForDevs) {
            revert DownbadDonkeys__MaxSupplyForDevReached();
        }
        amountMintedByDevs += _quantity;

        _batchMint(msg.sender, _quantity);
        emit DevMint(msg.sender, _quantity);
    }

    /// @notice Set amount of NFTs mintable per address during the premint phase
    /// @param _addresses List of addresses allowed to mint during the premint phase
    /// @param _numNfts List of NFT quantities mintable per address
    function seedPremintlist(address[] calldata _addresses, uint256[] calldata _numNfts) external onlyOwner {
        uint256 addressesLength = _addresses.length;
        if (addressesLength != _numNfts.length) {
            revert DownbadDonkeys__WrongAddressesAndNumSlotsLength();
        }
        for (uint256 i; i < addressesLength; i++) {
            premintList[_addresses[i]] = _numNfts[i];
        }

        emit PremintlistSeeded();
    }

    /// @notice Pause the contract. This will pause all mint and claim functions
    /// @dev Can only be called when the contract is not paused
    /// @dev Can only be called by the owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause the contract. This will unpause all mint and claim functions
    /// @dev Can only be called when the contract is paused
    /// @dev Can only be called by the owner
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Lock the token ids to mint
    /// @dev This action is irreversible
    /// @dev Starting new phases will be impossible after this function is called
    function lockNewMintPhasesForever() external onlyOwner {
        creatingNewPhasesLocked = true;
    }

    /// @notice Set the pre-mint start time. Can only be set after phases
    /// have been initialized.
    /// @dev Only callable by owner
    /// @param _preMintStartTime New pre-mint start time
    function setPreMintStartTime(uint256 _preMintStartTime) external onlyOwner isTimeUpdateAllowed(preMintStartTime) {
        if (publicSaleStartTime < _preMintStartTime) {
            revert DownbadDonkeys__InvalidPhases();
        }
        preMintStartTime = _preMintStartTime;
        emit PreMintStartTimeSet(_preMintStartTime);
    }

    /// @notice Set the public sale start time. Can only be set after phases
    /// have been initialized.
    /// @dev Only callable by owner
    /// @param _publicSaleStartTime New public sale start time
    function setPublicSaleStartTime(uint256 _publicSaleStartTime)
        external
        onlyOwner
        isTimeUpdateAllowed(publicSaleStartTime)
    {
        if (_publicSaleStartTime < preMintStartTime || publicSaleEndTime < _publicSaleStartTime) {
            revert DownbadDonkeys__InvalidPhases();
        }

        publicSaleStartTime = _publicSaleStartTime;
        emit PublicSaleStartTimeSet(_publicSaleStartTime);
    }

    /// @notice Set the public sale end time. Can only be set after phases
    /// have been initialized.
    /// @dev Only callable by owner
    /// @param _publicSaleEndTime New public sale end time
    function setPublicSaleEndTime(uint256 _publicSaleEndTime)
        external
        onlyOwner
        isTimeUpdateAllowed(publicSaleEndTime)
    {
        if (_publicSaleEndTime < publicSaleStartTime) {
            revert DownbadDonkeys__InvalidPhases();
        }
        publicSaleEndTime = _publicSaleEndTime;
        emit PublicSaleEndTimeSet(_publicSaleEndTime);
    }

    /// @notice Set the royalty fee
    /// @param _receiver Royalty fee collector
    /// @param _feePercent Royalty fee percent in basis point
    function setRoyaltyInfo(address _receiver, uint96 _feePercent) external onlyOwner {
        // Royalty fees are limited to 25%
        if (_feePercent > 2_500) {
            revert DownbadDonkeys__InvalidRoyaltyInfo();
        }
        _setDefaultRoyalty(_receiver, _feePercent);
        emit DefaultRoyaltySet(_receiver, _feePercent);
    }

    /// @notice Set Descriptor address
    /// @param _descriptor address of descriptor to set
    function setDescriptor(address _descriptor) external onlyOwner {
        if (_descriptor == address(0)) revert DownbadDonkeys__ZeroAddress();
        descriptor = IDescriptor(_descriptor);
    }

    /// @notice Set LayerZeroEndpoint address
    /// @param _endpoint address of LayerZeroEndpoint to set
    function setLZEndpoint(address _endpoint) external onlyOwner {
        if (_endpoint == address(0)) revert DownbadDonkeys__ZeroAddress();
        lzEndpoint = ILayerZeroEndpointUpgradeable(_endpoint);
        emit LZEndpointSet(_endpoint);
    }

    /// @notice Withdraw native token to the given recipient
    /// @param _to Recipient of the earned native token
    function withdrawNative(address _to) external onlyOwner whenNotPaused {
        uint256 amount = address(this).balance;
        bool sent;
        (sent,) = _to.call{value: amount}("");
        if (!sent) {
            revert DownbadDonkeys__TransferFailed();
        }

        emit Withdraw(_to, amount);
    }

    function metadataBatchUpdated(uint256 _fromTokenId, uint256 _toTokenId) external onlyDescriptor {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

    function metadataUpdated(uint256 _tokenId) external onlyDescriptor {
        emit MetadataUpdate(_tokenId);
    }

    //* External view functions */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert DownbadDonkeys__InvalidTokenId();
        return descriptor.tokenURI(tokenId);
    }

    /// @notice Returns the current phase
    /// @return phase Current phase
    function currentPhase() public view returns (Phase) {
        if (
            preMintStartTime == 0 || publicSaleStartTime == 0 || publicSaleEndTime == 0
                || block.timestamp < preMintStartTime
        ) {
            return Phase.NotStarted;
        } else if (startMintId == endMintId + 1) {
            return Phase.Ended;
        } else if (block.timestamp >= preMintStartTime && block.timestamp < publicSaleStartTime) {
            return Phase.PreMint;
        } else if (block.timestamp >= publicSaleStartTime && block.timestamp < publicSaleEndTime) {
            return Phase.PublicSale;
        }
        return Phase.Ended;
    }

    /// @notice The remaining no. of pre-minted NFTs for the user address
    /// @param _user user address
    function userPendingPreMints(address _user) public view returns (uint256) {
        uint256 idx = _pendingPreMints.indexes[_user];
        if (idx == 0) {
            return 0;
        }
        return _pendingPreMints.preMintDataArr[idx - 1].quantity;
    }

    /// @notice Number minted by user including pre-mints
    function numberMintedWithPreMint(address _owner) public view returns (uint256) {
        return amountMintedByAddress[_owner] + userPendingPreMints(_owner);
    }

    /// @dev See {IERC165-supportsInterface}.
    /// @param interfaceId The interface to check
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable, ONFT721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return ERC165Upgradeable.supportsInterface(interfaceId) || ERC721Upgradeable.supportsInterface(interfaceId)
            || ERC2981Upgradeable.supportsInterface(interfaceId) || interfaceId == bytes4(0x49064906) // IERC4906
            || super.supportsInterface(interfaceId);
    }

    //* External view functions for LaunchpegLens Compatibility */

    /// @notice Returns unrevealed URI
    /// @return URI of unrevealed NFT
    function unrevealedURI() external view returns (string memory) {
        return descriptor.unrevealedURI();
    }

    /// @notice Returns base URI
    /// @return Base URI
    function baseURI() external view returns (string memory) {
        return descriptor.baseURI();
    }

    /// @notice Returns Project Owner Role
    /// @dev This contract doesn't have a project owner role, but we need to implement this function for LaunchpegLens compatibility
    /// @return Project Owner Role
    function PROJECT_OWNER_ROLE() external pure returns (bytes32) {
        return keccak256("PROJECT_OWNER_ROLE");
    }

    /// @notice Always returns 0, as this contract doesn't have a project owner role
    function getRoleMemberCount(bytes32) external view returns (uint256) {
        return 0;
    }

    /// @notice Always returns 0, as this contract doesn't restrict time to withdraw tokens
    function withdrawAVAXStartTime() external view returns (uint256) {
        return 0;
    }

    /// @notice Returns number of NFTs minted by the user
    /// @param user User address
    /// @return Number of NFTs minted by the user
    function numberMinted(address user) external view returns (uint256) {
        return amountMintedByAddress[user];
    }

    /// @notice Returns number of NFTs that can be minted during pre-mint phase by the user
    /// @param user User address
    /// @return Number of NFTs that can be minted during pre-mint phase by the user
    function allowlist(address user) external view returns (uint256) {
        return premintList[user];
    }

    /// @notice This contract doesn't use allowlist, so this function always returns publicSaleStartTime for LaunchpegLens compatibility
    /// @return publicSaleStartTime
    function allowlistStartTime() external view returns (uint256) {
        return publicSaleStartTime;
    }

    /// @notice This contract doesn't use allowlist, so this function always returns 0 for LaunchpegLens compatibility
    /// @return 0
    function amountMintedDuringAllowlist() external view returns (uint256) {
        return 0;
    }

    //* Internal functions */

    /// @dev Verifies that enough native token has been sent by the sender and refunds the extra tokens if any
    /// @param _price The price paid by the sender for minting NFTs
    function _refundIfOver(uint256 _price) internal {
        if (msg.value < _price) {
            revert DownbadDonkeys__NotEnoughNative(msg.value);
        }
        if (msg.value > _price) {
            (bool success,) = msg.sender.call{value: msg.value - _price}("");
            if (!success) {
                revert DownbadDonkeys__TransferFailed();
            }
        }
    }

    /// @dev Total amount of minted tokens including pre-mints
    function _currentTokenIdWithPremint() internal view returns (uint256) {
        return startMintId + (amountMintedDuringPreMint - amountClaimedDuringPreMint);
    }

    /// @dev Checks if the address (the operator) trying to transfer the NFT is allowed
    /// @param operator Address of the operator
    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    function _setMintTimes(uint256 _preMintStartTime, uint256 _publicSaleStartTime, uint256 _publicSaleEndTime)
        internal
    {
        if (
            _preMintStartTime < block.timestamp || _publicSaleStartTime < _preMintStartTime
                || _publicSaleEndTime < _publicSaleStartTime
        ) {
            revert DownbadDonkeys__InvalidPhases();
        }

        preMintStartTime = _preMintStartTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;

        emit PreMintStartTimeSet(preMintStartTime);
        emit PublicSaleStartTimeSet(publicSaleStartTime);
        emit PublicSaleEndTimeSet(publicSaleEndTime);
    }

    function _setMintPrices(uint256 _allowlistPrice, uint256 _salePrice) internal {
        if (_allowlistPrice > _salePrice) {
            revert DownbadDonkeys__InvalidAllowlistPrice();
        }

        salePrice = _salePrice;
        allowlistPrice = _allowlistPrice;
        emit MintPricesSet(allowlistPrice, salePrice);
    }

    function _setTokensToMint(
        uint256 _amountForDevs,
        uint256 _amountForAllowlist,
        uint256 _maxPerAddressDuringMint,
        uint256 _startMintId,
        uint256 _endMintId
    ) internal {
        if (
            _endMintId + 1 > collectionSize || _startMintId > _endMintId
                || _amountForDevs + _amountForAllowlist > _endMintId - _startMintId + 1
                || _amountForAllowlist > _endMintId - _startMintId + 1
        ) revert DownbadDonkeys__InvalidMintIdSetup();

        amountForDevs = _amountForDevs;
        amountForAllowlist = _amountForAllowlist;
        maxPerAddressDuringMint = _maxPerAddressDuringMint;

        startMintId = _startMintId;
        endMintId = _endMintId;
    }

    //* Private functions */

    /// @dev Adds pre-mint data to the pre-mint data set
    /// @param _sender address to mint NFTs to
    /// @param _quantity No. of NFTs to add to mint quantity
    function _addPreMint(address _sender, uint96 _quantity) private {
        PreMintDataSet storage set = _pendingPreMints;
        uint256 idx = set.indexes[_sender];
        // user exists in set
        if (idx != 0) {
            set.preMintDataArr[idx - 1].quantity += _quantity;
        } else {
            PreMintData memory preMintData = PreMintData({sender: _sender, quantity: _quantity});
            set.preMintDataArr.push(preMintData);
            set.indexes[_sender] = set.preMintDataArr.length;
        }
    }

    /// @dev Removes pre-mint data from the pre-mint data set
    /// @param _sender address to mint NFTs to
    /// @param _quantity No. of NFTs to remove from mint quantity
    function _removePreMint(address _sender, uint96 _quantity) private {
        PreMintDataSet storage set = _pendingPreMints;
        uint256 idx = set.indexes[_sender];
        // user exists in set
        if (idx != 0) {
            uint96 currQuantity = set.preMintDataArr[idx - 1].quantity;
            uint96 newQuantity = (currQuantity > _quantity) ? currQuantity - _quantity : 0;
            // remove from set
            if (newQuantity == 0) {
                uint256 toDeleteIdx = idx - 1;
                uint256 lastIdx = set.preMintDataArr.length - 1;
                if (toDeleteIdx != lastIdx) {
                    PreMintData memory lastPreMintData = set.preMintDataArr[lastIdx];
                    set.preMintDataArr[toDeleteIdx] = lastPreMintData;
                    set.indexes[lastPreMintData.sender] = idx;
                }
                set.preMintDataArr.pop();
                delete set.indexes[_sender];
            } else {
                set.preMintDataArr[idx - 1].quantity = newQuantity;
            }
        }
    }

    /// @notice Mints NFTs to the sender
    /// @param _sender address to mint NFTs to
    /// @param _amount The amount of tokens to mint
    function _batchMint(address _sender, uint256 _amount) private {
        amountMintedOnThisChain += _amount;
        amountMintedByAddress[_sender] += _amount;
        totalSupply += _amount;
        uint256 _startMintId = startMintId;
        for (uint256 i; i < _amount; i++) {
            _safeMint(_sender, _startMintId + i, "");
        }
        startMintId = _startMintId + _amount;
    }

    function _creditTo(uint16, address _toAddress, uint256 _tokenId) internal virtual override {
        totalSupply += 1;
        super._creditTo(0, _toAddress, _tokenId);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint256 _tokenId) internal virtual override {
        totalSupply -= 1;
        super._debitFrom(_from, 0, "", _tokenId);
    }

    // * Operator Filter Registry functions */

    /// @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
    /// address, checks will be bypassed. OnlyOwner
    /// @param _newRegistry The address of the new OperatorFilterRegistry
    function updateOperatorFilterRegistryAddress(IOperatorFilterRegistry _newRegistry) external onlyOwner {
        _updateOperatorFilterRegistryAddress(_newRegistry);
    }

    /// @dev Update the address that the contract will make OperatorFilter checks against. When set to the zero
    /// address, checks will be bypassed.
    /// @param _newRegistry The address of the new OperatorFilterRegistry
    function _updateOperatorFilterRegistryAddress(IOperatorFilterRegistry _newRegistry) private {
        operatorFilterRegistry = _newRegistry;
        emit OperatorFilterRegistryUpdated(_newRegistry);
    }

    /// @dev `setApprovalForAll` wrapper to prevent the sender to approve a non-allowed operator
    /// @param operator Address being approved
    /// @param approved Whether the operator is approved or not
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev `aprove` wrapper to prevent the sender to approve a non-allowed operator
    /// @param operator Address being approved
    /// @param tokenId TokenID approved
    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /// @dev `transferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    /// @param data Data to send along with a safe transfer check
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);

    address internal immutable vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IBaseLaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of BaseLaunchpeg
interface IBatchReveal {
    error BatchReveal__InvalidBatchRevealSize();
    error BatchReveal__HasBeenForceRevealed();

    function revealBatchSize() external view returns (uint256);

    function batchToSeed(uint256) external view returns (uint256);

    function lastTokenRevealed() external view returns (uint256);

    function revealStartTime() external view returns (uint256);

    function revealInterval() external view returns (uint256);

    function useVRF() external view returns (bool);

    function subscriptionId() external view returns (uint64);

    function keyHash() external view returns (bytes32);

    function callbackGasLimit() external view returns (uint32);

    function requestConfirmations() external view returns (uint16);

    function nextBatchToReveal() external view returns (uint256);

    function hasBeenForceRevealed() external view returns (bool);

    function vrfRequestedForBatch(uint256) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDescriptor {
    error Descriptor__InvalidBatchRevealSetup();
    error Descriptor__RevealNextBatchNotAvailable();
    error Descriptor__InvalidCoordinator();
    error Descriptor__InvalidCallbackGasLimit();
    error Descriptor__InvalidKeyHash();
    error Descriptor__IsNotInTheConsumerList();
    error Descriptor__InvalidChain();
    error Descriptor__InvalidTokenToReveal();

    function tokenURI(uint256 tokenID) external view returns (string memory);

    function unrevealedURI() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function revealNextBatch() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDownbadDonkeys {
    enum Phase {
        NotStarted,
        DutchAuction,
        PreMint,
        Allowlist,
        PublicSale,
        Ended
    }

    /// @dev Structure for pre-mint data
    struct PreMintData {
        // address to mint NFTs to
        address sender;
        // No. of NFTs to mint
        uint96 quantity;
    }

    /// @dev Structure for a set of pre-mint data.
    struct PreMintDataSet {
        // pre-mint data array
        PreMintData[] preMintDataArr;
        // maps a user address to the index of the user's pre-mint data in the
        // `preMintDataArr` array. Plus 1 because index 0 means data does not
        // exist for that user.
        mapping(address => uint256) indexes;
    }

    /// @notice Collection data to initialize DownbadDonkeys
    /// @dev used for compatibility with LaunchpegFactory
    /// @param name ERC721 name
    /// @param symbol ERC721 symbol
    /// @param maxPerAddressDuringMint Max amount of NFTs an address can mint in public phases
    /// @param collectionSize The collection size (e.g 10000)
    /// @param amountForDevs Amount of NFTs reserved for `projectOwner` (e.g 200)
    /// @param amountForAuction Amount of NFTs available for the auction (e.g 8000)
    /// @param amountForAllowlist Amount of NFTs available for the allowlist mint (e.g 1000)
    struct CollectionData {
        string name;
        string symbol;
        address batchReveal;
        uint256 maxPerAddressDuringMint;
        uint256 collectionSize;
        uint256 amountForDevs;
        uint256 amountForAuction;
        uint256 amountForAllowlist;
    }

    /// @notice Collection owner data to initialize DownbadDonkeys
    /// @dev used for compatibility with LaunchpegFactory
    /// @param owner The contract owner
    /// @param projectOwner The project owner
    /// @param royaltyReceiver Royalty fee collector
    /// @param joeFeeCollector The address to which the fees on the sale will be sent
    /// @param joeFeePercent The fees collected by the fee collector on the sale benefits
    struct CollectionOwnerData {
        address owner;
        address projectOwner;
        address royaltyReceiver;
        address joeFeeCollector;
        uint256 joeFeePercent;
    }

    error DownbadDonkeys__InvalidRoyaltyInfo();
    error DownbadDonkeys__WrongPhase();
    error DownbadDonkeys__InvalidQuantity();
    error DownbadDonkeys__NotEligibleForPreMint();
    error DownbadDonkeys__MaxSupplyReached();
    error DownbadDonkeys__NotEnoughNative(uint256 value);
    error DownbadDonkeys__TransferFailed();
    error DownbadDonkeys__InvalidAllowlistPrice();
    error DownbadDonkeys__InvalidPhases();
    error DownbadDonkeys__ZeroAddress();
    error DownbadDonkeys__InvalidTokenId();
    error DownbadDonkeys__InvalidMintIdSetup();
    error DownbadDonkeys__MaxSupplyForDevReached();
    error DownbadDonkeys__WrongAddressesAndNumSlotsLength();
    error DownbadDonkeys__InvalidClaim();
    error DownbadDonkeys__HasBeenForceRevealed();
    error DownbadDonkeys__InvalidBatchRevealSize();
    error DownbadDonkeys__CanNotMintThisMany();
    error DownbadDonkeys__Unauthorized();
    error DownbadDonkeys__NotInitialized();
    error DownbadDonkeys__OnlyDescriptor();
    error DownbadDonkeys__CantAddNewPhasesAnymore();
    error DownbadDonkeys__UnclaimedTokensExist();
    error OperatorNotAllowed(address operator);

    function collectionSize() external view returns (uint256);

    function amountMintedOnThisChain() external view returns (uint256);

    function startMintId() external view returns (uint256);

    function metadataBatchUpdated(uint256 _fromTokenId, uint256 _toTokenId) external;

    function metadataUpdated(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC4906 is IERC165Upgradeable, IERC721Upgradeable {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
        external
        view
        returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function __ERC721A_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721AUpgradeable.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (
            to.isContract() &&
            !_checkContractOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            updatedIndex++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);
        address from = prevOwnership.addr;
        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());
            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;
            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;
            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }
        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);
        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721ReceiverUpgradeable(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return
                retval ==
                IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "./ERC721AUpgradeable.sol";

/// @title IBaseLaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of BaseLaunchpeg
interface IBaseLaunchpeg is IERC721Upgradeable, IERC721MetadataUpgradeable {
    enum Phase {
        NotStarted,
        DutchAuction,
        PreMint,
        Allowlist,
        PublicSale,
        Ended
    }

    /// @notice Collection data to initialize Launchpeg
    /// @param name ERC721 name
    /// @param symbol ERC721 symbol
    /// @param maxPerAddressDuringMint Max amount of NFTs an address can mint in public phases
    /// @param collectionSize The collection size (e.g 10000)
    /// @param amountForDevs Amount of NFTs reserved for `projectOwner` (e.g 200)
    /// @param amountForAuction Amount of NFTs available for the auction (e.g 8000)
    /// @param amountForAllowlist Amount of NFTs available for the allowlist mint (e.g 1000)
    struct CollectionData {
        string name;
        string symbol;
        address batchReveal;
        uint256 maxPerAddressDuringMint;
        uint256 collectionSize;
        uint256 amountForDevs;
        uint256 amountForAuction;
        uint256 amountForAllowlist;
    }

    /// @notice Collection owner data to initialize Launchpeg
    /// @param owner The contract owner
    /// @param projectOwner The project owner
    /// @param royaltyReceiver Royalty fee collector
    /// @param joeFeeCollector The address to which the fees on the sale will be sent
    /// @param joeFeePercent The fees collected by the fee collector on the sale benefits
    struct CollectionOwnerData {
        address owner;
        address projectOwner;
        address royaltyReceiver;
        address joeFeeCollector;
        uint256 joeFeePercent;
    }

    function PROJECT_OWNER_ROLE() external pure returns (bytes32);

    function collectionSize() external view returns (uint256);

    function unrevealedURI() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function amountForDevs() external view returns (uint256);

    function amountForAllowlist() external view returns (uint256);

    function maxPerAddressDuringMint() external view returns (uint256);

    function joeFeePercent() external view returns (uint256);

    function joeFeeCollector() external view returns (address);

    function allowlist(address) external view returns (uint256);

    function amountMintedByDevs() external view returns (uint256);

    function amountMintedDuringPreMint() external view returns (uint256);

    function amountClaimedDuringPreMint() external view returns (uint256);

    function amountMintedDuringAllowlist() external view returns (uint256);

    function amountMintedDuringPublicSale() external view returns (uint256);

    function preMintStartTime() external view returns (uint256);

    function allowlistStartTime() external view returns (uint256);

    function publicSaleStartTime() external view returns (uint256);

    function publicSaleEndTime() external view returns (uint256);

    function withdrawAVAXStartTime() external view returns (uint256);

    function allowlistPrice() external view returns (uint256);

    function salePrice() external view returns (uint256);

    function initializeBatchReveal(address _batchReveal) external;

    function setRoyaltyInfo(address receiver, uint96 feePercent) external;

    function seedAllowlist(
        address[] memory _addresses,
        uint256[] memory _numSlots
    ) external;

    function setBaseURI(string calldata baseURI) external;

    function setUnrevealedURI(string calldata baseURI) external;

    function setPreMintStartTime(uint256 _preMintStartTime) external;

    function setAllowlistStartTime(uint256 _allowlistStartTime) external;

    function setPublicSaleStartTime(uint256 _publicSaleStartTime) external;

    function setPublicSaleEndTime(uint256 _publicSaleEndTime) external;

    function setWithdrawAVAXStartTime(uint256 _withdrawAVAXStartTime) external;

    function devMint(uint256 quantity) external;

    function preMint(uint96 _quantity) external payable;

    function claimPreMint() external;

    function batchClaimPreMint(uint96 _maxQuantity) external;

    function allowlistMint(uint256 _quantity) external payable;

    function publicSaleMint(uint256 _quantity) external payable;

    function withdrawAVAX(address to) external;

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (ERC721AUpgradeable.TokenOwnership memory);

    function userPendingPreMints(address owner) external view returns (uint256);

    function numberMinted(address owner) external view returns (uint256);

    function numberMintedWithPreMint(address _owner)
        external
        view
        returns (uint256);

    function currentPhase() external view returns (Phase);

    function revealNextBatch() external;

    function hasBatchToReveal() external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IBaseLaunchpegV1
/// @author Trader Joe
/// @notice Defines the legacy methods in Launchpeg V1 contracts
interface IBaseLaunchpegV1 {
    /** IBaseLaunchpeg */
    function projectOwner() external view returns (address);

    /** ILaunchpeg */
    function getAllowlistPrice() external view returns (uint256);

    function getPublicSalePrice() external view returns (uint256);

    /** IBatchReveal */
    function revealBatchSize() external view returns (uint256);

    function lastTokenRevealed() external view returns (uint256);

    function revealStartTime() external view returns (uint256);

    function revealInterval() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IBatchReveal
/// @author Trader Joe
/// @notice Defines the basic interface of BatchReveal
interface IBatchRevealv2 {
    struct BatchRevealConfig {
        uint256 collectionSize;
        int128 intCollectionSize;
        /// @notice Size of the batch reveal
        /// @dev Must divide collectionSize
        uint256 revealBatchSize;
        /// @notice Timestamp for the start of the reveal process
        /// @dev Can be set to zero for immediate reveal after token mint
        uint256 revealStartTime;
        /// @notice Time interval for gradual reveal
        /// @dev Can be set to zero in order to reveal the collection all at once
        uint256 revealInterval;
    }

    function initialize() external;

    function configure(
        address _baseLaunchpeg,
        uint256 _revealBatchSize,
        uint256 _revealStartTime,
        uint256 _revealInterval
    ) external;

    function setRevealBatchSize(
        address _baseLaunchpeg,
        uint256 _revealBatchSize
    ) external;

    function setRevealStartTime(
        address _baseLaunchpeg,
        uint256 _revealStartTime
    ) external;

    function setRevealInterval(address _baseLaunchpeg, uint256 _revealInterval)
        external;

    function setVRF(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) external;

    function launchpegToConfig(address)
        external
        view
        returns (
            uint256,
            int128,
            uint256,
            uint256,
            uint256
        );

    function launchpegToBatchToSeed(address, uint256)
        external
        view
        returns (uint256);

    function launchpegToLastTokenReveal(address)
        external
        view
        returns (uint256);

    function useVRF() external view returns (bool);

    function subscriptionId() external view returns (uint64);

    function keyHash() external view returns (bytes32);

    function callbackGasLimit() external view returns (uint32);

    function requestConfirmations() external view returns (uint16);

    function launchpegToNextBatchToReveal(address)
        external
        view
        returns (uint256);

    function launchpegToHasBeenForceRevealed(address)
        external
        view
        returns (bool);

    function launchpegToVrfRequestedForBatch(address, uint256)
        external
        view
        returns (bool);

    function getShuffledTokenId(address _baseLaunchpeg, uint256 _startId)
        external
        view
        returns (uint256);

    function isBatchRevealInitialized(address _baseLaunchpeg)
        external
        view
        returns (bool);

    function revealNextBatch(address _baseLaunchpeg, uint256 _totalSupply)
        external
        returns (bool);

    function hasBatchToReveal(address _baseLaunchpeg, uint256 _totalSupply)
        external
        view
        returns (bool, uint256);

    function forceReveal(address _baseLaunchpeg) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBaseLaunchpeg.sol";

/// @title ILaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of FlatLaunchpeg
interface IFlatLaunchpeg is IBaseLaunchpeg {
    function initialize(
        CollectionData calldata _collectionData,
        CollectionOwnerData calldata _ownerData
    ) external;

    function initializePhases(
        uint256 _preMintStartTime,
        uint256 _allowlistStartTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _allowlistPrice,
        uint256 _salePrice
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBaseLaunchpeg.sol";

/// @title ILaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of Launchpeg
interface ILaunchpeg is IBaseLaunchpeg {
    function amountForAuction() external view returns (uint256);

    function auctionSaleStartTime() external view returns (uint256);

    function auctionStartPrice() external view returns (uint256);

    function auctionEndPrice() external view returns (uint256);

    function auctionSaleDuration() external view returns (uint256);

    function auctionDropInterval() external view returns (uint256);

    function auctionDropPerStep() external view returns (uint256);

    function allowlistDiscountPercent() external view returns (uint256);

    function publicSaleDiscountPercent() external view returns (uint256);

    function amountMintedDuringAuction() external view returns (uint256);

    function lastAuctionPrice() external view returns (uint256);

    function getAuctionPrice(uint256 _saleStartTime)
        external
        view
        returns (uint256);

    function initialize(
        CollectionData calldata _collectionData,
        CollectionOwnerData calldata _ownerData
    ) external;

    function initializePhases(
        uint256 _auctionSaleStartTime,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionDropInterval,
        uint256 _preMintStartTime,
        uint256 _allowlistStartTime,
        uint256 _allowlistDiscountPercent,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSaleDiscountPercent
    ) external;

    function setAuctionSaleStartTime(uint256 _auctionSaleStartTime) external;

    function auctionMint(uint256 _quantity) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ILaunchpegFactory
/// @author Trader Joe
/// @notice Defines the basic interface of LaunchpegFactory
interface ILaunchpegFactory {
    function LAUNCHPEG_PAUSER_ROLE() external pure returns (bytes32);

    function launchpegImplementation() external view returns (address);

    function flatLaunchpegImplementation() external view returns (address);

    function batchReveal() external view returns (address);

    function joeFeePercent() external view returns (uint256);

    function joeFeeCollector() external view returns (address);

    function isLaunchpeg(uint256 _type, address _contract)
        external
        view
        returns (bool);

    function allLaunchpegs(uint256 _launchpegType, uint256 _launchpegID)
        external
        view
        returns (address);

    function numLaunchpegs(uint256 _launchpegType)
        external
        view
        returns (uint256);

    function createLaunchpeg(
        string memory _name,
        string memory _symbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint256 _maxPerAddressDuringMint,
        uint256 _collectionSize,
        uint256 _amountForAuction,
        uint256 _amountForAllowlist,
        uint256 _amountForDevs,
        bool _enableBatchReveal
    ) external returns (address);

    function createFlatLaunchpeg(
        string memory _name,
        string memory _symbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint256 _maxPerAddressDuringMint,
        uint256 _collectionSize,
        uint256 _amountForDevs,
        uint256 _amountForAllowlist,
        bool _enableBatchReveal
    ) external returns (address);

    function setLaunchpegImplementation(address _launchpegImplementation)
        external;

    function setFlatLaunchpegImplementation(
        address _flatLaunchpegImplementation
    ) external;

    function setBatchReveal(address _batchReveal) external;

    function setDefaultJoeFeePercent(uint256 _joeFeePercent) external;

    function setDefaultJoeFeeCollector(address _joeFeeCollector) external;

    function addLaunchpegPauser(address _pauser) external;

    function removeLaunchpegPauser(address _pauser) external;

    function pauseLaunchpeg(address _launchpeg) external;

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPendingOwnableUpgradeable {
    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import "./IPendingOwnableUpgradeable.sol";

interface ISafePausableUpgradeable is IAccessControlEnumerableUpgradeable, IPendingOwnableUpgradeable {
    function PAUSER_ROLE() external pure returns (bytes32);

    function UNPAUSER_ROLE() external pure returns (bytes32);

    function PAUSER_ADMIN_ROLE() external pure returns (bytes32);

    function UNPAUSER_ADMIN_ROLE() external pure returns (bytes32);

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_provingKeyHashes list of registered key hashes
     */
    function getRequestConfig()
        external
        view
        returns (
            uint16,
            uint32,
            bytes32[] memory
        );

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId)
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "test/TestHelper.t.sol";

contract TestSetup is TestHelper {
    uint256 amountForDevs = 5;
    uint256 amountForAllowlist = 5;
    uint256 startMintId = 0;
    uint256 endMintId = 15;

    function setUp() public {
        DownbadDonkeys downbadDonkeysImplementation = new DownbadDonkeys();
        address downbadDonkeysAddress = Clones.clone(address(downbadDonkeysImplementation));

        downbadDonkeys = DownbadDonkeys(downbadDonkeysAddress);
        downbadDonkeys.initialize(collectionData, collectionOwnerData);
    }

    function testInitialization() public {
        assertEq(downbadDonkeys.name(), name);
        assertEq(downbadDonkeys.symbol(), symbol);
        assertEq(address(downbadDonkeys.lzEndpoint()), address(0));
    }

    function testSettingLZEndpoint() public {
        downbadDonkeys.setLZEndpoint(lzEndpoint);
        assertEq(address(downbadDonkeys.lzEndpoint()), lzEndpoint);
    }

    function teststartNewPhasesReverts() public {
        vm.prank(ALICE);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );

        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.startNewPhases(
            block.timestamp - 1,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp - 1,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration - 1,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidAllowlistPrice.selector);
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price + 1,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
    }

    function teststartNewPhases() public {
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
        assertEq(downbadDonkeys.preMintStartTime(), block.timestamp);
        assertEq(downbadDonkeys.publicSaleStartTime(), block.timestamp + premintPhaseDuration);
        assertEq(downbadDonkeys.publicSaleEndTime(), block.timestamp + premintPhaseDuration + publicPhaseDuration);
        assertEq(downbadDonkeys.allowlistPrice(), price);
        assertEq(downbadDonkeys.salePrice(), price);

        assertEq(downbadDonkeys.amountForDevs(), amountForDevs);
        assertEq(downbadDonkeys.amountForAllowlist(), amountForAllowlist);
        assertEq(downbadDonkeys.maxPerAddressDuringMint(), maxPerAddressDuringMint);
        assertEq(downbadDonkeys.startMintId(), startMintId);
        assertEq(downbadDonkeys.endMintId(), endMintId);
    }

    function testPhases() public {
        downbadDonkeys.startNewPhases(
            block.timestamp + 1,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
        assertEq(uint256(downbadDonkeys.currentPhase()), uint256(IDownbadDonkeys.Phase.NotStarted));
        vm.warp(block.timestamp + 1);
        assertEq(uint256(downbadDonkeys.currentPhase()), uint256(IDownbadDonkeys.Phase.PreMint));
        vm.warp(block.timestamp + premintPhaseDuration);
        assertEq(uint256(downbadDonkeys.currentPhase()), uint256(IDownbadDonkeys.Phase.PublicSale));
        vm.warp(block.timestamp + premintPhaseDuration + publicPhaseDuration);
        assertEq(uint256(downbadDonkeys.currentPhase()), uint256(IDownbadDonkeys.Phase.Ended));
    }

    function testSetTimesOnlyOwner() public {
        downbadDonkeys.startNewPhases(
            block.timestamp + 1,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
        vm.startPrank(ALICE);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        downbadDonkeys.setPreMintStartTime(block.timestamp + 2);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        downbadDonkeys.setPublicSaleStartTime(block.timestamp + premintPhaseDuration + 1);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        downbadDonkeys.setPublicSaleEndTime(block.timestamp + premintPhaseDuration + publicPhaseDuration + 1);
        vm.stopPrank();
    }

    function testSetTimes() public {
        downbadDonkeys.startNewPhases(
            block.timestamp + 1,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );

        downbadDonkeys.setPreMintStartTime(block.timestamp + 2);
        assertEq(downbadDonkeys.preMintStartTime(), block.timestamp + 2);
        downbadDonkeys.setPublicSaleStartTime(block.timestamp + premintPhaseDuration + 1);
        assertEq(downbadDonkeys.publicSaleStartTime(), block.timestamp + premintPhaseDuration + 1);
        downbadDonkeys.setPublicSaleEndTime(block.timestamp + premintPhaseDuration + publicPhaseDuration + 1);
        assertEq(downbadDonkeys.publicSaleEndTime(), block.timestamp + premintPhaseDuration + publicPhaseDuration + 1);
    }

    function testSetTimeBeforeInitializationReverts() public {
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__NotInitialized.selector);
        downbadDonkeys.setPreMintStartTime(block.timestamp);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__NotInitialized.selector);
        downbadDonkeys.setPublicSaleStartTime(block.timestamp);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__NotInitialized.selector);
        downbadDonkeys.setPublicSaleEndTime(block.timestamp);
    }

    function testSetTimeBeforeCurrentTimeReverts() public {
        downbadDonkeys.startNewPhases(
            block.timestamp + 1,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.setPreMintStartTime(block.timestamp - 1);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.setPublicSaleStartTime(block.timestamp - 1);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.setPublicSaleEndTime(block.timestamp - 1);
    }

    function testSetTimeDuringAnotherPhaseReverts() public {
        downbadDonkeys.startNewPhases(
            block.timestamp + 1,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevs,
            amountForAllowlist,
            maxPerAddressDuringMint,
            startMintId,
            endMintId
        );
        // Can't set times to start later than next phase
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.setPreMintStartTime(block.timestamp + premintPhaseDuration + 1);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.setPublicSaleStartTime(block.timestamp + premintPhaseDuration + publicPhaseDuration + 1);

        // Can't set times to start earlier than previous phase
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.setPublicSaleEndTime(block.timestamp + premintPhaseDuration - 1);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.setPublicSaleStartTime(block.timestamp);
    }

    function testSetDescriptor() public {
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__ZeroAddress.selector);
        downbadDonkeys.setDescriptor(address(0));

        downbadDonkeys.setDescriptor(makeAddr("descriptor"));
        assertEq(address(downbadDonkeys.descriptor()), makeAddr("descriptor"));
    }

    function testRoyalty() public {
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidRoyaltyInfo.selector);
        downbadDonkeys.setRoyaltyInfo(ALICE, 2501);

        downbadDonkeys.setRoyaltyInfo(ALICE, 500);

        (address receiver, uint256 royalty) = downbadDonkeys.royaltyInfo(1, 10000);
        assertEq(royalty, 500);
        assertEq(receiver, ALICE);
    }

    function testPaused() public {
        downbadDonkeys.pause();
        address owner = downbadDonkeys.owner();
        assertEq(downbadDonkeys.paused(), true);

        vm.startPrank(owner, owner);
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        downbadDonkeys.preMint(1);
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        downbadDonkeys.publicSaleMint(1);
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        downbadDonkeys.claimPreMint();
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        downbadDonkeys.batchClaimPreMint(1);
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        downbadDonkeys.devMint(1);
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        downbadDonkeys.withdrawNative(ALICE);

        downbadDonkeys.unpause();
        assertEq(downbadDonkeys.paused(), false);
    }

    function testSupportsInterface() public {
        assertTrue(downbadDonkeys.supportsInterface(type(IERC165Upgradeable).interfaceId));

        assertTrue(downbadDonkeys.supportsInterface(type(IERC2981Upgradeable).interfaceId));

        assertTrue(downbadDonkeys.supportsInterface(type(IERC721Upgradeable).interfaceId));

        assertTrue(downbadDonkeys.supportsInterface(type(IONFT721Upgradeable).interfaceId));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "test/TestHelper.t.sol";
import "./mocks/VRFCoordinatorV2Mock.sol";

contract DescriptorTests is TestHelper {
    VRFCoordinatorV2Mock public vrfCoordinator;
    bytes32 public keyhash = bytes32(keccak256("keyhash"));

    function setUp() public {
        vrfCoordinator = new VRFCoordinatorV2Mock(1, 1);
        collectionData = IDownbadDonkeys.CollectionData(
            name,
            symbol,
            address(0),
            maxPerAddressDuringMint,
            collectionSize,
            amountForDevsChainA,
            0,
            amountForPremintChainA
        );
        DownbadDonkeys downbadDonkeysImplementation = new DownbadDonkeys();
        address downbadDonkeysAddress = Clones.clone(address(downbadDonkeysImplementation));

        downbadDonkeys = DownbadDonkeys(downbadDonkeysAddress);
        downbadDonkeys.initialize(collectionData, collectionOwnerData);
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            0.1 ether,
            0.1 ether,
            10000,
            0,
            maxPerAddressDuringMint,
            0,
            9999
        );
        descriptor = new Descriptor(
            address(downbadDonkeys),
            batchRevealSize,
            collectionSize,
            address(vrfCoordinator),
            true
        );
        downbadDonkeys.setDescriptor(address(descriptor));
        descriptor.setBaseURI(baseURI);
        descriptor.setUnrevealedURI(unrevealedURI);

        DownbadDonkeys downbadDonkeysImplementation2 = new DownbadDonkeys();
        address downbadDonkeysAddress2 = Clones.clone(address(downbadDonkeysImplementation2));

        downbadDonkeysSecondChain = DownbadDonkeys(downbadDonkeysAddress2);

        downbadDonkeysSecondChain.initialize(collectionData, collectionOwnerData);

        downbadDonkeysSecondChain.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            0.1 ether,
            0.1 ether,
            10000,
            0,
            maxPerAddressDuringMint,
            0,
            9999
        );
        descriptorSecondChain = new Descriptor(
            address(downbadDonkeysSecondChain),
            batchRevealSize,
            collectionSize,
            address(vrfCoordinator),
            false
        );
        downbadDonkeysSecondChain.setDescriptor(address(descriptorSecondChain));
        descriptorSecondChain.setBaseURI(baseURI);
        descriptorSecondChain.setUnrevealedURI(unrevealedURI);

        uint64 subId = vrfCoordinator.createSubscription();
        vrfCoordinator.addConsumer(subId, address(descriptor));
        vrfCoordinator.fundSubscription(subId, 1e18);
        descriptor.setVRF(keyhash, subId, 2000000);
        descriptor.setRevealStartTime(block.timestamp + 100);
    }

    function testRandomness() public {
        downbadDonkeys.devMint(downbadDonkeys.collectionSize());
        downbadDonkeysSecondChain.devMint(downbadDonkeysSecondChain.collectionSize());
        // not enough time passed
        vm.expectRevert(IDescriptor.Descriptor__RevealNextBatchNotAvailable.selector);
        downbadDonkeys.revealNextBatch();

        assertEq(downbadDonkeys.tokenURI(0), unrevealedURI);
        assertEq(downbadDonkeys.tokenURI(9999), unrevealedURI);
        assertEq(downbadDonkeysSecondChain.tokenURI(0), unrevealedURI);
        assertEq(downbadDonkeysSecondChain.tokenURI(9999), unrevealedURI);

        vm.warp(block.timestamp + 100);
        for (uint256 i = 0; i < 10;) {
            downbadDonkeys.revealNextBatch();
            vrfCoordinator.fulfillRandomWords(++i, address(descriptor));
        }

        assertFalse(compareStrings(downbadDonkeys.tokenURI(0), unrevealedURI));
        assertFalse(compareStrings(downbadDonkeys.tokenURI(9999), unrevealedURI));

        assertEq(downbadDonkeysSecondChain.tokenURI(0), unrevealedURI);
        assertEq(downbadDonkeysSecondChain.tokenURI(9999), unrevealedURI);

        uint256[] memory seeds = descriptor.getRandomSeeds();
        assertEq(seeds.length, 10);

        descriptorSecondChain.seedRandomSeeds(seeds);

        uint256 batchesAmount = downbadDonkeys.collectionSize() / batchRevealSize;
        for (uint256 j; j < batchesAmount; j++) {
            assertEq(
                downbadDonkeys.tokenURI(j * batchRevealSize), downbadDonkeysSecondChain.tokenURI(j * batchRevealSize)
            );

            assertEq(
                downbadDonkeys.tokenURI(j * batchRevealSize + 33),
                downbadDonkeysSecondChain.tokenURI(j * batchRevealSize + 33)
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "test/TestHelper.t.sol";
import "./mocks/VRFCoordinatorV2Mock.sol";

contract DescriptorTests is TestHelper {
    VRFCoordinatorV2Mock public vrfCoordinator;
    bytes32 public keyhash = bytes32(keccak256("keyhash"));
    uint64 public subId;

    function setUp() public {
        vrfCoordinator = new VRFCoordinatorV2Mock(1, 1);
        DownbadDonkeys downbadDonkeysImplementation = new DownbadDonkeys();
        address downbadDonkeysAddress = Clones.clone(address(downbadDonkeysImplementation));

        downbadDonkeys = DownbadDonkeys(downbadDonkeysAddress);
        downbadDonkeys.initialize(collectionData, collectionOwnerData);
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            0.1 ether,
            0.1 ether,
            10000,
            0,
            maxPerAddressDuringMint,
            0,
            9999
        );
        descriptor = new Descriptor(
            address(downbadDonkeys),
            batchRevealSize,
            collectionSize,
            address(vrfCoordinator),
            true
        );
        DownbadDonkeys downbadDonkeysImplementation2 = new DownbadDonkeys();
        address downbadDonkeysAddress2 = Clones.clone(address(downbadDonkeysImplementation2));

        downbadDonkeysSecondChain = DownbadDonkeys(downbadDonkeysAddress2);

        downbadDonkeysSecondChain.initialize(collectionData, collectionOwnerData);
        downbadDonkeysSecondChain.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            0.1 ether,
            0.1 ether,
            10000,
            0,
            maxPerAddressDuringMint,
            0,
            9999
        );
        descriptorSecondChain = new Descriptor(
            address(downbadDonkeysSecondChain),
            batchRevealSize,
            collectionSize,
            address(vrfCoordinator),
            false
        );
        downbadDonkeysSecondChain.setDescriptor(address(descriptorSecondChain));
        descriptorSecondChain.setBaseURI(baseURI);
        descriptorSecondChain.setUnrevealedURI(unrevealedURI);

        downbadDonkeys.setDescriptor(address(descriptor));
        subId = vrfCoordinator.createSubscription();
        vrfCoordinator.addConsumer(subId, address(descriptor));
        vrfCoordinator.fundSubscription(subId, 1e18);
        descriptor.setVRF(keyhash, subId, 2000000);
        descriptor.setRevealStartTime(block.timestamp + 100);
    }

    function testSetTime() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(ALICE);
        descriptor.setRevealStartTime(block.timestamp + 33);

        descriptor.setRevealStartTime(block.timestamp + 33);
        assertEq(descriptor.revealStartTime(), block.timestamp + 33);
    }

    function testSettingUri() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(ALICE);
        descriptor.setBaseURI(baseURI);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(ALICE);
        descriptor.setUnrevealedURI(unrevealedURI);

        descriptor.setBaseURI(baseURI);

        vm.expectEmit(true, true, true, true);
        emit BatchMetadataUpdate(0, 9999);

        descriptor.setUnrevealedURI(unrevealedURI);
        assertEq(descriptor.baseURI(), baseURI);
        assertEq(descriptor.unrevealedURI(), unrevealedURI);
    }

    function testSettingRandomnessInvalidChainReverts() public {
        uint256[] memory randomSeeds = new uint256[](1);

        vm.expectRevert(IDescriptor.Descriptor__InvalidChain.selector);
        descriptor.seedRandomSeeds(randomSeeds);

        vm.expectRevert(IDescriptor.Descriptor__InvalidChain.selector);
        descriptorSecondChain.setLastTokenMintedForReveal(100);

        vm.expectRevert(IDescriptor.Descriptor__InvalidChain.selector);
        descriptorSecondChain.revealNextBatch();

        vm.expectRevert(IDescriptor.Descriptor__InvalidChain.selector);
        descriptorSecondChain.setVRF(keyhash, subId, 2000000);
    }

    function testSetVRF() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(ALICE);
        descriptor.setVRF(keyhash, subId, 2000000);

        vm.expectRevert(IDescriptor.Descriptor__InvalidCallbackGasLimit.selector);
        descriptor.setVRF(keyhash, subId, 0);

        vm.expectRevert(IDescriptor.Descriptor__InvalidKeyHash.selector);
        descriptor.setVRF(bytes32(keccak256("wrongKeyhash")), subId, 2000000);

        uint64 wrongSubId = vrfCoordinator.createSubscription();
        vm.expectRevert(IDescriptor.Descriptor__IsNotInTheConsumerList.selector);
        descriptor.setVRF(keyhash, wrongSubId, 2000000);

        descriptor.setVRF(keyhash, subId, 2000000);

        assertEq(descriptor.keyHash(), keyhash);
        assertEq(descriptor.subscriptionId(), 1);
        assertEq(descriptor.callbackGasLimit(), 2000000);
    }

    function testRevealing() public {
        vm.warp(block.timestamp + 100);
        descriptor.setVRF(keyhash, subId, 2000000);
        vm.expectRevert(IDescriptor.Descriptor__RevealNextBatchNotAvailable.selector);
        downbadDonkeys.revealNextBatch();

        downbadDonkeys.devMint(1000);

        vm.expectEmit(true, true, true, true);
        emit BatchMetadataUpdate(0, 999);
        downbadDonkeys.revealNextBatch();
        vrfCoordinator.fulfillRandomWords(1, address(descriptor));

        vm.expectRevert(IDescriptor.Descriptor__RevealNextBatchNotAvailable.selector);
        downbadDonkeys.revealNextBatch();

        vm.expectRevert(IDescriptor.Descriptor__InvalidTokenToReveal.selector);
        descriptor.setLastTokenMintedForReveal(collectionSize + 1);

        descriptor.setLastTokenMintedForReveal(collectionSize);
        for (uint256 i = 1; i < 10;) {
            vm.expectEmit(true, true, true, true);
            emit BatchMetadataUpdate(batchRevealSize * i, batchRevealSize * (i + 1) - 1);
            downbadDonkeys.revealNextBatch();
            vrfCoordinator.fulfillRandomWords(++i, address(descriptor));
        }

        vm.expectEmit(true, true, true, true);
        emit BatchMetadataUpdate(0, downbadDonkeys.collectionSize() - 1);
        descriptor.setBaseURI(unrevealedURI);
    }

    function testSingleUpdate() public {
        vm.prank(address(descriptor));
        vm.expectEmit(true, true, true, true);
        emit MetadataUpdate(1);
        downbadDonkeys.metadataUpdated(1);
    }

    function testOnlyDescriptor() public {
        vm.startPrank(ALICE);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__OnlyDescriptor.selector);
        downbadDonkeys.metadataUpdated(1);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__OnlyDescriptor.selector);
        downbadDonkeys.metadataBatchUpdated(1, 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "test/TestHelper.t.sol";

import "./mocks/LZEndpointMock.sol";

contract IntegrationTest is TestHelper {
    uint16 chainId_A = 1;
    uint16 chainId_B = 2;
    DownbadDonkeys downbadDonkeysA;
    DownbadDonkeys downbadDonkeysB;
    LZEndpointMock lzEndpointMockA;
    LZEndpointMock lzEndpointMockB;
    uint256 batchSizeLimit = 300;
    bytes defaultAdapterParams;

    IDownbadDonkeys.CollectionOwnerData collectionOwnerDataA;
    IDownbadDonkeys.CollectionOwnerData collectionOwnerDataB;

    function setUp() public {
        lzEndpointMockA = new LZEndpointMock(chainId_A);
        lzEndpointMockB = new LZEndpointMock(chainId_B);

        collectionOwnerDataA = IDownbadDonkeys.CollectionOwnerData(DEV, address(0), DEV, address(0), 0);
        collectionOwnerDataB = IDownbadDonkeys.CollectionOwnerData(DEV, address(0), DEV, address(0), 0);

        DownbadDonkeys downbadDonkeysImplementation = new DownbadDonkeys();
        address downbadDonkeysAddress = Clones.clone(address(downbadDonkeysImplementation));

        downbadDonkeysA = DownbadDonkeys(downbadDonkeysAddress);

        downbadDonkeysA.initialize(collectionData, collectionOwnerDataA);
        downbadDonkeysA.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            0.1 ether,
            0.1 ether,
            5000,
            0,
            maxPerAddressDuringMint,
            0,
            4999
        );
        downbadDonkeysA.setLZEndpoint(address(lzEndpointMockA));

        DownbadDonkeys downbadDonkeysImplementationB = new DownbadDonkeys();
        address downbadDonkeysAddressB = Clones.clone(address(downbadDonkeysImplementationB));

        downbadDonkeysB = DownbadDonkeys(downbadDonkeysAddressB);
        downbadDonkeysB.initialize(collectionData, collectionOwnerDataB);
        downbadDonkeysB.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            0.1 ether,
            0.1 ether,
            5000,
            0,
            maxPerAddressDuringMint,
            5000,
            9999
        );
        downbadDonkeysB.setLZEndpoint(address(lzEndpointMockB));

        lzEndpointMockA.setDestLzEndpoint(address(downbadDonkeysB), address(lzEndpointMockB));
        lzEndpointMockB.setDestLzEndpoint(address(downbadDonkeysA), address(lzEndpointMockA));

        // set each contracts source address so it can send to each other
        downbadDonkeysA.setTrustedRemote(
            chainId_B, abi.encodePacked(address(downbadDonkeysB), address(downbadDonkeysA))
        );
        downbadDonkeysB.setTrustedRemote(
            chainId_A, abi.encodePacked(address(downbadDonkeysA), address(downbadDonkeysB))
        );

        vm.deal(ALICE, 10 ether);
        vm.deal(address(lzEndpointMockA), 10 ether);
        vm.deal(address(lzEndpointMockB), 10 ether);
    }

    function testSendFromYourOwnToken() public {
        uint256 tokenId = 3;
        downbadDonkeysA.devMint(10);
        address owner = downbadDonkeysA.owner();

        // verify the owner of the token is on the source chain
        assertEq(downbadDonkeysA.ownerOf(tokenId), owner);

        // token doesn't exist on other chain
        vm.expectRevert("ERC721: invalid token ID");
        downbadDonkeysB.ownerOf(tokenId);

        // can transfer token on srcChain as regular ERC721
        downbadDonkeysA.transferFrom(owner, ALICE, tokenId);
        assertEq(downbadDonkeysA.ownerOf(tokenId), ALICE);

        // approve the proxy to swap your token
        vm.startPrank(ALICE, ALICE);
        downbadDonkeysA.approve(address(downbadDonkeysA), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            downbadDonkeysA.estimateSendFee(chainId_B, abi.encodePacked(ALICE), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        downbadDonkeysA.sendFrom{value: nativeFee}(
            ALICE, chainId_B, abi.encodePacked(ALICE), tokenId, payable(ALICE), address(0), defaultAdapterParams
        );

        // token is burnt
        assertEq(downbadDonkeysA.ownerOf(tokenId), address(downbadDonkeysA));

        // token received on the dst chain
        assertEq(downbadDonkeysB.ownerOf(tokenId), ALICE);

        // estimate nativeFees
        (nativeFee,) =
            downbadDonkeysB.estimateSendFee(chainId_A, abi.encodePacked(ALICE), tokenId, false, defaultAdapterParams);

        // can send to other onft contract eg. not the original nft contract chain
        downbadDonkeysB.sendFrom{value: nativeFee}(
            ALICE, chainId_A, abi.encodePacked(ALICE), tokenId, payable(ALICE), address(0), defaultAdapterParams
        );

        // token is burned on the sending chain
        assertEq(downbadDonkeysB.ownerOf(tokenId), address(downbadDonkeysB));
    }

    function sendFromRevertsIfNotOwner() public {
        uint256 tokenId = 3;
        downbadDonkeysA.devMint(10);
        address owner = downbadDonkeysA.owner();
        // approve the proxy to swap your token
        downbadDonkeysA.approve(address(downbadDonkeysA), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            downbadDonkeysA.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        downbadDonkeysA.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(downbadDonkeysB.ownerOf(tokenId), owner);

        // reverts because other address does not own it
        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        downbadDonkeysB.sendFrom(
            ALICE, chainId_A, abi.encodePacked(ALICE), tokenId, payable(ALICE), address(0), defaultAdapterParams
        );
    }

    function testSendFromOnBehalfOfAnotherUser() public {
        uint256 tokenId = 4;
        downbadDonkeysA.devMint(10);
        address owner = downbadDonkeysA.owner();

        // approve the proxy to swap your token
        //downbadDonkeysA.approve(address(downbadDonkeysA), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            downbadDonkeysA.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        downbadDonkeysA.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(downbadDonkeysB.ownerOf(tokenId), owner);

        // approve the other user to send the token
        downbadDonkeysB.approve(address(ALICE), tokenId);

        // estimate nativeFees
        (nativeFee,) =
            downbadDonkeysB.estimateSendFee(chainId_A, abi.encodePacked(ALICE), tokenId, false, defaultAdapterParams);

        // sends across
        vm.prank(ALICE);
        downbadDonkeysB.sendFrom{value: nativeFee}(
            owner, chainId_A, abi.encodePacked(ALICE), tokenId, payable(ALICE), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(downbadDonkeysA.ownerOf(tokenId), ALICE);
    }

    function testRevertsIfContractIsApprovedButNotTheSendingUser() public {
        uint256 tokenId = 5;
        downbadDonkeysA.devMint(10);
        address owner = downbadDonkeysA.owner();

        // approve the proxy to swap your token
        downbadDonkeysA.approve(address(downbadDonkeysA), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            downbadDonkeysA.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        downbadDonkeysA.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(downbadDonkeysB.ownerOf(tokenId), owner);

        // approve the contract to swap your token - should be ALICE
        downbadDonkeysB.approve(address(downbadDonkeysB), tokenId);

        // reverts because contract is approved, not the user
        vm.startPrank(ALICE);
        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        downbadDonkeysB.sendFrom(
            owner, chainId_A, abi.encodePacked(ALICE), tokenId, payable(ALICE), address(0), defaultAdapterParams
        );
    }

    function testRevertsIfNotApprovedOnNonProxyChain() public {
        uint256 tokenId = 6;
        downbadDonkeysA.devMint(10);
        address owner = downbadDonkeysA.owner();

        // approve the proxy to swap your token
        downbadDonkeysA.approve(address(downbadDonkeysA), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            downbadDonkeysA.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        downbadDonkeysA.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(downbadDonkeysB.ownerOf(tokenId), owner);

        // reverts because user is not approved
        vm.startPrank(ALICE);
        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        downbadDonkeysB.sendFrom(
            owner, chainId_A, abi.encodePacked(ALICE), tokenId, payable(ALICE), address(0), defaultAdapterParams
        );
    }

    function testRevertsIfSenderDoesNotOwnToken() public {
        uint256 tokenIdA = 3;
        uint256 tokenIdB = 5;
        address owner = downbadDonkeysA.owner();
        downbadDonkeysA.devMint(10);
        downbadDonkeysA.transferFrom(owner, ALICE, tokenIdB);

        // approve owner address to transfer, but not the other
        downbadDonkeysA.setApprovalForAll(address(downbadDonkeysA), true);

        // reverts because ALICE is not owner of tokenIdA
        vm.startPrank(ALICE);

        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        downbadDonkeysA.sendFrom(
            ALICE, chainId_B, abi.encodePacked(ALICE), tokenIdA, payable(ALICE), address(0), defaultAdapterParams
        );

        // reverts because owner is not owner
        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        downbadDonkeysA.sendFrom(
            ALICE, chainId_B, abi.encodePacked(owner), tokenIdA, payable(owner), address(0), defaultAdapterParams
        );
    }

    function testTotalSupply() public {
        uint256 tokenId = 1;
        uint256 tokenId2 = 5000;
        assertEq(downbadDonkeysA.totalSupply(), 0);
        assertEq(downbadDonkeysB.totalSupply(), 0);
        downbadDonkeysA.devMint(10);
        address owner = downbadDonkeysA.owner();
        assertEq(downbadDonkeysA.totalSupply(), 10);

        (uint256 nativeFee,) =
            downbadDonkeysA.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        downbadDonkeysA.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );
        assertEq(downbadDonkeysA.totalSupply(), 9);
        assertEq(downbadDonkeysB.totalSupply(), 1);
        downbadDonkeysB.devMint(10);
        assertEq(downbadDonkeysB.totalSupply(), 11);

        (nativeFee,) =
            downbadDonkeysB.estimateSendFee(chainId_A, abi.encodePacked(owner), tokenId2, false, defaultAdapterParams);

        downbadDonkeysB.sendFrom{value: nativeFee}(
            owner, chainId_A, abi.encodePacked(owner), tokenId2, payable(owner), address(0), defaultAdapterParams
        );
        assertEq(downbadDonkeysA.totalSupply(), 10);
        assertEq(downbadDonkeysB.totalSupply(), 10);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "test/TestHelper.t.sol";
import "./mocks/LaunchpegLens.sol";
import "src/interfaces/LaunchpegInterfaces/ILaunchpegFactory.sol";

contract BasicMintTests is TestHelper {
    LaunchpegLens.LensData lensData;
    address downbadDonkeysAddress;
    LaunchpegLens launchpegLens = LaunchpegLens(0x5529596c716D184549feeA152cC42E3982f77f25);
    ILaunchpegFactory launchpegFactory = ILaunchpegFactory(0x62765C29c870af4d750Ba622A4d7F0a7308589c5);
    address factoryOwner;

    function setUp() public {
        vm.createSelectFork(StdChains.getChain("avalanche").rpcUrl, 26_647_000);
        factoryOwner = launchpegFactory.owner();

        DownbadDonkeys downbadDonkeysImplementation = new DownbadDonkeys();

        vm.startPrank(factoryOwner, factoryOwner);
        launchpegFactory.setFlatLaunchpegImplementation(address(downbadDonkeysImplementation));
        downbadDonkeysAddress = launchpegFactory.createFlatLaunchpeg(
            name,
            symbol,
            lzEndpoint,
            factoryOwner,
            maxPerAddressDuringMint,
            collectionSize,
            amountForDevsChainA,
            amountForPremintChainA,
            false
        );
        downbadDonkeys = DownbadDonkeys(downbadDonkeysAddress);
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevsChainA,
            amountForPremintChainA,
            maxPerAddressDuringMint,
            startMintIdChainA,
            endMintIdChainA
        );
        descriptor = new Descriptor(
            address(downbadDonkeys),
            batchRevealSize,
            collectionSize,
            vrfCoordinatorFakeAddress,
            true
        );
        downbadDonkeys.setDescriptor(address(descriptor));
        descriptor.setBaseURI(baseURI);
        descriptor.setUnrevealedURI(unrevealedURI);
        address[] memory _addresses = new address[](1);
        _addresses[0] = ALICE;
        uint256[] memory _numNfts = new uint256[](1);
        _numNfts[0] = 3;
        downbadDonkeys.seedPremintlist(_addresses, _numNfts);

        vm.stopPrank();
        vm.deal(ALICE, 1 << 128);
    }

    function testLens() public {
        lensData = launchpegLens.getLaunchpegData(address(downbadDonkeys), ALICE);
        assertEq(uint256(lensData.launchType), 2);
        assertEq(lensData.collectionData.name, name);
        assertEq(lensData.collectionData.symbol, symbol);
        assertEq(lensData.collectionData.collectionSize, collectionSize);
        assertEq(lensData.collectionData.maxPerAddressDuringMint, maxPerAddressDuringMint);
        assertEq(lensData.collectionData.totalSupply, 0);
        assertEq(lensData.collectionData.unrevealedURI, unrevealedURI);
        assertEq(lensData.collectionData.baseURI, baseURI);

        assertEq(uint256(lensData.flatLaunchpegData.currentPhase), 2);
        assertEq(lensData.flatLaunchpegData.amountForAllowlist, amountForPremintChainA);
        assertEq(lensData.flatLaunchpegData.amountForDevs, amountForDevsChainA);
        assertEq(lensData.flatLaunchpegData.preMintStartTime, block.timestamp);
        assertEq(lensData.flatLaunchpegData.allowlistStartTime, block.timestamp + premintPhaseDuration);
        assertEq(lensData.flatLaunchpegData.publicSaleStartTime, block.timestamp + premintPhaseDuration);
        assertEq(
            lensData.flatLaunchpegData.publicSaleEndTime, block.timestamp + premintPhaseDuration + publicPhaseDuration
        );
        assertEq(lensData.flatLaunchpegData.allowlistPrice, price);
        assertEq(lensData.flatLaunchpegData.salePrice, price);
        assertEq(lensData.flatLaunchpegData.amountMintedDuringPreMint, 0);
        assertEq(lensData.flatLaunchpegData.amountClaimedDuringPreMint, 0);
        assertEq(lensData.flatLaunchpegData.amountMintedDuringAllowlist, 0);
        assertEq(lensData.flatLaunchpegData.amountMintedDuringPublicSale, 0);

        assertEq(lensData.userData.balanceOf, 0);
        assertEq(lensData.userData.numberMinted, 0);
        assertEq(lensData.userData.numberMintedWithPreMint, 0);
        assertEq(lensData.userData.allowanceForAllowlistMint, 3);

        assertEq(lensData.projectOwnerData.projectOwners.length, 0);
        assertEq(lensData.projectOwnerData.amountMintedByDevs, 0);
        assertEq(lensData.projectOwnerData.withdrawAVAXStartTime, 0);
        assertEq(lensData.projectOwnerData.launchpegBalanceAVAX, 0);

        launchpegLens.getLaunchpegType(address(downbadDonkeys));

        vm.prank(factoryOwner, factoryOwner);
        downbadDonkeys.devMint(5);
        vm.startPrank(ALICE, ALICE);
        downbadDonkeys.preMint{value: price * 2}(2);
        vm.warp(block.timestamp + premintPhaseDuration);
        downbadDonkeys.publicSaleMint{value: price * 2}(2);

        lensData = launchpegLens.getLaunchpegData(address(downbadDonkeys), ALICE);

        assertEq(lensData.collectionData.totalSupply, 7);
        assertEq(uint256(lensData.flatLaunchpegData.currentPhase), 4);
        assertEq(lensData.userData.balanceOf, 2);
        assertEq(lensData.userData.numberMinted, 2);
        assertEq(lensData.userData.numberMintedWithPreMint, 4);
        assertEq(lensData.userData.allowanceForAllowlistMint, 1);

        assertEq(lensData.flatLaunchpegData.amountMintedDuringPreMint, 2);
        assertEq(lensData.flatLaunchpegData.amountMintedDuringPublicSale, 2);
        assertEq(lensData.projectOwnerData.amountMintedByDevs, 5);
        assertEq(lensData.projectOwnerData.launchpegBalanceAVAX, 4 * price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "test/TestHelper.t.sol";

contract MintTests is TestHelper {
    address[] addresses;
    uint256[] amounts;

    function setUp() public {
        DownbadDonkeys downbadDonkeysImplementation = new DownbadDonkeys();
        address downbadDonkeysAddress = Clones.clone(address(downbadDonkeysImplementation));

        downbadDonkeys = DownbadDonkeys(downbadDonkeysAddress);
        downbadDonkeys.initialize(collectionData, collectionOwnerData);
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevsChainA,
            amountForPremintChainA,
            maxPerAddressDuringMint,
            startMintIdChainA,
            endMintIdChainA
        );
        descriptor = new Descriptor(
            address(downbadDonkeys),
            batchRevealSize,
            collectionSize,
            vrfCoordinatorFakeAddress,
            true
        );
        vm.deal(ALICE, 1 << 128);
        vm.deal(BOB, 1 << 128);
        vm.deal(CAROL, 1 << 128);

        addresses = new address[](3);
        addresses[0] = ALICE;
        addresses[1] = BOB;
        addresses[2] = CAROL;
        amounts = new uint256[](3);
        amounts[0] = 1;
        amounts[1] = 2;
        amounts[2] = 3;
    }

    function testSeedPremintlistReverts() public {
        vm.prank(ALICE);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        downbadDonkeys.seedPremintlist(addresses, amounts);
        address[] memory addressesWrongLength = new address[](2);
        uint256[] memory amountsWrongLength = new uint256[](2);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__WrongAddressesAndNumSlotsLength.selector);
        downbadDonkeys.seedPremintlist(addressesWrongLength, amounts);

        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__WrongAddressesAndNumSlotsLength.selector);
        downbadDonkeys.seedPremintlist(addresses, amountsWrongLength);
    }

    function testPremint() public {
        vm.prank(ALICE);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        downbadDonkeys.seedPremintlist(addresses, amounts);

        downbadDonkeys.seedPremintlist(addresses, amounts);
        assertEq(downbadDonkeys.premintList(ALICE), 1);
        assertEq(downbadDonkeys.premintList(BOB), 2);
        assertEq(downbadDonkeys.premintList(CAROL), 3);

        vm.prank(ALICE);
        downbadDonkeys.preMint{value: price}(1);
        assertEq(downbadDonkeys.numberMintedWithPreMint(ALICE), 1);
        assertEq(downbadDonkeys.premintList(ALICE), 0);
        assertEq(downbadDonkeys.premintList(BOB), 2);
        assertEq(downbadDonkeys.premintList(CAROL), 3);

        vm.prank(BOB);
        downbadDonkeys.preMint{value: 2 * price}(2);
        assertEq(downbadDonkeys.numberMintedWithPreMint(BOB), 2);
        assertEq(downbadDonkeys.premintList(ALICE), 0);
        assertEq(downbadDonkeys.premintList(BOB), 0);
        assertEq(downbadDonkeys.premintList(CAROL), 3);

        vm.prank(CAROL);
        downbadDonkeys.preMint{value: 2 * price}(2);
        assertEq(downbadDonkeys.numberMintedWithPreMint(CAROL), 2);
        assertEq(downbadDonkeys.premintList(ALICE), 0);
        assertEq(downbadDonkeys.premintList(BOB), 0);
        assertEq(downbadDonkeys.premintList(CAROL), 1);

        vm.prank(CAROL);
        downbadDonkeys.preMint{value: price}(1);
        assertEq(downbadDonkeys.numberMintedWithPreMint(CAROL), 3);
        assertEq(downbadDonkeys.premintList(ALICE), 0);
        assertEq(downbadDonkeys.premintList(BOB), 0);
        assertEq(downbadDonkeys.premintList(CAROL), 0);

        vm.startPrank(ALICE);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__WrongPhase.selector);
        downbadDonkeys.claimPreMint();
        assertEq(downbadDonkeys.startMintId(), 0);
        assertEq(downbadDonkeys.balanceOf(ALICE), 0);
        assertEq(downbadDonkeys.amountMintedOnThisChain(), 0);

        vm.warp(block.timestamp + premintPhaseDuration);

        downbadDonkeys.claimPreMint();
        assertEq(downbadDonkeys.balanceOf(ALICE), 1);
        assertEq(downbadDonkeys.startMintId(), 1);
        assertEq(downbadDonkeys.amountMintedOnThisChain(), 1);

        downbadDonkeys.batchClaimPreMint(3);
        assertEq(downbadDonkeys.balanceOf(BOB), 2);
        assertEq(downbadDonkeys.balanceOf(CAROL), 1);
        assertEq(downbadDonkeys.startMintId(), 4);
        assertEq(downbadDonkeys.amountMintedOnThisChain(), 4);
        vm.stopPrank();

        vm.warp(block.timestamp + publicPhaseDuration);
        vm.startPrank(CAROL);
        downbadDonkeys.claimPreMint();
        assertEq(downbadDonkeys.balanceOf(CAROL), 3);
        assertEq(downbadDonkeys.startMintId(), 6);
        assertEq(downbadDonkeys.amountMintedOnThisChain(), 6);

        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidClaim.selector);
        downbadDonkeys.claimPreMint();
    }

    function testPremintReverts() public {
        vm.prank(ALICE);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__NotEligibleForPreMint.selector);
        downbadDonkeys.preMint{value: price}(1);
        amounts[2] = 100;
        downbadDonkeys.seedPremintlist(addresses, amounts);

        vm.startPrank(ALICE);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__NotEligibleForPreMint.selector);
        downbadDonkeys.preMint{value: 2 * price}(2);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidQuantity.selector);
        downbadDonkeys.preMint{value: 0}(0);

        vm.stopPrank();
        vm.prank(CAROL);
        downbadDonkeys.preMint{value: price * amounts[2]}(uint96(amounts[2]));
        vm.prank(BOB);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__MaxSupplyReached.selector);
        downbadDonkeys.preMint{value: price}(1);

        vm.warp(block.timestamp + premintPhaseDuration);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidQuantity.selector);
        downbadDonkeys.batchClaimPreMint(0);
    }

    function testPublicMint() public {
        amounts[2] = 90;
        downbadDonkeys.seedPremintlist(addresses, amounts);
        vm.prank(CAROL);
        downbadDonkeys.preMint{value: price * amounts[2]}(uint96(amounts[2]));

        vm.warp(block.timestamp + premintPhaseDuration);

        vm.startPrank(ALICE, ALICE);
        assertEq(0, downbadDonkeys.startMintId());

        downbadDonkeys.publicSaleMint{value: maxPerAddressDuringMint * price}(maxPerAddressDuringMint);
        assertEq(downbadDonkeys.balanceOf(ALICE), maxPerAddressDuringMint);
        assertEq(maxPerAddressDuringMint, downbadDonkeys.startMintId());

        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__CanNotMintThisMany.selector);
        downbadDonkeys.publicSaleMint{value: price}(1);
        vm.stopPrank();
        downbadDonkeys.devMint(100);

        // 90 preminted, 100 dev minted, 10 public minted = 200 tokens total
        assertEq(downbadDonkeys.startMintId(), 110);
        vm.startPrank(BOB, BOB);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__MaxSupplyReached.selector);
        downbadDonkeys.publicSaleMint{value: price}(1);

        downbadDonkeys.batchClaimPreMint(100);

        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidClaim.selector);
        downbadDonkeys.batchClaimPreMint(100);

        assertEq(downbadDonkeys.startMintId(), 200);
        // tokenId 200 doesn't exist and can't be minted on this chain
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidTokenId.selector);
        downbadDonkeys.tokenURI(200);
    }

    function testDevMint() public {
        address owner = downbadDonkeys.owner();
        downbadDonkeys.devMint(100);
        assertEq(downbadDonkeys.startMintId(), 100);
        assertEq(downbadDonkeys.balanceOf(owner), 100);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__MaxSupplyForDevReached.selector);
        downbadDonkeys.devMint(1);
    }

    function testRefund() public {
        vm.warp(block.timestamp + premintPhaseDuration);
        vm.startPrank(ALICE, ALICE);
        uint256 balanceBefore = ALICE.balance;
        downbadDonkeys.publicSaleMint{value: 2 * maxPerAddressDuringMint * price}(maxPerAddressDuringMint);
        assertEq(ALICE.balance, balanceBefore - maxPerAddressDuringMint * price);
    }

    function testEnoughNativeSent() public {
        downbadDonkeys.seedPremintlist(addresses, amounts);
        vm.startPrank(ALICE, ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDownbadDonkeys.DownbadDonkeys__NotEnoughNative.selector, price - 1));
        downbadDonkeys.preMint{value: price - 1}(1);

        vm.warp(block.timestamp + premintPhaseDuration);
        vm.expectRevert(abi.encodeWithSelector(IDownbadDonkeys.DownbadDonkeys__NotEnoughNative.selector, price - 1));
        downbadDonkeys.publicSaleMint{value: price - 1}(1);
    }

    function testWithdraw() public {
        downbadDonkeys.seedPremintlist(addresses, amounts);
        assertEq(downbadDonkeys.premintList(ALICE), 1);
        assertEq(downbadDonkeys.premintList(BOB), 2);
        assertEq(downbadDonkeys.premintList(CAROL), 3);

        vm.startPrank(ALICE, ALICE);
        downbadDonkeys.preMint{value: price}(1);

        vm.warp(block.timestamp + premintPhaseDuration);
        downbadDonkeys.publicSaleMint{value: price}(1);
        vm.stopPrank();
        assertEq(address(downbadDonkeys).balance, price * 2);
        downbadDonkeys.withdrawNative(makeAddr("recepient"));
        assertEq(address(downbadDonkeys).balance, 0);
        assertEq(makeAddr("recepient").balance, price * 2);
    }

    function testStartNewPhasesTime() public {
        vm.warp(block.timestamp + premintPhaseDuration + publicPhaseDuration);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.startNewPhases(
            block.timestamp - 1,
            block.timestamp,
            block.timestamp,
            price,
            price,
            amountForDevsChainA,
            amountForPremintChainA,
            maxPerAddressDuringMint,
            startMintIdChainA,
            endMintIdChainA
        );

        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.startNewPhases(
            block.timestamp + 1,
            block.timestamp,
            block.timestamp + 2,
            price,
            price,
            amountForDevsChainA,
            amountForPremintChainA,
            maxPerAddressDuringMint,
            startMintIdChainA,
            endMintIdChainA
        );
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__InvalidPhases.selector);
        downbadDonkeys.startNewPhases(
            block.timestamp + 1,
            block.timestamp + 2,
            block.timestamp,
            price,
            price,
            amountForDevsChainA,
            amountForPremintChainA,
            maxPerAddressDuringMint,
            startMintIdChainA,
            endMintIdChainA
        );

        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + 1,
            block.timestamp + 2,
            price,
            price,
            amountForDevsChainA,
            amountForPremintChainA,
            maxPerAddressDuringMint,
            startMintIdChainA,
            endMintIdChainA
        );
        assertEq(downbadDonkeys.preMintStartTime(), block.timestamp);
        assertEq(downbadDonkeys.publicSaleStartTime(), block.timestamp + 1);
        assertEq(downbadDonkeys.publicSaleEndTime(), block.timestamp + 2);
    }

    function testNewPhasesMintAmounts() public {
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + 1,
            block.timestamp + 2,
            price,
            price,
            10, //amountForDevs
            5, //amountForPremint
            5, //maxPerAddressDuringMint
            0, //startMintId
            20 //endMintId
        );
        assertEq(downbadDonkeys.amountForDevs(), 10);
        assertEq(downbadDonkeys.amountForAllowlist(), 5);
        assertEq(downbadDonkeys.maxPerAddressDuringMint(), 5);
        assertEq(downbadDonkeys.startMintId(), 0);
        assertEq(downbadDonkeys.endMintId(), 20);

        downbadDonkeys.devMint(10);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__MaxSupplyForDevReached.selector);
        downbadDonkeys.devMint(10);

        downbadDonkeys.seedPremintlist(addresses, amounts);
        vm.prank(ALICE, ALICE);
        downbadDonkeys.preMint{value: price}(1);
        vm.prank(BOB, BOB);
        downbadDonkeys.preMint{value: 2 * price}(2);
        vm.prank(CAROL, CAROL);
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__MaxSupplyReached.selector);
        downbadDonkeys.preMint{value: 3 * price}(3);

        skip(1);
        vm.prank(CAROL, CAROL);
        downbadDonkeys.publicSaleMint{value: 5 * price}(5);

        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__UnclaimedTokensExist.selector);

        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + 1,
            block.timestamp + 2,
            price * 2,
            price * 2,
            10, //amountForDevs
            5, //amountForPremint
            5, //maxPerAddressDuringMint
            18, //startMintId
            38 //endMintId
        );
        downbadDonkeys.batchClaimPreMint(100);

        assertEq(downbadDonkeys.amountMintedOnThisChain(), 18);

        // Start new phases. Last token minted has tokenID 17, so next mint starts at startMintId = 18
        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + 1,
            block.timestamp + 2,
            price * 2,
            price * 3,
            10, //amountForDevs
            5, //amountForPremint
            5, //maxPerAddressDuringMint
            18, //startMintId
            38 //endMintId
        );
        downbadDonkeys.seedPremintlist(addresses, amounts);

        assertEq(downbadDonkeys.allowlistPrice(), price * 2);
        assertEq(downbadDonkeys.salePrice(), price * 3);
        assertEq(downbadDonkeys.startMintId(), 18);
        assertEq(downbadDonkeys.endMintId(), 38);
        assertEq(downbadDonkeys.amountForDevs(), 10);
        assertEq(downbadDonkeys.amountForAllowlist(), 5);
        assertEq(downbadDonkeys.maxPerAddressDuringMint(), 5);

        assertEq(downbadDonkeys.amountMintedByDevs(), 0);
        assertEq(downbadDonkeys.amountMintedDuringPreMint(), 0);
        assertEq(downbadDonkeys.amountClaimedDuringPreMint(), 0);
        assertEq(downbadDonkeys.amountMintedDuringPublicSale(), 0);

        // Dev can mint again
        downbadDonkeys.devMint(10);
        assertEq(downbadDonkeys.amountMintedByDevs(), 10);
        vm.prank(ALICE, ALICE);
        downbadDonkeys.preMint{value: 2 * price}(1);
        vm.prank(BOB, BOB);
        downbadDonkeys.preMint{value: 2 * 2 * price}(2);
        skip(1);
        startHoax(makeAddr("DEBBIE"), makeAddr("DEBBIE"), 1 << 127);
        downbadDonkeys.publicSaleMint{value: 5 * 3 * price}(5);

        downbadDonkeys.batchClaimPreMint(100);

        assertEq(downbadDonkeys.amountMintedDuringPreMint(), 3);
        assertEq(downbadDonkeys.amountClaimedDuringPreMint(), 3);
        assertEq(downbadDonkeys.amountMintedDuringPublicSale(), 5);
        assertEq(downbadDonkeys.amountMintedOnThisChain(), 18 + 18);
    }

    function testLockingNewPhases() public {
        downbadDonkeys.lockNewMintPhasesForever();
        vm.expectRevert(IDownbadDonkeys.DownbadDonkeys__CantAddNewPhasesAnymore.selector);

        downbadDonkeys.startNewPhases(
            block.timestamp,
            block.timestamp + premintPhaseDuration,
            block.timestamp + premintPhaseDuration + publicPhaseDuration,
            price,
            price,
            amountForDevsChainA,
            amountForPremintChainA,
            maxPerAddressDuringMint,
            startMintIdChainA,
            endMintIdChainA
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "openzeppelin/interfaces/IERC165.sol";
import {IERC721} from "openzeppelin/interfaces/IERC721.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";
import {Test} from "forge-std/Test.sol";
import {
    OperatorFilterRegistry,
    OperatorFilterRegistryErrorsAndEvents,
    IOperatorFilterRegistry
} from "operator-filter-registry/OperatorFilterRegistry.sol";
import {IDownbadDonkeys} from "src/interfaces/IDownbadDonkeys.sol";
import {DownbadDonkeys} from "src/DownbadDonkeys.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";

contract BaseRegistryTest is Test, OperatorFilterRegistryErrorsAndEvents {
    OperatorFilterRegistry constant registry = OperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    function setUp() public virtual {
        address deployedRegistry = address(new OperatorFilterRegistry());
        vm.etch(address(registry), deployedRegistry.code);
    }
}

contract TestableExampleERC721 is DownbadDonkeys {
    constructor() {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract ExampleERC721Test is BaseRegistryTest {
    address payable DEV = payable(address(this));
    IDownbadDonkeys.CollectionData collectionData =
        IDownbadDonkeys.CollectionData("DownbadDonkeys", "DBD", address(0), 10, 10, 10, 0, 10);
    IDownbadDonkeys.CollectionOwnerData collectionOwnerData =
        IDownbadDonkeys.CollectionOwnerData(DEV, makeAddr("lzEndpoint"), DEV, address(0), 0);

    TestableExampleERC721 example;
    address filteredAddress;

    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function setUp() public override {
        super.setUp();

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);

        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), filteredAddress, true);
        vm.stopPrank();
        DownbadDonkeys exampleImplementation = new TestableExampleERC721();
        address exampleImplementationAddress = Clones.clone(address(exampleImplementation));

        example = TestableExampleERC721(exampleImplementationAddress);
        //example = new TestableExampleERC721();
        example.initialize(collectionData, collectionOwnerData);
    }

    function testFilter() public {
        vm.startPrank(address(filteredAddress));
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        example.transferFrom(makeAddr("from"), makeAddr("to"), 1);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        example.safeTransferFrom(makeAddr("from"), makeAddr("to"), 1);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        example.safeTransferFrom(makeAddr("from"), makeAddr("to"), 1, "");
    }

    function testOwnersNotExcluded() public {
        address alice = address(0xA11CE);
        example.mint(alice, 1);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.prank(alice);
        example.transferFrom(alice, makeAddr("to"), 1);
    }

    function testOwnersNotExcludedSafeTransfer() public {
        address alice = address(0xA11CE);
        example.mint(alice, 1);
        example.mint(alice, 2);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.startPrank(alice);
        example.safeTransferFrom(alice, makeAddr("to"), 1);
        example.safeTransferFrom(alice, makeAddr("to"), 2, "");
    }

    function testExclusionExceptionDoesNotApplyToOperators() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        example.mint(bob, 1);
        vm.prank(bob);
        example.setApprovalForAll(alice, true);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, alice));
        example.transferFrom(bob, makeAddr("to"), 1);
    }

    function testExcludeApprovals() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        example.mint(bob, 1);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, alice));
        example.setApprovalForAll(alice, true);

        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, alice));
        example.approve(alice, 1);
    }

    function testSupportsInterface() public {
        assertTrue(example.supportsInterface(type(IERC165).interfaceId));
        assertTrue(example.supportsInterface(type(IERC721).interfaceId));
        assertTrue(example.supportsInterface(type(IERC2981).interfaceId));
    }

    function testUpdateOperatorFilterRegistryAddress() public {
        address newRegistry = makeAddr("new registry");
        example.updateOperatorFilterRegistryAddress(IOperatorFilterRegistry(newRegistry));
        assertEq(address(example.operatorFilterRegistry()), newRegistry);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "openzeppelin/proxy/Clones.sol";

import "src/DownbadDonkeys.sol";
import "src/Descriptor.sol";
import "src/interfaces/IDescriptor.sol";
import "src/interfaces/IDownbadDonkeys.sol";
import "src/interfaces/IERC4906.sol";

contract TestHelper is Test {
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    address payable DEV = payable(address(this));
    address public ALICE = makeAddr("ALICE");
    address public BOB = makeAddr("BOB");
    address public CAROL = makeAddr("CAROL");
    DownbadDonkeys downbadDonkeys;
    DownbadDonkeys downbadDonkeysSecondChain;
    Descriptor descriptor;
    Descriptor descriptorSecondChain;
    address vrfCoordinatorFakeAddress = makeAddr("vrfCoordinator");
    string name = "DownbadDonkeys";
    string symbol = "DBD";
    uint256 collectionSize = 10000;
    uint256 batchRevealSize = 1000;
    uint256 minGasToTransfer = 150000;
    address lzEndpoint = makeAddr("lzEndpoint");
    uint256 amountForDevsChainA = 100;
    uint256 amountForPremintChainA = 100;
    uint256 startMintIdChainA = 0;
    uint256 endMintIdChainA = 199;

    uint256 amountForDevsChainB = 100;
    uint256 amountForPremintChainB = 100;
    uint256 startMintIdChainB = 200;
    uint256 endMintIdChainB = 399;

    uint256 premintPhaseDuration = 100;
    uint256 publicPhaseDuration = 100;
    uint256 maxPerAddressDuringMint = 10;
    uint256 price = 0.1 ether;

    string baseURI = "ipfs://joestudios.metadata/";
    string unrevealedURI = "ipfs://joestudios.unrevealed/";

    IDownbadDonkeys.CollectionData collectionData = IDownbadDonkeys.CollectionData(
        name,
        symbol,
        address(0),
        maxPerAddressDuringMint,
        collectionSize,
        amountForDevsChainA,
        0,
        amountForPremintChainA
    );
    IDownbadDonkeys.CollectionOwnerData collectionOwnerData =
        IDownbadDonkeys.CollectionOwnerData(DEV, lzEndpoint, DEV, address(0), 0);

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

import "solidity-examples/interfaces/ILayerZeroReceiver.sol";
import "solidity-examples/interfaces/ILayerZeroEndpoint.sol";
import "solidity-examples/libraries/LzLib.sol";
import "forge-std/console.sol";

/*
like a real LayerZero endpoint but can be mocked, which handle message transmission, verification, and receipt.
- blocking: LayerZero provides ordered delivery of messages from a given sender to a destination chain.
- non-reentrancy: endpoint has a non-reentrancy guard for both the send() and receive(), respectively.
- adapter parameters: allows UAs to add arbitrary transaction params in the send() function, like airdrop on destination chain.
unlike a real LayerZero endpoint, it is
- no messaging library versioning
- send() will short circuit to lzReceive()
- no user application configuration
*/
contract LZEndpointMock is ILayerZeroEndpoint {
    uint8 internal constant _NOT_ENTERED = 1;
    uint8 internal constant _ENTERED = 2;

    mapping(address => address) public lzEndpointLookup;

    uint16 public mockChainId;
    bool public nextMsgBlocked;

    // fee config
    RelayerFeeConfig public relayerFeeConfig;
    ProtocolFeeConfig public protocolFeeConfig;
    uint256 public oracleFee;
    bytes public defaultAdapterParams;

    // path = remote addrss + local address
    // inboundNonce = [srcChainId][path].
    mapping(uint16 => mapping(bytes => uint64)) public inboundNonce;
    //todo: this is a hack
    // outboundNonce = [dstChainId][srcAddress]
    mapping(uint16 => mapping(address => uint64)) public outboundNonce;
    //    // outboundNonce = [dstChainId][path].
    //    mapping(uint16 => mapping(bytes => uint64)) public outboundNonce;
    // storedPayload = [srcChainId][path]
    mapping(uint16 => mapping(bytes => StoredPayload)) public storedPayload;
    // msgToDeliver = [srcChainId][path]
    mapping(uint16 => mapping(bytes => QueuedPayload[])) public msgsToDeliver;

    // reentrancy guard
    uint8 internal _send_entered_state = 1;
    uint8 internal _receive_entered_state = 1;

    struct ProtocolFeeConfig {
        uint256 zroFee;
        uint256 nativeBP;
    }

    struct RelayerFeeConfig {
        uint128 dstPriceRatio; // 10^10
        uint128 dstGasPriceInWei;
        uint128 dstNativeAmtCap;
        uint64 baseGas;
        uint64 gasPerByte;
    }

    struct StoredPayload {
        uint64 payloadLength;
        address dstAddress;
        bytes32 payloadHash;
    }

    struct QueuedPayload {
        address dstAddress;
        uint64 nonce;
        bytes payload;
    }

    modifier sendNonReentrant() {
        require(
            _send_entered_state == _NOT_ENTERED,
            "LayerZeroMock: no send reentrancy"
        );
        _send_entered_state = _ENTERED;
        _;
        _send_entered_state = _NOT_ENTERED;
    }

    modifier receiveNonReentrant() {
        require(
            _receive_entered_state == _NOT_ENTERED,
            "LayerZeroMock: no receive reentrancy"
        );
        _receive_entered_state = _ENTERED;
        _;
        _receive_entered_state = _NOT_ENTERED;
    }

    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);
    event PayloadCleared(
        uint16 srcChainId,
        bytes srcAddress,
        uint64 nonce,
        address dstAddress
    );
    event PayloadStored(
        uint16 srcChainId,
        bytes srcAddress,
        address dstAddress,
        uint64 nonce,
        bytes payload,
        bytes reason
    );
    event ValueTransferFailed(address indexed to, uint256 indexed quantity);

    constructor(uint16 _chainId) {
        mockChainId = _chainId;

        // init config
        relayerFeeConfig = RelayerFeeConfig({
            dstPriceRatio: 1e10, // 1:1, same chain, same native coin
            dstGasPriceInWei: 1e10,
            dstNativeAmtCap: 1e19,
            baseGas: 100,
            gasPerByte: 1
        });
        protocolFeeConfig = ProtocolFeeConfig({zroFee: 1e18, nativeBP: 1000}); // BP 0.1
        oracleFee = 1e16;
        defaultAdapterParams = LzLib.buildDefaultAdapterParams(200000);
    }

    // ------------------------------ ILayerZeroEndpoint Functions ------------------------------
    function send(
        uint16 _chainId,
        bytes memory _path,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) external payable override sendNonReentrant {
        require(
            _path.length == 40,
            "LayerZeroMock: incorrect remote address size"
        ); // only support evm chains

        address dstAddr;
        assembly {
            dstAddr := mload(add(_path, 20))
        }

        address lzEndpoint = lzEndpointLookup[dstAddr];
        require(
            lzEndpoint != address(0),
            "LayerZeroMock: destination LayerZero Endpoint not found"
        );

        // not handle zro token
        bytes memory adapterParams = _adapterParams.length > 0
            ? _adapterParams
            : defaultAdapterParams;
        (uint256 nativeFee, ) = estimateFees(
            _chainId,
            msg.sender,
            _payload,
            _zroPaymentAddress != address(0x0),
            adapterParams
        );

        require(
            msg.value >= nativeFee,
            "LayerZeroMock: not enough native for fees"
        );

        uint64 nonce = ++outboundNonce[_chainId][msg.sender];

        // refund if they send too much
        uint256 amount = msg.value - nativeFee;
        if (amount > 0) {
            (bool success, ) = _refundAddress.call{value: amount}("");
            require(success, "LayerZeroMock: failed to refund");
        }

        // Mock the process of receiving msg on dst chain
        // Mock the relayer paying the dstNativeAddr the amount of extra native token
        (
            ,
            uint256 extraGas,
            uint256 dstNativeAmt,
            address payable dstNativeAddr
        ) = LzLib.decodeAdapterParams(adapterParams);
        if (dstNativeAmt > 0) {
            (bool success, ) = dstNativeAddr.call{value: dstNativeAmt}("");
            if (!success) {
                emit ValueTransferFailed(dstNativeAddr, dstNativeAmt);
            }
        }

        bytes memory srcUaAddress = abi.encodePacked(msg.sender, dstAddr); // cast this address to bytes
        bytes memory payload = _payload;
        LZEndpointMock(lzEndpoint).receivePayload(
            mockChainId,
            srcUaAddress,
            dstAddr,
            nonce,
            extraGas,
            payload
        );
    }

    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _path,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external override receiveNonReentrant {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];

        // assert and increment the nonce. no message shuffling
        require(
            _nonce == ++inboundNonce[_srcChainId][_path],
            "LayerZeroMock: wrong nonce"
        );

        // queue the following msgs inside of a stack to simulate a successful send on src, but not fully delivered on dst
        if (sp.payloadHash != bytes32(0)) {
            QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_path];
            QueuedPayload memory newMsg = QueuedPayload(
                _dstAddress,
                _nonce,
                _payload
            );

            // warning, might run into gas issues trying to forward through a bunch of queued msgs
            // shift all the msgs over so we can treat this like a fifo via array.pop()
            if (msgs.length > 0) {
                // extend the array
                msgs.push(newMsg);

                // shift all the indexes up for pop()
                for (uint256 i = 0; i < msgs.length - 1; i++) {
                    msgs[i + 1] = msgs[i];
                }

                // put the newMsg at the bottom of the stack
                msgs[0] = newMsg;
            } else {
                msgs.push(newMsg);
            }
        } else if (nextMsgBlocked) {
            storedPayload[_srcChainId][_path] = StoredPayload(
                uint64(_payload.length),
                _dstAddress,
                keccak256(_payload)
            );
            emit PayloadStored(
                _srcChainId,
                _path,
                _dstAddress,
                _nonce,
                _payload,
                bytes("")
            );
            // ensure the next msgs that go through are no longer blocked
            nextMsgBlocked = false;
        } else {
            try
                ILayerZeroReceiver(_dstAddress).lzReceive{gas: _gasLimit}(
                    _srcChainId,
                    _path,
                    _nonce,
                    _payload
                )
            {} catch (bytes memory reason) {
                storedPayload[_srcChainId][_path] = StoredPayload(
                    uint64(_payload.length),
                    _dstAddress,
                    keccak256(_payload)
                );
                emit PayloadStored(
                    _srcChainId,
                    _path,
                    _dstAddress,
                    _nonce,
                    _payload,
                    reason
                );
                // ensure the next msgs that go through are no longer blocked
                nextMsgBlocked = false;
            }
        }
    }

    function getInboundNonce(uint16 _chainID, bytes calldata _path)
        external
        view
        override
        returns (uint64)
    {
        return inboundNonce[_chainID][_path];
    }

    function getOutboundNonce(uint16 _chainID, address _srcAddress)
        external
        view
        override
        returns (uint64)
    {
        return outboundNonce[_chainID][_srcAddress];
    }

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes memory _payload,
        bool _payInZRO,
        bytes memory _adapterParams
    ) public view override returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory adapterParams = _adapterParams.length > 0
            ? _adapterParams
            : defaultAdapterParams;

        // Relayer Fee
        uint256 relayerFee = _getRelayerFee(
            _dstChainId,
            1,
            _userApplication,
            _payload.length,
            adapterParams
        );

        // LayerZero Fee
        uint256 protocolFee = _getProtocolFees(
            _payInZRO,
            relayerFee,
            oracleFee
        );
        _payInZRO ? zroFee = protocolFee : nativeFee = protocolFee;

        // return the sum of fees
        nativeFee = nativeFee + relayerFee + oracleFee;
    }

    function getChainId() external view override returns (uint16) {
        return mockChainId;
    }

    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _path,
        bytes calldata _payload
    ) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        require(
            sp.payloadHash != bytes32(0),
            "LayerZeroMock: no stored payload"
        );
        require(
            _payload.length == sp.payloadLength &&
                keccak256(_payload) == sp.payloadHash,
            "LayerZeroMock: invalid payload"
        );

        address dstAddress = sp.dstAddress;
        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        uint64 nonce = inboundNonce[_srcChainId][_path];

        ILayerZeroReceiver(dstAddress).lzReceive(
            _srcChainId,
            _path,
            nonce,
            _payload
        );
        emit PayloadCleared(_srcChainId, _path, nonce, dstAddress);
    }

    function hasStoredPayload(uint16 _srcChainId, bytes calldata _path)
        external
        view
        override
        returns (bool)
    {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        return sp.payloadHash != bytes32(0);
    }

    function getSendLibraryAddress(address)
        external
        view
        override
        returns (address)
    {
        return address(this);
    }

    function getReceiveLibraryAddress(address)
        external
        view
        override
        returns (address)
    {
        return address(this);
    }

    function isSendingPayload() external view override returns (bool) {
        return _send_entered_state == _ENTERED;
    }

    function isReceivingPayload() external view override returns (bool) {
        return _receive_entered_state == _ENTERED;
    }

    function getConfig(
        uint16, /*_version*/
        uint16, /*_chainId*/
        address, /*_ua*/
        uint256 /*_configType*/
    ) external pure override returns (bytes memory) {
        return "";
    }

    function getSendVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function getReceiveVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function setConfig(
        uint16, /*_version*/
        uint16, /*_chainId*/
        uint256, /*_configType*/
        bytes memory /*_config*/
    ) external override {}

    function setSendVersion(
        uint16 /*version*/
    ) external override {}

    function setReceiveVersion(
        uint16 /*version*/
    ) external override {}

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _path)
        external
        override
    {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        // revert if no messages are cached. safeguard malicious UA behaviour
        require(
            sp.payloadHash != bytes32(0),
            "LayerZeroMock: no stored payload"
        );
        require(sp.dstAddress == msg.sender, "LayerZeroMock: invalid caller");

        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        emit UaForceResumeReceive(_srcChainId, _path);

        // resume the receiving of msgs after we force clear the "stuck" msg
        _clearMsgQue(_srcChainId, _path);
    }

    // ------------------------------ Other Public/External Functions --------------------------------------------------

    function getLengthOfQueue(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint256)
    {
        return msgsToDeliver[_srcChainId][_srcAddress].length;
    }

    // used to simulate messages received get stored as a payload
    function blockNextMsg() external {
        nextMsgBlocked = true;
    }

    function setDestLzEndpoint(address destAddr, address lzEndpointAddr)
        external
    {
        lzEndpointLookup[destAddr] = lzEndpointAddr;
    }

    function setRelayerPrice(
        uint128 _dstPriceRatio,
        uint128 _dstGasPriceInWei,
        uint128 _dstNativeAmtCap,
        uint64 _baseGas,
        uint64 _gasPerByte
    ) external {
        relayerFeeConfig.dstPriceRatio = _dstPriceRatio;
        relayerFeeConfig.dstGasPriceInWei = _dstGasPriceInWei;
        relayerFeeConfig.dstNativeAmtCap = _dstNativeAmtCap;
        relayerFeeConfig.baseGas = _baseGas;
        relayerFeeConfig.gasPerByte = _gasPerByte;
    }

    function setProtocolFee(uint256 _zroFee, uint256 _nativeBP) external {
        protocolFeeConfig.zroFee = _zroFee;
        protocolFeeConfig.nativeBP = _nativeBP;
    }

    function setOracleFee(uint256 _oracleFee) external {
        oracleFee = _oracleFee;
    }

    function setDefaultAdapterParams(bytes memory _adapterParams) external {
        defaultAdapterParams = _adapterParams;
    }

    // --------------------- Internal Functions ---------------------
    // simulates the relayer pushing through the rest of the msgs that got delayed due to the stored payload
    function _clearMsgQue(uint16 _srcChainId, bytes calldata _path) internal {
        QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_path];

        // warning, might run into gas issues trying to forward through a bunch of queued msgs
        while (msgs.length > 0) {
            QueuedPayload memory payload = msgs[msgs.length - 1];
            ILayerZeroReceiver(payload.dstAddress).lzReceive(
                _srcChainId,
                _path,
                payload.nonce,
                payload.payload
            );
            msgs.pop();
        }
    }

    function _getProtocolFees(
        bool _payInZro,
        uint256 _relayerFee,
        uint256 _oracleFee
    ) internal view returns (uint256) {
        if (_payInZro) {
            return protocolFeeConfig.zroFee;
        } else {
            return
                ((_relayerFee + _oracleFee) * protocolFeeConfig.nativeBP) /
                10000;
        }
    }

    function _getRelayerFee(
        uint16, /* _dstChainId */
        uint16, /* _outboundProofType */
        address, /* _userApplication */
        uint256 _payloadSize,
        bytes memory _adapterParams
    ) internal view returns (uint256) {
        (uint16 txType, uint256 extraGas, uint256 dstNativeAmt, ) = LzLib
            .decodeAdapterParams(_adapterParams);
        uint256 totalRemoteToken; // = baseGas + extraGas + requiredNativeAmount
        if (txType == 2) {
            require(
                relayerFeeConfig.dstNativeAmtCap >= dstNativeAmt,
                "LayerZeroMock: dstNativeAmt too large "
            );
            totalRemoteToken += dstNativeAmt;
        }
        // remoteGasTotal = dstGasPriceInWei * (baseGas + extraGas)
        uint256 remoteGasTotal = relayerFeeConfig.dstGasPriceInWei *
            (relayerFeeConfig.baseGas + extraGas);
        totalRemoteToken += remoteGasTotal;

        // tokenConversionRate = dstPrice / localPrice
        // basePrice = totalRemoteToken * tokenConversionRate
        uint256 basePrice = (totalRemoteToken *
            relayerFeeConfig.dstPriceRatio) / 10**10;

        // pricePerByte = (dstGasPriceInWei * gasPerBytes) * tokenConversionRate
        uint256 pricePerByte = (relayerFeeConfig.dstGasPriceInWei *
            relayerFeeConfig.gasPerByte *
            relayerFeeConfig.dstPriceRatio) / 10**10;

        return basePrice + _payloadSize * pricePerByte;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import "../../src/interfaces/LaunchpegInterfaces/IBaseLaunchpeg.sol";
import "../../src/interfaces/LaunchpegInterfaces/IBaseLaunchpegV1.sol";
import "../../src/interfaces/LaunchpegInterfaces/IBatchRevealv2.sol";
import "../../src/interfaces/LaunchpegInterfaces/IFlatLaunchpeg.sol";
import "../../src/interfaces/LaunchpegInterfaces/ILaunchpeg.sol";
import "../../src/interfaces/LaunchpegInterfaces/ILaunchpegFactory.sol";

error LaunchpegLens__InvalidContract();
error LaunchpegLens__InvalidLaunchpegType();
error LaunchpegLens__InvalidLaunchpegVersion();

/// @title Launchpeg Lens
/// @author Trader Joe
/// @notice Helper contract to fetch launchpegs data
contract LaunchpegLens {
    struct CollectionData {
        string name;
        string symbol;
        uint256 collectionSize;
        uint256 maxPerAddressDuringMint;
        uint256 totalSupply;
        string unrevealedURI;
        string baseURI;
    }

    struct LaunchpegData {
        ILaunchpeg.Phase currentPhase;
        uint256 amountForAuction;
        uint256 amountForAllowlist;
        uint256 amountForDevs;
        uint256 auctionSaleStartTime;
        uint256 preMintStartTime;
        uint256 allowlistStartTime;
        uint256 publicSaleStartTime;
        uint256 publicSaleEndTime;
        uint256 auctionStartPrice;
        uint256 auctionEndPrice;
        uint256 auctionSaleDuration;
        uint256 auctionDropInterval;
        uint256 auctionDropPerStep;
        uint256 allowlistDiscountPercent;
        uint256 publicSaleDiscountPercent;
        uint256 auctionPrice;
        uint256 allowlistPrice;
        uint256 publicSalePrice;
        uint256 lastAuctionPrice;
        uint256 amountMintedDuringAuction;
        uint256 amountMintedDuringPreMint;
        uint256 amountClaimedDuringPreMint;
        uint256 amountMintedDuringAllowlist;
        uint256 amountMintedDuringPublicSale;
    }

    struct FlatLaunchpegData {
        ILaunchpeg.Phase currentPhase;
        uint256 amountForAllowlist;
        uint256 amountForDevs;
        uint256 preMintStartTime;
        uint256 allowlistStartTime;
        uint256 publicSaleStartTime;
        uint256 publicSaleEndTime;
        uint256 allowlistPrice;
        uint256 salePrice;
        uint256 amountMintedDuringPreMint;
        uint256 amountClaimedDuringPreMint;
        uint256 amountMintedDuringAllowlist;
        uint256 amountMintedDuringPublicSale;
    }

    struct RevealData {
        uint256 revealBatchSize;
        uint256 lastTokenRevealed;
        uint256 revealStartTime;
        uint256 revealInterval;
    }

    struct UserData {
        uint256 balanceOf;
        uint256 numberMinted;
        uint256 numberMintedWithPreMint;
        uint256 allowanceForAllowlistMint;
    }

    struct ProjectOwnerData {
        address[] projectOwners;
        uint256 amountMintedByDevs;
        uint256 withdrawAVAXStartTime;
        uint256 launchpegBalanceAVAX;
    }

    /// Global struct that is returned by getAllLaunchpegs()
    struct LensData {
        address id;
        LaunchpegType launchType;
        CollectionData collectionData;
        LaunchpegData launchpegData;
        FlatLaunchpegData flatLaunchpegData;
        RevealData revealData;
        UserData userData;
        ProjectOwnerData projectOwnerData;
    }

    enum LaunchpegType {
        Unknown,
        Launchpeg,
        FlatLaunchpeg
    }

    enum LaunchpegVersion {
        Unknown,
        V1,
        V2
    }

    /// @notice LaunchpegFactory V1
    ILaunchpegFactory public immutable launchpegFactoryV1;

    /// @notice LaunchpegFactory V2
    ILaunchpegFactory public immutable launchpegFactoryV2;

    /// @notice BatchReveal address
    address public immutable batchReveal;

    /// @dev LaunchpegLens constructor
    /// @param _launchpegFactoryV1 LaunchpegFactory V1
    /// @param _launchpegFactoryV2 LaunchpegFactory V2
    /// @param _batchReveal BatchReveal address
    constructor(ILaunchpegFactory _launchpegFactoryV1, ILaunchpegFactory _launchpegFactoryV2, address _batchReveal) {
        launchpegFactoryV1 = _launchpegFactoryV1;
        launchpegFactoryV2 = _launchpegFactoryV2;
        batchReveal = _batchReveal;
    }

    /// @notice Gets the type and version of Launchpeg
    /// @param _contract Contract address to consider
    /// @return LaunchpegType Type of Launchpeg implementation (Dutch Auction / Flat / Unknown)
    function getLaunchpegType(address _contract) public view returns (LaunchpegType, LaunchpegVersion) {
        if (launchpegFactoryV1.isLaunchpeg(0, _contract)) {
            return (LaunchpegType.Launchpeg, LaunchpegVersion.V1);
        } else if (launchpegFactoryV2.isLaunchpeg(0, _contract)) {
            return (LaunchpegType.Launchpeg, LaunchpegVersion.V2);
        } else if (launchpegFactoryV1.isLaunchpeg(1, _contract)) {
            return (LaunchpegType.FlatLaunchpeg, LaunchpegVersion.V1);
        } else if (launchpegFactoryV2.isLaunchpeg(1, _contract)) {
            return (LaunchpegType.FlatLaunchpeg, LaunchpegVersion.V2);
        } else {
            return (LaunchpegType.Unknown, LaunchpegVersion.Unknown);
        }
    }

    /// @notice Fetch Launchpeg data by type and version
    /// @param _type Type of Launchpeg to consider
    /// @param _version Launchpeg version
    /// @param _number Number of Launchpeg to fetch
    /// @param _limit Last Launchpeg index to fetch
    /// @param _user Address to consider for NFT balances and allowlist allocations
    /// @return LensDataList List of contracts datas, in descending order
    function getLaunchpegsByTypeAndVersion(
        LaunchpegType _type,
        LaunchpegVersion _version,
        uint256 _number,
        uint256 _limit,
        address _user
    ) external view returns (LensData[] memory) {
        if (_type == LaunchpegType.Unknown) {
            revert LaunchpegLens__InvalidLaunchpegType();
        }
        if (_version == LaunchpegVersion.Unknown) {
            revert LaunchpegLens__InvalidLaunchpegVersion();
        }
        // default to v2 unless v1 is specified
        ILaunchpegFactory factory = (_version == LaunchpegVersion.V1) ? launchpegFactoryV1 : launchpegFactoryV2;
        // 0 - Launchpeg, 1 - FlatLaunchpeg
        uint256 lpTypeIdx = uint8(_type) - 1;
        uint256 numLaunchpegs = factory.numLaunchpegs(lpTypeIdx);

        uint256 end = _limit > numLaunchpegs ? numLaunchpegs : _limit;
        uint256 start = _number > end ? 0 : end - _number;

        LensData[] memory LensDatas;
        LensDatas = new LensData[](end - start);

        for (uint256 i = 0; i < LensDatas.length; i++) {
            LensDatas[i] = getLaunchpegData(factory.allLaunchpegs(lpTypeIdx, end - 1 - i), _user);
        }

        return LensDatas;
    }

    /// @notice Fetch Launchpeg data from the provided address
    /// @param _launchpeg Contract address to consider
    /// @param _user Address to consider for NFT balances and allowlist allocations
    /// @return LensData Contract data
    function getLaunchpegData(address _launchpeg, address _user) public view returns (LensData memory) {
        (LaunchpegType launchType, LaunchpegVersion launchVersion) = getLaunchpegType(_launchpeg);
        if (launchType == LaunchpegType.Unknown) {
            revert LaunchpegLens__InvalidContract();
        }

        LensData memory data;
        data.id = _launchpeg;
        data.launchType = launchType;
        data.collectionData = _getCollectionData(_launchpeg);
        data.projectOwnerData = _getProjectOwnerData(_launchpeg, launchVersion);
        data.revealData = _getBatchRevealData(_launchpeg, launchVersion);
        data.userData = _getUserData(_launchpeg, launchVersion, _user);

        if (data.launchType == LaunchpegType.Launchpeg) {
            data.launchpegData = _getLaunchpegData(_launchpeg, launchVersion);
        } else if (data.launchType == LaunchpegType.FlatLaunchpeg) {
            data.flatLaunchpegData = _getFlatLaunchpegData(_launchpeg, launchVersion);
        }

        return data;
    }

    /// @dev Fetches Launchpeg collection data
    /// @param _launchpeg Launchpeg address
    function _getCollectionData(address _launchpeg) private view returns (CollectionData memory data) {
        data.name = ERC721AUpgradeable(_launchpeg).name();
        data.symbol = ERC721AUpgradeable(_launchpeg).symbol();
        data.collectionSize = IBaseLaunchpeg(_launchpeg).collectionSize();
        data.maxPerAddressDuringMint = IBaseLaunchpeg(_launchpeg).maxPerAddressDuringMint();
        data.totalSupply = ERC721AUpgradeable(_launchpeg).totalSupply();
        data.unrevealedURI = IBaseLaunchpeg(_launchpeg).unrevealedURI();
        data.baseURI = IBaseLaunchpeg(_launchpeg).baseURI();
    }

    /// @dev Fetches Launchpeg project owner data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getProjectOwnerData(address _launchpeg, LaunchpegVersion launchVersion)
        private
        view
        returns (ProjectOwnerData memory data)
    {
        data.amountMintedByDevs = IBaseLaunchpeg(_launchpeg).amountMintedByDevs();
        data.launchpegBalanceAVAX = _launchpeg.balance;
        if (launchVersion == LaunchpegVersion.V1) {
            address[] memory projectOwners = new address[](1);
            projectOwners[0] = IBaseLaunchpegV1(_launchpeg).projectOwner();
            data.projectOwners = projectOwners;
        } else if (launchVersion == LaunchpegVersion.V2) {
            data.projectOwners = _getProjectOwners(_launchpeg);
            data.withdrawAVAXStartTime = IBaseLaunchpeg(_launchpeg).withdrawAVAXStartTime();
        }
    }

    /// @dev Fetches Launchpeg project owners. Only works for Launchpeg V2.
    /// @param _launchpeg Launchpeg address
    function _getProjectOwners(address _launchpeg) private view returns (address[] memory) {
        bytes32 role = IBaseLaunchpeg(_launchpeg).PROJECT_OWNER_ROLE();
        uint256 count = IAccessControlEnumerableUpgradeable(_launchpeg).getRoleMemberCount(role);
        address[] memory projectOwners = new address[](count);
        for (uint256 i; i < count; i++) {
            projectOwners[i] = IAccessControlEnumerableUpgradeable(_launchpeg).getRoleMember(role, i);
        }
        return projectOwners;
    }

    /// @dev Fetches Launchpeg data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getLaunchpegData(address _launchpeg, LaunchpegVersion launchVersion)
        private
        view
        returns (LaunchpegData memory data)
    {
        ILaunchpeg lp = ILaunchpeg(_launchpeg);
        data.currentPhase = lp.currentPhase();
        data.amountForAuction = lp.amountForAuction();
        data.amountForAllowlist = lp.amountForAllowlist();
        data.amountForDevs = lp.amountForDevs();
        data.auctionSaleStartTime = lp.auctionSaleStartTime();
        data.allowlistStartTime = lp.allowlistStartTime();
        data.publicSaleStartTime = lp.publicSaleStartTime();
        data.auctionStartPrice = lp.auctionStartPrice();
        data.auctionEndPrice = lp.auctionEndPrice();
        data.auctionSaleDuration = lp.auctionSaleDuration();
        data.auctionDropInterval = lp.auctionDropInterval();
        data.auctionDropPerStep = lp.auctionDropPerStep();
        data.allowlistDiscountPercent = lp.allowlistDiscountPercent();
        data.publicSaleDiscountPercent = lp.publicSaleDiscountPercent();
        data.auctionPrice = lp.getAuctionPrice(data.auctionSaleStartTime);
        data.lastAuctionPrice = lp.lastAuctionPrice();
        data.amountMintedDuringAuction = lp.amountMintedDuringAuction();
        data.amountMintedDuringAllowlist = lp.amountMintedDuringAllowlist();
        data.amountMintedDuringPublicSale = lp.amountMintedDuringPublicSale();
        if (launchVersion == LaunchpegVersion.V1) {
            data.allowlistPrice = IBaseLaunchpegV1(_launchpeg).getAllowlistPrice();
            data.publicSalePrice = IBaseLaunchpegV1(_launchpeg).getPublicSalePrice();
        } else if (launchVersion == LaunchpegVersion.V2) {
            data.allowlistPrice = lp.allowlistPrice();
            data.publicSalePrice = lp.salePrice();
            data.preMintStartTime = lp.preMintStartTime();
            data.publicSaleEndTime = lp.publicSaleEndTime();
            data.amountMintedDuringPreMint = lp.amountMintedDuringPreMint();
            data.amountClaimedDuringPreMint = lp.amountClaimedDuringPreMint();
        }
    }

    /// @dev Fetches FlatLaunchpeg data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getFlatLaunchpegData(address _launchpeg, LaunchpegVersion launchVersion)
        private
        view
        returns (FlatLaunchpegData memory data)
    {
        IFlatLaunchpeg lp = IFlatLaunchpeg(_launchpeg);
        data.currentPhase = lp.currentPhase();
        data.amountForAllowlist = lp.amountForAllowlist();
        data.amountForDevs = lp.amountForDevs();
        data.allowlistStartTime = lp.allowlistStartTime();
        data.publicSaleStartTime = lp.publicSaleStartTime();
        data.allowlistPrice = lp.allowlistPrice();
        data.salePrice = lp.salePrice();
        data.amountMintedDuringAllowlist = lp.amountMintedDuringAllowlist();
        data.amountMintedDuringPublicSale = lp.amountMintedDuringPublicSale();
        if (launchVersion == LaunchpegVersion.V2) {
            data.preMintStartTime = lp.preMintStartTime();
            data.publicSaleEndTime = lp.publicSaleEndTime();
            data.amountMintedDuringPreMint = lp.amountMintedDuringPreMint();
            data.amountClaimedDuringPreMint = lp.amountClaimedDuringPreMint();
        }
    }

    /// @dev Fetches batch reveal data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getBatchRevealData(address _launchpeg, LaunchpegVersion launchVersion)
        private
        view
        returns (RevealData memory data)
    {
        if (launchVersion == LaunchpegVersion.V1) {
            IBaseLaunchpegV1 br = IBaseLaunchpegV1(_launchpeg);
            data.revealBatchSize = br.revealBatchSize();
            data.revealStartTime = br.revealStartTime();
            data.revealInterval = br.revealInterval();
            data.lastTokenRevealed = br.lastTokenRevealed();
        } else if (launchVersion == LaunchpegVersion.V2) {
            (,, uint256 revealBatchSize, uint256 revealStartTime, uint256 revealInterval) =
                IBatchRevealv2(batchReveal).launchpegToConfig(_launchpeg);
            data.revealBatchSize = revealBatchSize;
            data.revealStartTime = revealStartTime;
            data.revealInterval = revealInterval;
            data.lastTokenRevealed = IBatchRevealv2(batchReveal).launchpegToLastTokenReveal(_launchpeg);
        }
    }

    /// @dev Fetches Launchpeg user data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getUserData(address _launchpeg, LaunchpegVersion launchVersion, address _user)
        private
        view
        returns (UserData memory data)
    {
        if (_user != address(0)) {
            data.balanceOf = ERC721AUpgradeable(_launchpeg).balanceOf(_user);
            data.numberMinted = IBaseLaunchpeg(_launchpeg).numberMinted(_user);
            data.allowanceForAllowlistMint = IBaseLaunchpeg(_launchpeg).allowlist(_user);
            if (launchVersion == LaunchpegVersion.V2) {
                data.numberMintedWithPreMint = IBaseLaunchpeg(_launchpeg).numberMintedWithPreMint(_user);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// A mock for testing code that relies on VRFCoordinatorV2.
pragma solidity ^0.8.4;

import "src/interfaces/LinkTokenInterface.sol";
import "src/interfaces/VRFCoordinatorV2Interface.sol";
import "src/chainlink/VRFConsumerBaseV2.sol";

contract VRFCoordinatorV2Mock is VRFCoordinatorV2Interface {
    uint96 public immutable BASE_FEE;
    uint96 public immutable GAS_PRICE_LINK;
    uint16 public immutable MAX_CONSUMERS = 100;

    error InvalidSubscription();
    error InsufficientBalance();
    error MustBeSubOwner(address owner);
    error TooManyConsumers();
    error InvalidConsumer();
    error InvalidRandomWords();

    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );
    event RandomWordsFulfilled(uint256 indexed requestId, uint256 outputSeed, uint96 payment, bool success);
    event SubscriptionCreated(uint64 indexed subId, address owner);
    event SubscriptionFunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);
    event SubscriptionCanceled(uint64 indexed subId, address to, uint256 amount);
    event ConsumerAdded(uint64 indexed subId, address consumer);
    event ConsumerRemoved(uint64 indexed subId, address consumer);

    uint64 s_currentSubId;
    uint256 s_nextRequestId = 1;
    uint256 s_nextPreSeed = 100;

    struct Subscription {
        address owner;
        uint96 balance;
    }

    mapping(uint64 => Subscription) s_subscriptions; /* subId */ /* subscription */
    mapping(uint64 => address[]) s_consumers; /* subId */ /* consumers */

    struct Request {
        uint64 subId;
        uint32 callbackGasLimit;
        uint32 numWords;
    }

    mapping(uint256 => Request) s_requests; /* requestId */ /* request */

    constructor(uint96 _baseFee, uint96 _gasPriceLink) {
        BASE_FEE = _baseFee;
        GAS_PRICE_LINK = _gasPriceLink;
    }

    function consumerIsAdded(uint64 _subId, address _consumer) public view returns (bool) {
        address[] memory consumers = s_consumers[_subId];
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == _consumer) {
                return true;
            }
        }
        return false;
    }

    modifier onlyValidConsumer(uint64 _subId, address _consumer) {
        if (!consumerIsAdded(_subId, _consumer)) {
            revert InvalidConsumer();
        }
        _;
    }

    /**
     * @notice fulfillRandomWords fulfills the given request, sending the random words to the supplied
     * @notice consumer.
     *
     * @dev This mock uses a simplified formula for calculating payment amount and gas usage, and does
     * @dev not account for all edge cases handled in the real VRF coordinator. When making requests
     * @dev against the real coordinator a small amount of additional LINK is required.
     *
     * @param _requestId the request to fulfill
     * @param _consumer the VRF randomness consumer to send the result to
     */
    function fulfillRandomWords(uint256 _requestId, address _consumer) external {
        fulfillRandomWordsWithOverride(_requestId, _consumer, new uint256[](0));
    }

    /**
     * @notice fulfillRandomWordsWithOverride allows the user to pass in their own random words.
     *
     * @param _requestId the request to fulfill
     * @param _consumer the VRF randomness consumer to send the result to
     * @param _words user-provided random words
     */
    function fulfillRandomWordsWithOverride(uint256 _requestId, address _consumer, uint256[] memory _words) public {
        uint256 startGas = gasleft();
        if (s_requests[_requestId].subId == 0) {
            revert("nonexistent request");
        }
        Request memory req = s_requests[_requestId];

        if (_words.length == 0) {
            _words = new uint256[](req.numWords);
            for (uint256 i = 0; i < req.numWords; i++) {
                _words[i] = uint256(keccak256(abi.encode(_requestId, i)));
            }
        } else if (_words.length != req.numWords) {
            revert InvalidRandomWords();
        }

        VRFConsumerBaseV2 v;
        bytes memory callReq = abi.encodeWithSelector(v.rawFulfillRandomWords.selector, _requestId, _words);
        (bool success,) = _consumer.call{gas: req.callbackGasLimit}(callReq);

        uint96 payment = uint96(BASE_FEE + ((startGas - gasleft()) * GAS_PRICE_LINK));
        if (s_subscriptions[req.subId].balance < payment) {
            revert InsufficientBalance();
        }
        s_subscriptions[req.subId].balance -= payment;
        delete (s_requests[_requestId]);
        emit RandomWordsFulfilled(_requestId, _requestId, payment, success);
    }

    /**
     * @notice fundSubscription allows funding a subscription with an arbitrary amount for testing.
     *
     * @param _subId the subscription to fund
     * @param _amount the amount to fund
     */
    function fundSubscription(uint64 _subId, uint96 _amount) public {
        if (s_subscriptions[_subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        uint96 oldBalance = s_subscriptions[_subId].balance;
        s_subscriptions[_subId].balance += _amount;
        emit SubscriptionFunded(_subId, oldBalance, oldBalance + _amount);
    }

    function requestRandomWords(
        bytes32 _keyHash,
        uint64 _subId,
        uint16 _minimumRequestConfirmations,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) external override onlyValidConsumer(_subId, msg.sender) returns (uint256) {
        if (s_subscriptions[_subId].owner == address(0)) {
            revert InvalidSubscription();
        }

        uint256 requestId = s_nextRequestId++;
        uint256 preSeed = s_nextPreSeed++;

        s_requests[requestId] = Request({subId: _subId, callbackGasLimit: _callbackGasLimit, numWords: _numWords});

        emit RandomWordsRequested(
            _keyHash, requestId, preSeed, _subId, _minimumRequestConfirmations, _callbackGasLimit, _numWords, msg.sender
            );
        return requestId;
    }

    function createSubscription() external override returns (uint64 _subId) {
        s_currentSubId++;
        s_subscriptions[s_currentSubId] = Subscription({owner: msg.sender, balance: 0});
        emit SubscriptionCreated(s_currentSubId, msg.sender);
        return s_currentSubId;
    }

    function getSubscription(uint64 _subId)
        external
        view
        override
        returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers)
    {
        if (s_subscriptions[_subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        return (s_subscriptions[_subId].balance, 0, s_subscriptions[_subId].owner, s_consumers[_subId]);
    }

    function cancelSubscription(uint64 _subId, address _to) external override onlySubOwner(_subId) {
        emit SubscriptionCanceled(_subId, _to, s_subscriptions[_subId].balance);
        delete (s_subscriptions[_subId]);
    }

    modifier onlySubOwner(uint64 _subId) {
        address owner = s_subscriptions[_subId].owner;
        if (owner == address(0)) {
            revert InvalidSubscription();
        }
        if (msg.sender != owner) {
            revert MustBeSubOwner(owner);
        }
        _;
    }

    function getRequestConfig() external pure override returns (uint16, uint32, bytes32[] memory) {
        bytes32[] memory keyhashes = new bytes32[](1);
        keyhashes[0] = bytes32(keccak256("keyhash"));
        return (3, 2000000, keyhashes);
    }

    function addConsumer(uint64 _subId, address _consumer) external override onlySubOwner(_subId) {
        if (s_consumers[_subId].length == MAX_CONSUMERS) {
            revert TooManyConsumers();
        }

        if (consumerIsAdded(_subId, _consumer)) {
            return;
        }

        s_consumers[_subId].push(_consumer);
        emit ConsumerAdded(_subId, _consumer);
    }

    function removeConsumer(uint64 _subId, address _consumer)
        external
        override
        onlySubOwner(_subId)
        onlyValidConsumer(_subId, _consumer)
    {
        address[] storage consumers = s_consumers[_subId];
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == _consumer) {
                address last = consumers[consumers.length - 1];
                consumers[i] = last;
                consumers.pop();
                break;
            }
        }

        emit ConsumerRemoved(_subId, _consumer);
    }

    function getConfig()
        external
        pure
        returns (
            uint16 minimumRequestConfirmations,
            uint32 maxGasLimit,
            uint32 stalenessSeconds,
            uint32 gasAfterPaymentCalculation
        )
    {
        return (4, 2_500_000, 2_700, 33285);
    }

    function getFeeConfig()
        external
        pure
        returns (
            uint32 fulfillmentFlatFeeLinkPPMTier1,
            uint32 fulfillmentFlatFeeLinkPPMTier2,
            uint32 fulfillmentFlatFeeLinkPPMTier3,
            uint32 fulfillmentFlatFeeLinkPPMTier4,
            uint32 fulfillmentFlatFeeLinkPPMTier5,
            uint24 reqsForTier2,
            uint24 reqsForTier3,
            uint24 reqsForTier4,
            uint24 reqsForTier5
        )
    {
        return (
            100000, // 0.1 LINK
            100000, // 0.1 LINK
            100000, // 0.1 LINK
            100000, // 0.1 LINK
            100000, // 0.1 LINK
            0,
            0,
            0,
            0
        );
    }

    function getFallbackWeiPerUnitLink() external pure returns (int256) {
        return 4000000000000000; // 0.004 Ether
    }

    function requestSubscriptionOwnerTransfer(uint64, address) external pure override {
        revert("not implemented");
    }

    function acceptSubscriptionOwnerTransfer(uint64) external pure override {
        revert("not implemented");
    }

    function pendingRequestExists(uint64) public pure override returns (bool) {
        revert("not implemented");
    }
}