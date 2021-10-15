import { FixedPointNumber as FN } from "@acala-network/sdk-core";
import { SwapPromise } from "@acala-network/sdk-swap";
import { WalletPromise } from "@acala-network/sdk-wallet";

import { ApiPromise } from "@polkadot/api";
import { Option } from "@polkadot/types";
import { Balance, Permill } from "@polkadot/types/interfaces";
import { ITuple } from "@polkadot/types/types";

import { BaseHomaLite } from "./homaBase";
import { MintLimitReachedError, RedeemNotEnableError } from "./errors";
import { HomaLiteMintResult, HomaLiteRedeemResult, HomaLiteStorage } from "./types";
import { convertLiquidToStaking, convertStakingToLiquid } from "./utils";

export class HomaLite extends BaseHomaLite<ApiPromise> {
  public storage: HomaLiteStorage | undefined;

  constructor(api: ApiPromise, wallet: WalletPromise) {
    super(api, wallet);
  }

  private async updateStorage() {
    const data = await Promise.all([
      this.api.query.tokens.totalIssuance(this.constants.liquidToken.toChainData()),
      this.api.query.homaLite.totalStakingCurrency(),
      this.api.query.homaLite.stakingCurrencyMintCap(),
      this.isV1 ? "0" : this.api.query.homaLite.availableStakingBalance(),
      this.isV1 ? [] : this.api.query.homaLite.redeemRequests.entries(),
    ]);

    const mintGap = FN.fromInner(data[2].toString(), this.constants.stakingToken.decimal);
    const totalLiquiditeToken = FN.fromInner(data[0].toString(), this.constants.liquidToken.decimal);
    const totalStakingToken = FN.fromInner(data[1].toString(), this.constants.stakingToken.decimal);
    const availableStakingToken = FN.fromInner(data[3].toString(), this.constants.stakingToken.decimal);
    const originRedeemRequests = data[4];

    const redeemRequests = originRedeemRequests.map((item) => {
      const key = item[0].args[0];
      const data = (item[1] as unknown) as Option<ITuple<[Balance, Permill]>>;

      return {
        redeemer: key.toString(),
        amount: FN.fromInner(data.unwrapOrDefault()[0].toString(), this.constants.liquidToken.decimal),
        extraFee: FN.fromInner(data.unwrapOrDefault()[1].toString()),
      };
    });

    this.storage = {
      availableStakingToken,
      mintGap,
      redeemRequests,
      totalLiquiditeToken,
      totalStakingToken,
    };
  }

  public getExchangeRate(liquidBalance: FN, stakingBalance: FN) {
    let exchangeRate = FN.ZERO;

    if (liquidBalance.isZero() && stakingBalance.isZero()) {
      // FIXME: exchangeRate = this.constants.defaultExchangeRate;
      exchangeRate = FN.fromInner("5300000000000000", 12).div(new FN(531.4833, 12));
    } else {
      exchangeRate = liquidBalance.div(stakingBalance);
    }

    return exchangeRate;
  }

  private async mintV1(amount: FN): Promise<HomaLiteMintResult> {
    await this.updateStorage();

    if (!this.storage) {
      return {
        fee: this.constants.mintFee,
        received: FN.ZERO,
      };
    }
    const { mintGap, totalLiquiditeToken, totalStakingToken } = this.storage;

    const exchangeRate = this.getExchangeRate(totalLiquiditeToken, totalStakingToken);

    if (!exchangeRate || !amount || amount.isZero() || amount.isNaN()) {
      return {
        fee: this.constants.mintFee,
        received: FN.ZERO,
      };
    }

    if ((totalStakingToken || FN.ZERO).add(amount).gt(mintGap || FN.ZERO)) throw new MintLimitReachedError();

    let received = amount.minus(this.constants.mintFee).mul(exchangeRate);

    received = FN.ZERO.max(received.minus(received.mul(this.constants.maxRewardPerEra)));

    return {
      fee: this.constants.mintFee,
      received,
    };
  }

  private async mintV2(amount: FN): Promise<HomaLiteMintResult> {
    await this.updateStorage();

    if (!this.storage) {
      return {
        fee: this.constants.mintFee,
        received: FN.ZERO,
      };
    }

    const { redeemRequests, totalLiquiditeToken, totalStakingToken } = this.storage;
    const exchangeRate = this.getExchangeRate(totalLiquiditeToken, totalStakingToken);
    const _convertStakingToLiquid = (amt: FN) => convertStakingToLiquid(exchangeRate, amt);
    const _convertLiquidToStaking = (amt: FN) => convertLiquidToStaking(exchangeRate, amt);

    return this.calculateMintResult(_convertStakingToLiquid, _convertLiquidToStaking, redeemRequests, amount);
  }

  public mint(amount: FN) {
    if (this.isV1) {
      return this.mintV1(amount);
    }

    return this.mintV2(amount);
  }

  public async redeem(amount: FN, requestExtraFee = FN.ZERO): Promise<HomaLiteRedeemResult> {
    if (!this.isRedeemenable) throw new RedeemNotEnableError();

    await this.updateStorage();

    if (!this.storage) {
      return {
        fee: this.constants.mintFee,
        expected: FN.ZERO,
      };
    }

    const { availableStakingToken, totalLiquiditeToken, totalStakingToken } = this.storage;
    const exchangeRate = this.getExchangeRate(totalLiquiditeToken, totalStakingToken);
    const _convertStakingToLiquid = (amt: FN) => convertStakingToLiquid(exchangeRate, amt);
    const _convertLiquidToStaking = (amt: FN) => convertLiquidToStaking(exchangeRate, amt);

    return this.calculateRedeemResult(_convertStakingToLiquid, _convertLiquidToStaking, availableStakingToken, amount, requestExtraFee);
  }

  public async redeemFromDex(swap: SwapPromise, amount: FN, slippage?: FN): Promise<HomaLiteRedeemResult> {
    const { liquidToken, stakingToken } = this.constants;
    const _slippage = slippage || new FN(0.05 / 100);

    const result = await swap.swap([liquidToken, stakingToken], amount, "EXACT_INPUT");
    return {
      expected: result.output.balance.mul(FN.ONE.sub(_slippage)),
      fee: result.priceImpact.mul(result.output.balance),
    };
  }

  public getMaxStakingBalance() {
    return this.storage?.mintGap.minus(this.storage.totalStakingToken);
  }
}
