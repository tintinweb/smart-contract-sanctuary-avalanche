/**
 *Submitted for verification at snowtrace.io on 2023-04-01
*/

// spdx-license-identifier: UNLICENSED
pragma solidity 0.8.18;

contract EmergencyTriggerContract {
    bytes32 private constant EMERGENCY_HASH = keccak256(bytes("EMERGENCY"));
    address public constant owner = 0x05cF59dd28EAEf2Aa18A461BF4C4973fD06C2e3C;
    address public constant emergencyCoordinator1 = 0xF312197F0f39ae4EF067adf962A453cCC153F54e;
    address public constant emergencyCoordinator2 = 0x8162Cbd5902BCCca3bb882FC1B30f3138Dd108f5;
    bool public emergencyActivated = false;
    bool public triggerEmergency = false;

    event EmergencyActivated(address);

    modifier onlyOwner() {
        require(tx.origin == owner, "You are not the owner");
        _;
    }

    modifier onlyEmergencyCoordinator() {
        require(
            (tx.origin == emergencyCoordinator1) || (tx.origin == emergencyCoordinator2), 
            "You are not an authorized emergency coordinator"
        );
        _;
    }

    modifier notInEmergency() {
        require(emergencyActivated == false, "Emergency already activated");
        _;
    }

    function checkTriggeringRule(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded)
    {
        if (keccak256(checkData) == EMERGENCY_HASH) {
            return !emergencyActivated && triggerEmergency;
        }
        return false;
    }

    function panic() external payable notInEmergency onlyEmergencyCoordinator {
        emergencyActivated = true;
        triggerEmergency = false;
        emit EmergencyActivated(msg.sender);
    }

    function reset() external onlyOwner {
        emergencyActivated = false;
        triggerEmergency = false;
    }

    function setMustPanic(bool _triggerEmergency) external onlyOwner {
        triggerEmergency = _triggerEmergency;
    }
}