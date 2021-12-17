import { FixedPointNumber, Token, createLPCurrencyName, forceToCurrencyIdName } from "@acala-network/sdk-core";
import { SwapPromise } from "@acala-network/sdk-swap";
import { ApiPromise } from "@polkadot/api";
import { hexToString } from "@polkadot/util";
import { existential_deposit, nft_image_config } from "../constants/acala";
import { BN } from "@polkadot/util/bn/bn";
import { WalletPromise } from "@acala-network/sdk-wallet";
import { HomaLite } from "./homaLite";
import axios from "axios";
import { IncentiveResult } from "../types/acalaTypes";
import { HomaLiteMintResult, HomaLiteRedeemResult } from "./homaLite/types";

const ONE = FixedPointNumber.ONE;
const ACA_SYS_BLOCK_TIME = new BN(12000);
const SECONDS_OF_YEAR = new BN(365 * 24 * 3600);
const KSM_DECIMAL = 12;

let walletPromise: WalletPromise;
let homaApi: HomaLite;

function _computeExchangeFee(path: Token[], fee: FixedPointNumber) {
  return ONE.minus(
    path.slice(1).reduce((acc) => {
      return acc.times(ONE.minus(fee));
    }, ONE)
  );
}

function _getTokenDecimal(api: ApiPromise, token: string): number {
  let res = 18;
  api.registry.chainTokens.forEach((t, i) => {
    if (token === t) {
      res = api.registry.chainDecimals[i];
    }
  });
  return res;
}

// let swapper: SwapPromise;
/**
 * calc token swap amount
 */
async function calcTokenSwapAmount(api: ApiPromise, input: number, output: number, swapPair: string[], slippage: number) {
  // if (!swapper) {
  //   swapper = new SwapPromise(api);
  // }
  const swapper = new SwapPromise(api);

  const inputToken = Token.fromCurrencyId(
    api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, { token: swapPair[0] }),
    _getTokenDecimal(api, swapPair[0])
  );
  const outputToken = Token.fromCurrencyId(
    api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, { token: swapPair[1] }),
    _getTokenDecimal(api, swapPair[1])
  );
  const i = new FixedPointNumber(input || 0, inputToken.decimal);
  const o = new FixedPointNumber(output || 0, outputToken.decimal);

  const mode = output === null ? "EXACT_INPUT" : "EXACT_OUTPUT";

  return new Promise((resolve, reject) => {
    const exchangeFee = api.consts.dex.getExchangeFee as any;

    swapper
      .swap([inputToken, outputToken], output === null ? i : o, mode)
      .then((res: any) => {
        const feeRate = new FixedPointNumber(exchangeFee[0].toString()).div(new FixedPointNumber(exchangeFee[1].toString()));
        if (res.input) {
          resolve({
            amount: output === null ? res.output.balance.toNumber(6) : res.input.balance.toNumber(6),
            priceImpact: res.naturalPriceImpact.toNumber(6),
            fee: res.input.balance.times(_computeExchangeFee(res.path, feeRate)).toNumber(6),
            path: res.path,
            input: res.input.token.toString(),
            output: res.output.token.toString(),
          });
        }
      })
      .catch((err) => {
        resolve({ error: err });
      });
  });
}

async function queryLPTokens(api: ApiPromise, address: string) {
  const allTokens = (api.consts.dex.enabledTradingPairs as any).map((item: any) =>
    api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, {
      DexShare: [item[0].asToken.toString(), item[1].asToken.toString()],
    })
  );

  const res = await api.queryMulti(allTokens.map((e) => [api.query.tokens.accounts, [address, e]]));
  return (res as any)
    .map((e: any, i: number) => ({ free: e.free.toString(), currencyId: allTokens[i].asDexShare }))
    .filter((e: any) => e.free > 0);
}

/**
 * getAllTokens, with ForeignAssets
 */
async function getAllTokens(api: ApiPromise) {
  const [{ tokenSymbol, tokenDecimals }, foreign] = await Promise.all([
    api.rpc.system.properties(),
    api.query.assetRegistry.assetMetadatas.entries(),
  ]);
  const tokens = [...api.registry.chainTokens];
  tokens.shift();
  const res = tokens.map((e) => ({
    type: "Token",
    symbol: e,
    decimals: tokenDecimals.toJSON()[tokenSymbol.toJSON().indexOf(e)],
    minBalance: existential_deposit[e],
  }));
  const res2 = foreign.map(([args, data]) => {
    const json = data.toJSON();
    return {
      type: "ForeignAsset",
      id: args.toHuman()[0],
      ...(data.toHuman() as Object),
      decimals: json["decimals"],
      minBalance: json["minimalBalance"].toString(),
    };
  });
  return [...res, ...res2];
}

