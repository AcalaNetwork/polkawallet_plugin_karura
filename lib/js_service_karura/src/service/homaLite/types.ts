import { FixedPointNumber as FN, Token } from "@acala-network/sdk-core";

export interface HomaLiteConstants {
  // The Currency for the Liquid asset
  liquidToken: Token;
  // The Currency for the Staking asset
  stakingToken: Token;

  defaultExchangeRate: FN;
  // the minimal amount of staing currency to locked
  minimumMintThreshold: FN;
  // the minimal amount of liquid currency to be redeemed
  minimumRedeemThreshold: FN;
  // the maximum rewards that are earned on the relaychain
  maxRewardPerEra: FN;
  // the fixed const of transaction fee of XCM transfers
  mintFee: FN;
  // equivalent to the loss of % staking reward from unbonding on the relaychain
  baseWithdrawFee: FN;
  // the fixed const of withdrawing staking currency via redeem. In staking currency
  xcmUnbondFee: FN;
  // the maximum number of redeem requests to match in 'Mint' extrnsisc
  maximumRedeemRequestMatchesForMint: number;
  // maximum number of scheduled unbonds allowed
  maxScheduleUnbonds: number;
}

export interface RedeemRequest {
  redeemer: string;
  amount: FN;
  extraFee: FN;
}

export type ConvertStakingToLiquid = (amount: FN) => FN;

export type ConvertLiquidToStaking = (amount: FN) => FN;

export type GetExchangeRate = () => FN;

export interface HomaLiteMintResult {
  suggestRedeemRequests?: string[];
  received: FN;
  fee: FN;
}

export interface HomaLiteRedeemResult {
  newRedeemBalance?: FN;
  expected: FN;
  fee: FN;
}

export interface HomaLiteStorage {
  totalLiquiditeToken: FN;
  totalStakingToken: FN;
  mintGap: FN;
  availableStakingToken: FN;
  redeemRequests: RedeemRequest[];
}
