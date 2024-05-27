// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.8;

import {PermissionLib} from "@aragon/osx-commons-contracts/src/permission/PermissionLib.sol";
import {ProxyLib} from "@aragon/osx-commons-contracts/src/utils/deployment/ProxyLib.sol";
import {PluginSetup} from "@aragon/osx-commons-contracts/src/plugin/setup/PluginSetup.sol";
import {IPluginSetup} from "@aragon/osx-commons-contracts/src/plugin/setup/IPluginSetup.sol";
import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";

import {SecurityBackstop} from "./SecurityBackstop.sol";
import {Web3Protocol, EMERGENCY_SWITCH_PERMISSION_ID, EXECUTE_PERMISSION_ID} from "./Web3Protocol.sol";

/// @title SecurityBackstopSetup
/// @dev Release 1, Build 1
contract SecurityBackstopSetup is PluginSetup {
    using ProxyLib for address;

    /// @notice Constructs the `PluginSetup` by storing the `SecurityBackstop` implementation address.
    /// @dev The implementation address is used to verify the plugin on the respective block explorers.
    constructor()
        PluginSetup(address(new SecurityBackstop(IDAO(address(0)), Web3Protocol(address(0)))))
    {}

    /// @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes memory _data
    ) external returns (address plugin, PreparedSetupData memory preparedSetupData) {
        (Web3Protocol protocol, address switchController) = abi.decode(
            _data,
            (Web3Protocol, address)
        );

        plugin = address(new SecurityBackstop(IDAO(_dao), protocol));

        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](2);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: _dao,
            who: plugin,
            condition: PermissionLib.NO_CONDITION,
            permissionId: EXECUTE_PERMISSION_ID
        });

        permissions[1] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: switchController,
            condition: PermissionLib.NO_CONDITION,
            permissionId: EMERGENCY_SWITCH_PERMISSION_ID
        });

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    ) external pure returns (PermissionLib.MultiTargetPermission[] memory permissions) {
        permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _dao,
            who: _payload.plugin,
            condition: PermissionLib.NO_CONDITION,
            permissionId: EXECUTE_PERMISSION_ID
        });
    }
}
