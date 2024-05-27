import {PLUGIN_SETUP_CONTRACT_NAME} from '../../plugin-settings';
import buildMetadata from '../../src/build-metadata.json';
import {
  DAOMock,
  DAOMock__factory,
  SecurityBackstopSetup,
  SecurityBackstopSetup__factory,
  SecurityBackstop__factory,
} from '../../typechain';
import {EMERGENCY_SWITCH_PERMISSION_ID, defaultInitData} from './11_plugin';
import {
  DAO_PERMISSIONS,
  Operation,
  PERMISSION_MANAGER_FLAGS,
  getNamedTypesFromMetadata,
} from '@aragon/osx-commons-sdk';
import {loadFixture} from '@nomicfoundation/hardhat-network-helpers';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';
import {expect} from 'chai';
import {ethers} from 'hardhat';

type FixtureResult = {
  deployer: SignerWithAddress;
  alice: SignerWithAddress;
  bob: SignerWithAddress;
  pluginSetup: SecurityBackstopSetup;
  prepareInstallationInputs: string;
  prepareUninstallationInputs: string;
  daoMock: DAOMock;
};

async function fixture(): Promise<FixtureResult> {
  const [deployer, alice, bob] = await ethers.getSigners();
  const daoMock = await new DAOMock__factory(deployer).deploy();
  const pluginSetup = await new SecurityBackstopSetup__factory(
    deployer
  ).deploy();

  const prepareInstallationInputs = ethers.utils.defaultAbiCoder.encode(
    getNamedTypesFromMetadata(
      buildMetadata.pluginSetup.prepareInstallation.inputs
    ),
    [defaultInitData.protocol, defaultInitData.switchController]
  );

  const prepareUninstallationInputs = ethers.utils.defaultAbiCoder.encode(
    getNamedTypesFromMetadata(
      buildMetadata.pluginSetup.prepareUninstallation.inputs
    ),
    []
  );

  return {
    deployer,
    alice,
    bob,
    pluginSetup,
    prepareInstallationInputs,
    prepareUninstallationInputs,
    daoMock,
  };
}

describe(PLUGIN_SETUP_CONTRACT_NAME, function () {
  describe('prepareInstallation', async () => {
    it('returns the plugin, helpers, and permissions', async () => {
      const {deployer, pluginSetup, prepareInstallationInputs, daoMock} =
        await loadFixture(fixture);

      const nonce = await ethers.provider.getTransactionCount(
        pluginSetup.address
      );
      const anticipatedPluginAddress = ethers.utils.getContractAddress({
        from: pluginSetup.address,
        nonce,
      });

      const {
        plugin,
        preparedSetupData: {helpers, permissions},
      } = await pluginSetup.callStatic.prepareInstallation(
        daoMock.address,
        prepareInstallationInputs
      );

      expect(plugin).to.be.equal(anticipatedPluginAddress);
      expect(helpers.length).to.be.equal(0);
      expect(permissions.length).to.be.equal(2);
      expect(permissions).to.deep.equal([
        [
          Operation.Grant,
          daoMock.address,
          plugin,
          PERMISSION_MANAGER_FLAGS.NO_CONDITION,
          DAO_PERMISSIONS.EXECUTE_PERMISSION_ID,
        ],
        [
          Operation.Grant,
          plugin,
          defaultInitData.switchController,
          PERMISSION_MANAGER_FLAGS.NO_CONDITION,
          EMERGENCY_SWITCH_PERMISSION_ID,
        ],
      ]);

      await pluginSetup.prepareInstallation(
        daoMock.address,
        prepareInstallationInputs
      );
      const SecurityBackstop = new SecurityBackstop__factory(deployer).attach(
        plugin
      );

      // initialization is correct
      expect(await SecurityBackstop.dao()).to.eq(daoMock.address);
    });
  });

  describe('prepareUninstallation', async () => {
    it('returns the permissions', async () => {
      const {pluginSetup, daoMock, prepareUninstallationInputs} =
        await loadFixture(fixture);

      const dummyAddr = ethers.constants.AddressZero;

      const permissions = await pluginSetup.callStatic.prepareUninstallation(
        daoMock.address,
        {
          plugin: dummyAddr,
          currentHelpers: [],
          data: prepareUninstallationInputs,
        }
      );

      expect(permissions.length).to.be.equal(1);
      expect(permissions).to.deep.equal([
        [
          Operation.Revoke,
          daoMock.address,
          dummyAddr,
          PERMISSION_MANAGER_FLAGS.NO_CONDITION,
          DAO_PERMISSIONS.EXECUTE_PERMISSION_ID,
        ],
      ]);
    });
  });
});
