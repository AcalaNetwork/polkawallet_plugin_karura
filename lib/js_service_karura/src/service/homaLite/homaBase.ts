import { FixedPointNumber as FN } from "@acala-network/sdk-core";
import { WalletBase } from "@acala-network/sdk-wallet/wallet-base";

import { ApiPromise, ApiRx } from "@polkadot/api";

import { AmountBelowMinimumThreshold } from "./errors";
import {
  ConvertLiquidToStaking,
  ConvertStakingToLiquid,
  HomaLiteConstants,
  HomaLiteMintResult,
  HomaLiteRedeemResult,
  RedeemRequest,
} from "./types";

export abstract class BaseHomaLite<Api extends ApiPromise | ApiRx> {
  protected api: Api;
  protected wallet: WalletBase<Api>;
  public constants: HomaLiteConstants;

  constructor(api: Api, wallet: WalletBase<Api>) {
    this.api = api;
    this.wallet = wallet;

    this.constants = this.getConstants();
  }

  private getConstants() {
    const consts = this.api.consts.homaLite;

    const liquidToken = this.wallet.getToken(consts.liquidCurrencyId);
    const stakingToken = this.wallet.getToken(consts.stakingCurrencyId);

    const defaultExchangeRate = FN.fromInner(consts.defaultExchangeRate?.toString() || 0);
    const minimumMintThreshold = FN.fromInner(consts.minimumMintThreshold?.toString() || 0, stakingToken.decimal);
    const minimumRedeemThreshold = FN.fromInner(consts.minimumRedeemThreshold?.toString() || 0, liquidToken.decimal);
    const maxRewardPerEra = FN.fromInner(consts.maxRewardPerEra?.toString() || 0, 6);
    const mintFee = FN.fromInner(consts.mintFee?.toString() || 0, stakingToken.decimal);
    const xcmUnbondFee = FN.fromInner(consts.xcmUnbondFee?.toString() || 0, stakingToken.decimal);
    const baseWithdrawFee = FN.fromInner(consts.baseWithdrawFee?.toString() || 0, stakingToken.decimal);
    const maximumRedeemRequestMatchesForMint = Number(consts.maximumRedeemRequestMatchesForMint?.toString() || 0);
    const maxScheduleUnbonds = Number(consts.maxScheduledUnbonds?.toString() || 0);

    return {
      liquidToken,
      stakingToken,
      defaultExchangeRate,
      minimumMintThreshold,
      minimumRedeemThreshold,
      maxRewardPerEra,
      mintFee,
      xcmUnbondFee,
      baseWithdrawFee,
      maximumRedeemRequestMatchesForMint,
      maxScheduleUnbonds,
    };
  }

  get isRedeemenable() {
    return !!this.api.query.homaLite.availableStakingBalance;
  }

  get minMint() {
    return this.constants.mintFee.add(this.constants.minimumMintThreshold);
  }

  protected get isV1() {
    return !this.api.query.homaLite.availableStakingBalance;
  }

  /**
   * @name calculateMintResultFromRedeemRequests
   * @param redeemRequests the redeem requests storage data
   * @param targetAmount the target amount of liquid token
   * @returns [FixedPointNumber, FixedPointNumber] [actural minted amount, remaining need mint]
   */
  protected calculateMintResultFromRedeemRequests(redeemRequests: RedeemRequest[], targetAmount: FN): [FN, FN] {
    const totalAmountInRedeemRequests = redeemRequests.reduce((acc, cur) => acc.add(cur.amount), FN.ZERO);

    if (targetAmount.lte(totalAmountInRedeemRequests)) {
      return [targetAmount, FN.ZERO];
    }

    return [totalAmountInRedeemRequests, targetAmount.sub(totalAmountInRedeemRequests).max(FN.ZERO)];
  }

  protected calculateMintResult(
    convertStakingToLiquid: ConvertStakingToLiquid,
    convertLiquidToStaking: ConvertLiquidToStaking,
    redeemRequests: RedeemRequest[],
    amount: FN
  ): HomaLiteMintResult {
    let possibleFee = FN.ZERO;

    const { maxRewardPerEra, mintFee } = this.constants;

    if (amount.lte(this.minMint)) throw new AmountBelowMinimumThreshold();

    const totalLiquidToMint = convertStakingToLiquid(amount);

    let [mintedAmount, remainingAmount] = this.calculateMintResultFromRedeemRequests(redeemRequests, totalLiquidToMint);

    const stakingRemaining = convertLiquidToStaking(remainingAmount);

    if (stakingRemaining.gt(this.minMint)) {
      // // liquid_to_mint = convert_to_liquid( (staked_amount - MintFee) * (1 - MaxRewardPerEra) )
      let liquidToMint = stakingRemaining.sub(mintFee);

      liquidToMint = FN.ONE.sub(maxRewardPerEra).mul(liquidToMint);

      liquidToMint = convertLiquidToStaking(liquidToMint);

      mintedAmount = mintedAmount.add(liquidToMint);
      possibleFee = mintFee;
    }

    return {
      received: mintedAmount,
      fee: possibleFee,
    };
  }

  protected calculateRedeemResult(
    convertStakingToLiquid: ConvertStakingToLiquid,
    convertLiquidToStaking: ConvertLiquidToStaking,
    availableStakingBalance: FN,
    amount: FN,
    requestExtraFee: FN
  ): HomaLiteRedeemResult {
    let fee = FN.ZERO;
    let expected = FN.ZERO;

    const { baseWithdrawFee, minimumRedeemThreshold, xcmUnbondFee } = this.constants;

    if (amount.lte(minimumRedeemThreshold)) throw new AmountBelowMinimumThreshold();

    const actualLiquidAmount = amount.min(convertStakingToLiquid(availableStakingBalance));

    let liquidRemaining = amount.clone();

    if (convertLiquidToStaking(actualLiquidAmount).gt(xcmUnbondFee)) {
      const actualStakingAmount = convertLiquidToStaking(actualLiquidAmount);

      expected = expected.add(actualStakingAmount).minus(xcmUnbondFee);
      fee = fee.add(xcmUnbondFee);
      liquidRemaining = liquidRemaining.sub(actualLiquidAmount);
    }

    if (liquidRemaining.gt(minimumRedeemThreshold)) {
      // insert to redeem requests
      const feeDeductedPercentage = FN.ONE.sub(baseWithdrawFee).sub(requestExtraFee);

      // if redeem from mint process
      const stakingAmountFromMint = feeDeductedPercentage.mul(convertLiquidToStaking(liquidRemaining));
      const feeFromMint = FN.ONE.sub(feeDeductedPercentage).mul(convertLiquidToStaking(liquidRemaining));

      // if redeem from schedule unbond process
      const stakingAmountFromSchedule = convertLiquidToStaking(liquidRemaining).sub(xcmUnbondFee);
      const feeFromSchedule = xcmUnbondFee;

      // choose the min expected amount
      expected = expected.add(stakingAmountFromMint.min(stakingAmountFromSchedule));
      fee = fee.add(feeFromMint.min(feeFromSchedule));
    }

    return {
      expected,
      fee,
    };
  }
}