/**
 * getAllTokenPairs
 */
async function getTokenPairs(api: ApiPromise) {
  const tokenPairs = await api.query.dex.tradingPairStatuses.entries();
  return tokenPairs
    .filter((item) => (item[1] as any).isEnabled)
    .map(
      ([
        {
          args: [item],
        },
      ]) => {
        const pair = item.toJSON() as any[];
        const pairDecimals = [_getTokenDecimal(api, pair[0]?.token?.toString()), _getTokenDecimal(api, pair[1]?.token?.toString())];
        return {
          decimals: pairDecimals[0],
          pairDecimals,
          tokens: pair,
        };
      }
    );
}

/**
 * getBootstraps
 */
async function getBootstraps(api: ApiPromise) {
  const tokenPairs = await api.query.dex.tradingPairStatuses.entries();
  return tokenPairs
    .filter((item) => (item[1] as any).isProvisioning)
    .map(
      ([
        {
          args: [item],
        },
        provisioning,
      ]) => {
        const pair = item.toJSON() as any[];
        const pairDecimals = [_getTokenDecimal(api, pair[0]?.token?.toString()), _getTokenDecimal(api, pair[1]?.token?.toString())];
        return {
          decimals: pairDecimals[0] > pairDecimals[1] ? pairDecimals[0] : pairDecimals[1],
          pairDecimals,
          tokens: pair,
          provisioning: (provisioning as any).asProvisioning,
        };
      }
    );
}

/**
 * fetchDexPoolInfo
 * @param {String} poolId
 * @param {String} address
 */
async function fetchCollateralRewards(api: ApiPromise, pool: any, address: string, decimals: number) {
  const res = (await Promise.all([
    api.query.rewards.pools({ LoansIncentive: pool }),
    api.query.rewards.shareAndWithdrawnReward({ LoansIncentive: pool }, address),
  ])) as any;
  const pendingRewards = (!!api.query.incentives.pendingRewards
    ? await api.query.incentives?.pendingRewards({ LoansIncentive: pool }, address)
    : null) as any;
  let proportion = new FixedPointNumber(0);
  if (res[0] && res[1] && FPNum(res[0].totalShares).gt(new FixedPointNumber(0))) {
    proportion = FPNum(res[1][0]).div(FPNum(res[0].totalShares));
  }
  const decimalsACA = 12;
  return {
    token: pool.Token,
    sharesTotal: res[0].totalShares,
    shares: res[1][0],
    proportion: proportion.toNumber() || 0,
    reward: FPNum(res[0].totalRewards, decimals)
      .times(proportion)
      .minus(FPNum(res[1][1], decimals))
      .plus(FPNum(pendingRewards || 0, decimalsACA))
      .toString(),
  };
}

/**
 * fetchDexPoolInfo
 * @param {String} poolId
 * @param {String} address
 */
