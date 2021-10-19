import { FixedPointNumber as FN } from "@acala-network/sdk-core";

export function getExchangeRate(totalStaking: FN, totalLiquid: FN, defaultExchangeRate = FN.TEN) {
  if (totalStaking.isZero()) return defaultExchangeRate;

  try {
    return FN.fromRational(totalStaking, totalLiquid);
  } catch (e) {
    return defaultExchangeRate;
  }
}

export function convertLiquidToStaking(exchangeRate: FN, liquidAmount: FN) {
  return exchangeRate.mul(liquidAmount);
}

export function convertStakingToLiquid(exchangeRate: FN, stakingAmount: FN) {
  return stakingAmount.div(exchangeRate);
}
