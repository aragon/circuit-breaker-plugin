import '../../typechain/src/SecurityBackstop';
import {ethers} from 'hardhat';

export type InitData = {protocol: string; switchController: string};
export const defaultInitData: InitData = {
  protocol: ethers.constants.AddressZero,
  switchController: ethers.constants.AddressZero,
};

export const EMERGENCY_SWITCH_PERMISSION_ID = ethers.utils.id(
  'EMERGENCY_SWITCH_PERMISSION'
);