async function fetchCollateralRewardsV2(api: ApiPromise, pool: any, address: string, decimals: number) {
  if (!walletPromise) {
    walletPromise = new WalletPromise(api);
  }
  const res = (await Promise.all([
    api.query.rewards.poolInfos({ Loans: pool }),
    api.query.rewards.sharesAndWithdrawnRewards({ Loans: pool }, address),
  ])) as any;
  const pendingRewards = (!!api.query.incentives.pendingMultiRewards
    ? await api.query.incentives?.pendingMultiRewards({ Loans: pool }, address)
    : null) as any;
  let proportion = new FixedPointNumber(0);
  if (res[0] && res[1] && FPNum(res[0].totalShares).gt(new FixedPointNumber(0))) {
    proportion = FPNum(res[1][0]).div(FPNum(res[0].totalShares));
  }
  const withdrawns = Array.from(res[1][1].entries()).map((entry) => {
    const currencyId = forceToCurrencyIdName(entry[0]);
    const token = walletPromise.getToken(currencyId);
    const amount = FPNum(entry[1].toString(), token.decimal);
    return { token, amount };
  });
  const pendings = Array.from(pendingRewards.entries()).map((entry) => {
    const currencyId = forceToCurrencyIdName(entry[0]);
    const token = walletPromise.getToken(currencyId);
    const amount = FPNum(entry[1].toString(), token.decimal);
    return { token, amount };
  });
  const incentives = Array.from(res[0].rewards.entries()).map((e: any) => {
    const currencyId = forceToCurrencyIdName(e[0]);
    const token = walletPromise.getToken(currencyId);
    const tokenString = e[0].toHuman()["Token"];
    return {
      token: tokenString,
      amount: (
        FPNum(e[1][0], token.decimal)
          .times(proportion)
          .minus(withdrawns.find((i) => forceToCurrencyIdName(i.token) === forceToCurrencyIdName(token))?.amount || new FixedPointNumber(0))
          .plus(pendings.find((i) => forceToCurrencyIdName(i.token) === forceToCurrencyIdName(token))?.amount || new FixedPointNumber(0))
          .toNumber() || 0
      ).toString(),
    };
  });
  pendings.forEach((e) => {
    if (!incentives.find((i) => i.token === forceToCurrencyIdName(e.token))) {
      incentives.push({
        token: forceToCurrencyIdName(e.token),
        amount: e.amount.toNumber().toString(),
      });
    }
  });
  return {
    token: pool.Token,
    sharesTotal: res[0].totalShares,
    shares: res[1][0],
    proportion: proportion.toNumber() || 0,
    reward: incentives,
  };
}

/**
 * fetchDexPoolInfo
 * @param {String} poolId
 * @param {String} address
 */
async function fetchDexPoolInfo(api: ApiPromise, pool: any, address: string) {
  if (!walletPromise) {
    walletPromise = new WalletPromise(api);
  }
  const res = (await Promise.all([
    api.query.dex.liquidityPool(pool.DexShare),
    api.query.rewards.poolInfos({ Dex: pool }),
    api.query.rewards.sharesAndWithdrawnRewards({ Dex: pool }, address),
    api.query.tokens.totalIssuance(pool),
  ])) as any;
  const pendingRewards = (!!api.query.incentives.pendingMultiRewards
    ? await api.query.incentives?.pendingMultiRewards({ Dex: pool }, address)
    : null) as any;
  let proportion = new FixedPointNumber(0);
  if (res[1] && res[2] && FPNum(res[1].totalShares).gt(new FixedPointNumber(0))) {
    proportion = FPNum(res[2][0]).div(FPNum(res[1].totalShares));
  }
  const withdrawns = Array.from(res[2][1].entries()).map((entry) => {
    const currencyId = forceToCurrencyIdName(entry[0]);
    const token = walletPromise.getToken(currencyId);
    const amount = FPNum(entry[1].toString(), token.decimal);
    return { token, amount };
  });
  const pendings = Array.from(pendingRewards.entries()).map((entry) => {
    const currencyId = forceToCurrencyIdName(entry[0]);
    const token = walletPromise.getToken(currencyId);
    const amount = FPNum(entry[1].toString(), token.decimal);
    return { token, amount };
  });
  let saving = "0";
  const incentives = Array.from(res[1].rewards.entries()).map((e: any) => {
    const currencyId = forceToCurrencyIdName(e[0]);
    const token = walletPromise.getToken(currencyId);
    const tokenString = e[0].toHuman()["Token"];
    const data = {
      token: tokenString,
      amount: (
        FPNum(e[1][0], token.decimal)
          .times(proportion)
          .minus(withdrawns.find((i) => forceToCurrencyIdName(i.token) === forceToCurrencyIdName(token))?.amount || new FixedPointNumber(0))
          .plus(pendings.find((i) => forceToCurrencyIdName(i.token) === forceToCurrencyIdName(token))?.amount || new FixedPointNumber(0))
          .toNumber() || 0
      ).toString(),
    };
    if (tokenString === "KUSD") {
      saving = data.amount;
      return;
    }
    return data;
  });
  return {
    token: pool.DexShare.map((e) => e.Token).join("-"),
    pool: res[0],
    sharesTotal: res[1].totalShares,
    shares: res[2][0],
    proportion: proportion.toNumber() || 0,
    reward: { incentive: incentives.filter((e) => !!e), saving },
    issuance: res[3],
  };
}

function FPNum(input: any, decimals?: number) {
  return FixedPointNumber.fromInner(input.toString(), decimals);
}

