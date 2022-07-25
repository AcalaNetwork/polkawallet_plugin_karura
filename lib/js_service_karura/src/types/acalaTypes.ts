export type IncentiveResult = {
  Dex: any;
  DexSaving: any;
  Loans: any;
};

export interface TaigaUserReward {
  tokens?: string[];
  cumulative?: string[];
  claimable?: string[];
}
