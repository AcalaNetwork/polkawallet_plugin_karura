export class AmountBelowMinimumThreshold extends Error {
  constructor() {
    super();

    this.message = "Amount Below Minimum Threshold";
    this.name = "AmountBelowMinimumThreshold";
  }
}

export class MintLimitReachedError extends Error {
  constructor() {
    super();

    this.message = "Reached The Mint Limit";
    this.name = "MintLimitReachedError";
  }
}

export class RedeemNotEnableError extends Error {
  constructor() {
    super();

    this.message = "Redeem is not enable";
    this.name = "RedeemNotEnableError";
  }
}
