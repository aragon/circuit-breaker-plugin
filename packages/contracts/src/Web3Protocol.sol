// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

bytes32 constant EXECUTE_PERMISSION_ID = keccak256("EXECUTE_PERMISSION");
bytes32 constant EMERGENCY_SWITCH_PERMISSION_ID = keccak256("EMERGENCY_SWITCH_PERMISSION");

contract Web3Protocol {
    function emergencySwitch(
        bool _state // solhint-disable-next-line no-empty-blocks
    ) external {}
}