async function _calacFreeList(api: ApiPromise, start: number, duration: number, decimalsDOT: number) {
  const list = [];
  for (let i = start; i < start + duration; i++) {
    const result = await api.query.stakingPool.unbonding(i);
    const free = FixedPointNumber.fromInner(result[0], decimalsDOT).minus(FixedPointNumber.fromInner(result[1], decimalsDOT));
    list.push({
      era: i,
      free: free.toNumber(),
    });
  }
  return list.filter((item) => item.free);
}

async function fetchHomaUserInfo(api: ApiPromise, address: string) {
  const stakingPool = await (api.derive as any).homa.stakingPool();
  const start = stakingPool.currentEra.toNumber() + 1;
  const duration = stakingPool.bondingDuration.toNumber();
  const nextEraUnbund = (await api.query.stakingPool.nextEraUnbonds(address)) as any;
  const nextEraIndex = start + duration;
  const claims = [];
  let nextEraAdded = false;
  for (let i = start; i < start + duration + 2; i++) {
    const claimed = (await api.query.stakingPool.unbondings(address, i)) as any;
    if (claimed.gtn(0)) {
      claims[claims.length] = {
        era: i,
        claimed: i === nextEraIndex ? claimed + nextEraUnbund : claimed,
      };
      if (i === nextEraIndex) {
        nextEraAdded = true;
      }
    }
  }
  if (nextEraUnbund.gtn(0) && !nextEraAdded) {
    claims[claims.length] = {
      era: nextEraIndex,
      claimed: nextEraUnbund,
    };
  }

  const unbonded = await (api.rpc as any).stakingPool.getAvailableUnbonded(address);
  return {
    unbonded: unbonded.amount || 0,
    claims,
  };
}

const NFT_CLASS_ALL = [0, 1, 2, 3, 4, 5];
async function _transformClassInfo(api: ApiPromise, id: number, data: any): Promise<Omit<any, "tokenId">> {
  const cid = hexToString(data.metadata.toString());
  const _properties = api.createType("Properties", data.data.properties.toU8a());
  const properties = (_properties.toJSON() as unknown) as any[];
  const attribute = (data.data.attributes.toJSON() as unknown) as any;
  const owner = data.owner.toString();
  const metadataIpfsUrl = _getMetadataUrl(cid);

  let name = "";
  let description = "";
  let dwebImage = "";
  let serviceImage = "";

  try {
    const metadataResult = await axios.get((nft_image_config as Record<string, string>)[String(id)] || metadataIpfsUrl);

    if (metadataResult.status !== 200) {
      throw new Error("fetch metadata error");
    }

    const data: any = metadataResult.data;

    name = data.name as string;
    description = data.description as string;
    dwebImage = data.image as string;
    serviceImage = data?.qiNiuImage as string;
  } catch (e) {
    console.error(e);
  }

  return {
    attribute,
    classId: String(id),
    dwebMetadata: cid,
    metadata: {
      description,
      dwebImage,
      imageIpfsUrl: _getImageUrl(dwebImage),
      imageServiceUrl: serviceImage,
      name,
    },
    metadataIpfsUrl,
    owner,
    properties,
  };
}

function _getMetadataUrl(cid: string) {
  return `https://${cid}.ipfs.dweb.link/metadata.json`;
}

function _getImageUrl(data: string) {
  const [cid, fileName] = data.replace("ipfs://", "").split("/");

  return `https://${cid}.ipfs.dweb.link/${fileName}`;
}

async function queryNFTs(api: ApiPromise, address: string) {
  const classes = await api.queryMulti(
    NFT_CLASS_ALL.map((id) => {
      return [api.query.ormlNFT.classes, id];
    })
  );
  const infos = await Promise.all(classes.map((e: any, i) => _transformClassInfo(api, i, e.unwrapOrDefault())));
  const data = await Promise.all(
    NFT_CLASS_ALL.map((id) => {
      return api.query.ormlNFT.tokensByOwner.entries(address, id);
    })
  );

  const res = [];
  data
    .filter((item) => item.length !== 0)
    .map((list: any) => {
      list.forEach((item: any) => {
        const classId = item?.[0]?.args?.[1].toString();
        const tokenId = item?.[0]?.args?.[2].toString();
        const info = infos.find((item: any) => item.classId === classId);

        if (!!info) {
          res[res.length] = {
            ...info,
            tokenId: tokenId,
          };
        }
      });
    });

  const deposits = await Promise.all(res.map((e) => api.query.ormlNFT.tokens(e.classId, e.tokenId)));
  return res.map((e, i) => ({ ...e, deposit: (deposits[i] as any).toJSON()["data"]["deposit"].toString() }));
}

