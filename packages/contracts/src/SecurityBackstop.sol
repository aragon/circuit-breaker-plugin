// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

import {Plugin, IDAO} from "@aragon/osx-commons-contracts/src/plugin/Plugin.sol";

import {Web3Protocol, EMERGENCY_SWITCH_PERMISSION_ID} from "./Web3Protocol.sol";

/// @title SecurityBackstop
/// @notice Allows an address with the `EMERGENCY_SWITCH_PERMISSION_ID` permission to stop the protocol in an emergency.
/// @dev v1.1 (Release 1, Build 1)
contract SecurityBackstop is Plugin {
    Web3Protocol private immutable PROTOCOL;

    constructor(IDAO _dao, Web3Protocol _protocol) Plugin(_dao) {
        PROTOCOL = _protocol;
    }

    /// @notice Sets the emergency switch in the protocol in case of an emergency.
    /// @param _state Whether the emergency switch is on or off.
    /// @dev Requires the caller to have the `EMERGENCY_SWITCH_PERMISSION_ID` permission.
    function emergencySwitch(bool _state) external auth(EMERGENCY_SWITCH_PERMISSION_ID) {
        // Create the action to set the emergency switch state.
        IDAO.Action[] memory actions = new IDAO.Action[](1);
        actions[0] = IDAO.Action({
            to: address(PROTOCOL),
            data: abi.encodeCall(Web3Protocol.emergencySwitch, (_state)),
            value: 0 ether
        });

        // Execute the actions through the DAO executor.
        dao().execute({_callId: bytes32(block.timestamp), _actions: actions, _allowFailureMap: 0});
    }
}