async function checkExistentialDepositForTransfer(
  api: ApiPromise,
  address: string,
  token: string,
  decimals: number,
  amount: number,
  direction = "to"
) {
  if (!walletPromise) {
    walletPromise = new WalletPromise(api);
  }

  return new Promise((resolve, _) => {
    const tokenPair = token.split("-");
    walletPromise
      .checkTransfer(
        address,
        token.match("-") ? createLPCurrencyName(tokenPair[0], tokenPair[1]) : token,
        new FixedPointNumber(amount, decimals),
        direction as "from" | "to"
      )
      .then((res) => {
        resolve({ error: null, result: res });
      })
      .catch((err) => {
        resolve({ error: err.message, result: false });
      });
  });
}

async function queryIncentives(api: ApiPromise) {
  if (!walletPromise) {
    walletPromise = new WalletPromise(api);
  }

  const pools = await Promise.all([
    api.query.incentives.incentiveRewardAmounts.entries(),
    api.query.incentives.claimRewardDeductionRates.entries(),
    api.query.incentives.dexSavingRewardRates.entries(),
  ]);
  const res: IncentiveResult = {
    Dex: {},
    DexSaving: {},
    Loans: {},
  };
  const epoch = Number(api.consts.incentives.accumulatePeriod.toString());
  const epochOfYear = SECONDS_OF_YEAR.mul(new BN(1000))
    .div(ACA_SYS_BLOCK_TIME)
    .div(new BN(epoch));
  const deductions = pools[1].map((e) => {
    const poolId = e[0].args[0].toHuman();
    const incentiveType = Object.keys(poolId)[0];
    const id = poolId[incentiveType];
    const idString = incentiveType === "Dex" ? id["DexShare"].map((e: any) => e["Token"]).join("-") : id["Token"];

    return { incentiveType, idString, value: FPNum(e[1], 18).toString() };
  });
  pools[0].forEach((e, i) => {
    const poolId = e[0].args[0].toHuman();
    const incentiveType = Object.keys(poolId)[0];
    const id = poolId[incentiveType];
    const idString = incentiveType === "Dex" ? id["DexShare"].map((e: any) => e["Token"]).join("-") : id["Token"];
    const incentiveToken = e[0].args[1];
    const incentiveTokenView = incentiveToken.toHuman()["Token"];
    const incentiveTokenDecimal = walletPromise.getToken(incentiveToken as any).decimal;

    if (!res[incentiveType][idString]) {
      res[incentiveType][idString] = [];
    }
    res[incentiveType][idString].push({
      token: incentiveTokenView,
      amount: FPNum(epochOfYear.mul(new BN(e[1].toString())), incentiveTokenDecimal).toString(),
      deduction: deductions.find((e) => e.incentiveType === incentiveType && e.idString === idString)?.value || "0",
    });
  });
  deductions.forEach((e) => {
    if (!res[e.incentiveType][e.idString]) {
      res[e.incentiveType][e.idString] = [
        {
          token: "Any",
          amount: "0",
          deduction: e.value,
        },
      ];
    }
  });
  pools[2].forEach((e) => {
    const poolId = e[0].args[0].toHuman();
    const incentiveType = "DexSaving";
    const id = poolId["Dex"]["DexShare"].map((e: any) => e["Token"]).join("-");

    if (!res[incentiveType][id]) {
      res[incentiveType][id] = [];
    }
    res[incentiveType][id].push({
      token: "KUSD",
      amount: FPNum(epochOfYear.mul(new BN(e[1].toString())).div(new BN(2)), 18).toString(),
      deduction: deductions.find((e) => e.idString === id)?.value || "0",
    });
  });
  return res;
}

async function queryAggregatedAssets(api: ApiPromise, address: string) {
  const [dexPools, loanTypes] = await Promise.all([getTokenPairs(api), api.derive.loan.allLoanTypes()]);
  const [loans, nativeToken, tokens, poolInfos, loanRewards, incentives] = await Promise.all([
    api.derive.loan.allLoans(address),
    api.query.system.account(address),
    api.query.tokens.accounts.entries(address),
    Promise.all(dexPools.map((e) => fetchDexPoolInfo(api, { DexShare: e.tokens.map((i) => ({ Token: i.token })) }, address))),
    Promise.all(
      loanTypes.map((e) => {
        const token = e.currency.toHuman().Token;
        return fetchCollateralRewardsV2(api, { Token: token }, address, _getTokenDecimal(api, token));
      })
    ),
    queryIncentives(api),
  ]);
  const [loansMap, loanRewardsMap] = _calcLoanAssets(api, loanTypes, loans, loanRewards, incentives);
  const [tokensMap, lpTokensMap] = _calcFreeTokens(api, nativeToken, tokens);
  const [lpStakedMap, lpFreemap, lpRewardsMap] = _calcLPAssets(api, poolInfos, lpTokensMap, incentives);
  Object.keys(loanRewardsMap).forEach((token) => {
    if (!lpRewardsMap[token]) {
      lpRewardsMap[token] = loanRewardsMap[token];
    } else {
      lpRewardsMap[token] += loanRewardsMap[token];
    }
  });
  return {
    Tokens: tokensMap,
    Vaults: loansMap,
    "LP Staking": lpStakedMap,
    "LP Free": lpFreemap,
    Rewards: lpRewardsMap,
  };
}
function _addAsset(assetsMap: object, token: string, value: number) {
  if (assetsMap[token] == undefined) {
    assetsMap[token] = 0;
  }
  assetsMap[token] += value;
}
function _calcLoanAssets(api: ApiPromise, loanTypes: any[], loans: any[], loanRewards: any[], incentives: any) {
  const karura_stable_coin = "KUSD";
  const res = {};
  const rewardsMap = {};
  loans.forEach((e) => {
    const token = e.currency.toHuman().Token;
    _addAsset(res, token, FPNum(e.collateral, _getTokenDecimal(api, token)).toNumber());
    _addAsset(
      res,
      karura_stable_coin,
      0 -
        FPNum(e.debit, _getTokenDecimal(api, karura_stable_coin))
          .times(FPNum(loanTypes.find((t) => t.currency == e.currency).debitExchangeRate))
          .toNumber()
    );

    const reward = loanRewards.find((e) => e.token === token);
    if (!!reward && !!incentives.Loans[token]) {
      const loyalty = incentives.Loans[token][0].deduction;
      reward.reward.forEach((i) => {
        _addAsset(rewardsMap, "KAR", i.amount * (1 - loyalty));
      });
    }
  });
  return [res, rewardsMap];
}
function _calcFreeTokens(api: ApiPromise, native: any, tokens: any[]) {
  const native_token = "KAR";
  const res = {};
  const lpTokens = {};

  res[native_token] = FPNum(native.data.free.add(native.data.reserved), _getTokenDecimal(api, native_token)).toNumber();
  tokens.forEach(
    ([
      {
        args: [_, currency],
      },
      v,
    ]) => {
      const token = currency.toHuman()["Token"];
      if (!token) {
        lpTokens[
          currency
            .toHuman()
            ["DexShare"].map((e) => e.Token)
            .join("-")
        ] = v.free.add(v.reserved);
      } else {
        _addAsset(res, token, FPNum(v.free.add(v.reserved), _getTokenDecimal(api, token)).toNumber());
      }
    }
  );
  return [res, lpTokens];
}
function _calcLPAssets(api: ApiPromise, poolInfos: any[], lpTokensMap: any, incentives: any) {
  const res = {};
  const lpTokensFree = {};
  const lpRewards = {};

  poolInfos.map((e) => {
    const pair = e.token.split("-");
    const decimalPair = [_getTokenDecimal(api, pair[0]), _getTokenDecimal(api, pair[1])];
    [e.shares, lpTokensMap[e.token]].forEach((amount, i) => {
      if (!!amount && amount.gt(new BN(0))) {
        const proportion = FPNum(amount).div(FPNum(e.issuance));
        pair.forEach((token, index) => {
          _addAsset(
            i === 0 ? res : lpTokensFree,
            token,
            index === 0
              ? FPNum(e.pool[0], decimalPair[0])
                  .times(proportion)
                  .toNumber()
              : FPNum(e.pool[1], decimalPair[1])
                  .times(proportion)
                  .toNumber()
          );
        });
      }
    });

    const loyalty = incentives.Dex[e.token] ? incentives.Dex[e.token][0].deduction : 0;
    const savingLoyalty = !!incentives.DexSaving[e.token] ? incentives.DexSaving[e.token][0].deduction : 0;
    e.reward.incentive.forEach((i) => {
      _addAsset(lpRewards, i.token, i.amount * (1 - loyalty));
    });
    if ((e.reward.saving || 0) > 0) {
      _addAsset(lpRewards, "KUSD", (e.reward.saving || 0) * (1 - savingLoyalty));
    }
  });
  return [res, lpTokensFree, lpRewards];
}

async function calcHomaMintAmount(api: ApiPromise, amount: number) {
  if (!walletPromise || !homaApi) {
    walletPromise = new WalletPromise(api);
    homaApi = new HomaLite(api, walletPromise);
  }

  const res: HomaLiteMintResult = await homaApi.mint(new FixedPointNumber(amount, KSM_DECIMAL));
  return {
    fee: res.fee.toNumber().toFixed(8),
    received: res.received.toNumber().toFixed(8),
    suggestRedeemRequests: res.suggestRedeemRequests,
  };
}

async function calcHomaRedeemAmount(api: ApiPromise, address: string, amount: number, isByDex: boolean = false) {
  if (!walletPromise || !homaApi) {
    walletPromise = new WalletPromise(api);
    homaApi = new HomaLite(api, walletPromise);
  }

  if (isByDex) {
    const swapper = new SwapPromise(api);
    const res: HomaLiteRedeemResult = await homaApi.redeemFromDex(
      swapper,
      new FixedPointNumber(amount, KSM_DECIMAL),
      new FixedPointNumber(0.005)
    );
    return {
      fee: res.fee.toNumber().toFixed(8),
      expected: res.expected.toNumber().toFixed(8),
    };
  }

  const res: HomaLiteRedeemResult = await homaApi.redeem(address, new FixedPointNumber(amount, KSM_DECIMAL));
  return {
    fee: res.fee.toNumber().toFixed(8),
    expected: res.expected.toNumber().toFixed(8),
    newRedeemBalance: res.newRedeemBalance?.toChainData(),
  };
}

async function queryRedeemRequest(api: ApiPromise, address: string) {
  if (!walletPromise || !homaApi) {
    walletPromise = new WalletPromise(api);
    homaApi = new HomaLite(api, walletPromise);
  }

  const data = await homaApi.queryUserUnbondingStakingToken(address);
  return (data[0] || FixedPointNumber.ZERO).toNumber().toFixed(8);
}

async function queryDexIncentiveLoyaltyEndBlock(api: ApiPromise) {
  const data = await api.query.scheduler.agenda.entries();

  const result: { blockNumber: number; pool: PoolId }[] = [];

  data.forEach(([key, value]) => {
    const blockNumber = key.args[0].toNumber();

    const inner = (data: PalletSchedulerScheduledV2["call"]) => {
      if (data.method === "updateClaimRewardDeductionRates" && data.section === "incentives") {
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
        const args = (data.args as any) as Vec<Vec<ITuple<[PoolId, Rate]>>>;

        args.forEach((i) => {
          i.forEach((item) => {
            const ratio = item[1].toString();

            if (ratio === "0") {
              result.push({
                blockNumber,
                pool: api.createType("ModuleIncentivesPoolId", item[0]),
              });
            }
          });
        });
      }

      if (data.method === "batchAll" && data.section === "utility") {
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
        ((data.args[0] as any) as PalletSchedulerScheduledV2["call"][]).forEach((item) => inner(item));
      }
    };

    value.forEach((item) => inner(item.unwrapOrDefault().call));
  });

  return result;
}

export default {
  calcTokenSwapAmount,
  queryLPTokens,
  getAllTokens,
  getTokenPairs,
  getBootstraps,
  fetchCollateralRewards,
  fetchCollateralRewardsV2,
  fetchDexPoolInfo,
  fetchHomaUserInfo,
  queryNFTs,
  checkExistentialDepositForTransfer,
  queryIncentives,
  queryAggregatedAssets,

  // homaLite
  calcHomaMintAmount,
  calcHomaRedeemAmount,
  queryRedeemRequest,

  queryDexIncentiveLoyaltyEndBlock,
};
