import { createDexShareName, FixedPointNumber, forceToCurrencyId, forceToCurrencyName, Token } from "@acala-network/sdk-core";
import { AcalaDex, AggregateDex, NutsDex } from "@acala-network/sdk/dex";
import { ApiPromise, ApiRx } from "@polkadot/api";
import { hexToString } from "@polkadot/util";
import { nft_image_config } from "../constants/acala";
import { BN } from "@polkadot/util/bn/bn";
import { Homa, Wallet } from "@acala-network/sdk";
import axios from "axios";
import { IncentiveResult, TaigaUserReward } from "../types/acalaTypes";
import { firstValueFrom, throttleTime, take } from "rxjs";
import { HomaEnvironment } from "@acala-network/sdk/homa/types";
import { BalanceData } from "@acala-network/sdk/wallet/type";
import { StableAssetRx } from "@nuts-finance/sdk-stable-asset";
import { BigNumber } from "bignumber.js";

const SECONDS_OF_YEAR = new BN(365 * 24 * 3600);
const KSM_DECIMAL = 12;
const native_token = "KAR";
const native_token_list = [native_token, "KSM", "LKSM", "KUSD"];
const taigaPoolApy: Record<string, number> = {};

let ACA_SYS_BLOCK_TIME = new BN(12000);

let homa: Homa;

function _getTokenDecimal(allTokens: any[], tokenNameId: string): number {
  if (tokenNameId == native_token) return 12;

  return allTokens.find((i) => i.tokenNameId === tokenNameId)?.decimals || 18;
}

function _getTokenSymbol(allTokens: any[], tokenNameId: string): string {
  if (tokenNameId == native_token) return native_token;

  return allTokens.find((i) => i.tokenNameId === tokenNameId)?.symbol;
}

// async function _fetchBlockDuration() {
//   const res = await axios.get("https://api.polkawallet.io/height-time-avg?recent=300");

//   if (res.status === 200) {
//     ACA_SYS_BLOCK_TIME = new BN((res.data["avg"] * 1000).toFixed(0));
//   }
// }
// _fetchBlockDuration();

let swapper: AggregateDex;
async function _initDexSDK(api: ApiRx) {
  const wallet = (<any>window).wallet;
  swapper = new AggregateDex({
    api,
    wallet,
    providers: [new AcalaDex({ api, wallet }), new NutsDex({ api, wallet })],
  });

  await swapper.isReady;
}
async function getSwapTokens(apiRx: ApiRx) {
  if (!swapper) {
    await _initDexSDK(apiRx);
  }

  const tokens = await firstValueFrom(swapper.tradableTokens$.pipe(take(1)));
  return tokens.map((e) => {
    return {
      type: _getTokenType(e),
      tokenNameId: e.name,
      symbol: e.symbol === "aUSD" ? e.name : e.symbol,
      id: Object.values(e.toChainData())[0].toString(),
      src: e.locations,
      currencyId: e.toChainData(),
      decimals: e.decimals,
      minBalance: e.ed.toChainData().toString(),
    };
  });
}
/**
 * calc token swap amount
 */
async function calcTokenSwapAmount(apiRx: ApiRx, input: number, output: number, swapPair: string[], slippage: number) {
  if (!swapper) {
    await _initDexSDK(apiRx);
  }

  const inputToken = await ((<any>window).wallet as Wallet).getToken(swapPair[0]);
  const outputToken = await ((<any>window).wallet as Wallet).getToken(swapPair[1]);
  const i = new FixedPointNumber(input || 0, inputToken.decimals);
  const o = new FixedPointNumber(output || 0, outputToken.decimals);

  const mode = output === null ? "EXACT_INPUT" : "EXACT_OUTPUT";

  try {
    const result = await firstValueFrom(
      swapper
        .swap({
          source: "aggregate",
          mode,
          path: [inputToken, outputToken],
          input: output === null ? i : o,
          acceptiveSlippage: slippage,
        })
        .pipe(throttleTime(100))
    );

    const res = result.result;
    const path = result.tracker;
    if (res.input) {
      const tx = swapper.getTradingTx(result);
      return {
        amount: output === null ? res.output.amount.toNumber(6) : res.input.amount.toNumber(6),
        priceImpact: path.map((e) => e.naturalPriceImpact.toNumber(6)),
        fee: path.map((e) => e.exchangeFee.toNumber(6)),
        feeToken: path.map((e) => (e.source === "acala" ? e.input.token.name : e.output.token.name)),
        path: res.path.map((e) => ({ dex: e[0], path: e[1].map((i) => i.name) })),
        tx: {
          section: tx.method.section,
          method: tx.method.method,
          params: tx.args.map((e) => e.toJSON()),
        },
      };
    }
    return { error: "dex error" };
  } catch (err) {
    return { error: err };
  }
}

/**
 * getAllTokens, with ForeignAssets
 */
async function getAllTokens(api: ApiPromise) {
  const allTokens = await ((<any>window).wallet as Wallet).getTokens();

  return Object.values(allTokens)
    .map((e) => {
      return {
        type: _getTokenType(e),
        tokenNameId: e.name,
        symbol: e.symbol === "aUSD" ? e.name : e.symbol,
        id: Object.values(e.toChainData())[0].toString(),
        src: e.locations,
        currencyId: e.toChainData(),
        decimals: e.decimals,
        minBalance: e.ed.toChainData().toString(),
      };
    })
    .filter((e) => e.tokenNameId !== native_token && e.type !== "DexShare");
}

function _getTokenType(token: Token) {
  return native_token_list.includes(token.name)
    ? "Token"
    : token.name.startsWith("lp")
    ? "DexShare"
    : token.name.startsWith("erc20")
    ? "Erc20"
    : token.name.startsWith("sa") || token.name === "TAI"
    ? "TaigaAsset"
    : "ForeignAsset";
}

/**
 * get token balance from acala wallet sdk
 */
async function getTokenBalance(api: ApiPromise, address: string, tokenNameId: string, callback: (value: any) => void) {
  const sub = ((<any>window).wallet as Wallet).subscribeBalance(tokenNameId, address);
  if (!!callback) {
    sub.subscribe({
      next: (value: BalanceData) => {
        callback(_formatBalanceData(value));
      },
    });
  }
  const value = await firstValueFrom(sub);
  return _formatBalanceData(value);
}
function _formatBalanceData(value: BalanceData) {
  return {
    free: value.free.toChainData().toString(),
    frozen: value.locked.toChainData().toString(),
    reserved: value.reserved.toChainData().toString(),
    available: value.available.toChainData().toString(),
  };
}

/**
 * getAllTokenPairs
 */
async function getTokenPairs(api: ApiPromise) {
  const tokenPairs = await api.query.dex.tradingPairStatuses.entries();
  return tokenPairs
    .filter((item) => (item[1] as any).isEnabled)
    .map(([{ args: [item] }]) => ({
      tokens: item.toJSON(),
      tokenNameId: createDexShareName(forceToCurrencyName(item[0]), forceToCurrencyName(item[1])),
    }));
}
async function getTaigaTokenPairs(apiRx: ApiRx) {
  if (!homa) {
    homa = new Homa((<any>window).api, (<any>window).wallet);
  }

  const [stablePools, homaEnv] = await Promise.all([
    firstValueFrom(new StableAssetRx(apiRx).subscribeAllPools().pipe(take(1))),
    homa.getEnv(),
  ]);
  return stablePools.map(({ poolAsset, assets, balances, precisions }) => {
    if (assets[1].toJSON()["token"] === "LKSM") {
      balances[1] = balances[1].div(new BigNumber(homaEnv.exchangeRate.toNumber()));
    }
    return {
      tokens: assets,
      balances: balances.map((e, i) => e.div(precisions[i])),
      tokenNameId: forceToCurrencyName(poolAsset),
    };
  });
}

async function _queryTaigaPoolApy(network: string, pool: number) {
  const key = `${network}-${pool}`;

  if (taigaPoolApy[key]) {
    return taigaPoolApy[key];
  }

  const result = await axios.get(`https://api.taigaprotocol.io/rewards/apr?network=${network}&pool=${pool}`);

  if (result.status === 200 && Object.keys(result.data).length > 0) {
    taigaPoolApy[key] = result.data as number;
  }

  return taigaPoolApy[key];
}

async function _queryTaigaUserRewards(network: string, pool: number, user: string) {
  const result = await axios.get(`https://api.taigaprotocol.io/rewards/user/${user}?network=${network}&pool=${pool}`);

  if (result.status === 200 && Object.keys(result.data).length > 0) {
    return result.data as TaigaUserReward;
  }
}

async function getTaigaPoolInfo(api: ApiPromise, address: string) {
  const [taiKSMApy, threeUSDApy] = await Promise.all([0, 1].map((i) => _queryTaigaPoolApy("karura", i)));
  const [taiKSMReward, threeUSDReward] = await Promise.all([0, 1].map((i) => _queryTaigaUserRewards("karura", i, address)));
  const taiKSMshares = await _fetchCollateralRewards(api, { StableAssetPoolToken: 0 }, address);
  const threeUSDshares = await (<any>window).wallet.getIssuance("sa://1");
  return {
    "sa://0": {
      apy: taiKSMApy,
      reward: taiKSMReward.claimable,
      rewardTokens: ["sa://0", "TAI"],
      userShares: taiKSMshares.shares,
      totalShares: taiKSMshares.sharesTotal,
    },
    "sa://1": {
      apy: threeUSDApy,
      reward: threeUSDReward.claimable,
      rewardTokens: ["sa://1", "TAI", "sa://0", "LKSM", "KAR"],
      userShares: "0",
      totalShares: threeUSDshares.toChainData(),
    },
  };
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
        return {
          tokens: item.toJSON(),
          tokenNameId: createDexShareName(forceToCurrencyName(item[0]), forceToCurrencyName(item[1])),
          provisioning: (provisioning as any).asProvisioning,
        };
      }
    );
}

/**
 * fetchCollateralRewards
 * @param {String} address
 */
async function fetchCollateralRewards(api: ApiPromise, address: string) {
  const pools = await api.query.rewards.poolInfos.entries();
  const loanPools = pools.map(([key, _]) => key.toHuman()[0]).filter((token) => Object.keys(token)[0] === "Loans");
  return Promise.all(loanPools.map(({ Loans }) => _fetchCollateralRewards(api, Loans, address)));
}

async function _fetchCollateralRewards(api: ApiPromise, pool: any, address: string) {
  const res = (await Promise.all([
    api.query.rewards.poolInfos({ Loans: pool }),
    api.query.rewards.sharesAndWithdrawnRewards({ Loans: pool }, address),
    getAllTokens(api),
  ])) as any;
  const pendingRewards = (!!api.query.incentives.pendingMultiRewards
    ? await api.query.incentives?.pendingMultiRewards({ Loans: pool }, address)
    : null) as any;
  let proportion = new FixedPointNumber(0);
  if (res[0] && res[1] && FPNum(res[0].totalShares).gt(new FixedPointNumber(0))) {
    proportion = FPNum(res[1][0]).div(FPNum(res[0].totalShares));
  }
  const withdrawns = Array.from(res[1][1].entries()).map((entry) => {
    const currencyId = forceToCurrencyId(api, entry[0]);
    const tokenNameId = forceToCurrencyName(currencyId);
    const amount = FPNum(entry[1].toString(), _getTokenDecimal(res[2], tokenNameId));
    return { tokenNameId, currencyId, amount };
  });
  const pendings = Array.from(pendingRewards.entries()).map((entry) => {
    const currencyId = forceToCurrencyId(api, entry[0]);
    const tokenNameId = forceToCurrencyName(currencyId);
    const amount = FPNum(entry[1].toString(), _getTokenDecimal(res[2], tokenNameId));
    return { tokenNameId, currencyId, amount };
  });
  const incentives = Array.from(res[0].rewards.entries()).map((e: any) => {
    const currencyId = forceToCurrencyId(api, e[0]);
    const tokenNameId = forceToCurrencyName(currencyId);
    return {
      tokenNameId,
      currencyId,
      amount: (
        FPNum(e[1][0], _getTokenDecimal(res[2], tokenNameId))
          .times(proportion)
          .minus(withdrawns.find((i) => i.tokenNameId === tokenNameId)?.amount || new FixedPointNumber(0))
          .plus(pendings.find((i) => i.tokenNameId === tokenNameId)?.amount || new FixedPointNumber(0))
          .toNumber() || 0
      ).toString(),
    };
  });
  pendings.forEach((e) => {
    if (!incentives.find((i) => i.tokenNameId === e.tokenNameId)) {
      incentives.push({
        tokenNameId: e.tokenNameId,
        currencyId: e.currencyId,
        amount: e.amount.toNumber().toString(),
      });
    }
  });
  return {
    tokenNameId: forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, pool)),
    pool,
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
  const res = (await Promise.all([
    api.query.dex.liquidityPool(pool.DEXShare),
    api.query.rewards.poolInfos({ Dex: pool }),
    api.query.rewards.sharesAndWithdrawnRewards({ Dex: pool }, address),
    api.query.tokens.totalIssuance(pool),
    getAllTokens(api),
  ])) as any;
  const pendingRewards = (!!api.query.incentives.pendingMultiRewards
    ? await api.query.incentives?.pendingMultiRewards({ Dex: pool }, address)
    : null) as any;
  let proportion = new FixedPointNumber(0);
  if (res[1] && res[2] && FPNum(res[1].totalShares).gt(new FixedPointNumber(0))) {
    proportion = FPNum(res[2][0]).div(FPNum(res[1].totalShares));
  }
  const withdrawns = Array.from(res[2][1].entries()).map((entry) => {
    const currencyId = forceToCurrencyId(api, entry[0]);
    const tokenNameId = forceToCurrencyName(currencyId);
    const amount = FPNum(entry[1].toString(), _getTokenDecimal(res[4], tokenNameId));
    return { tokenNameId, amount };
  });
  const pendings = Array.from(pendingRewards.entries()).map((entry) => {
    const currencyId = forceToCurrencyId(api, entry[0]);
    const tokenNameId = forceToCurrencyName(currencyId);
    const amount = FPNum(entry[1].toString(), _getTokenDecimal(res[4], tokenNameId));
    return { tokenNameId, amount };
  });
  let saving = "0";
  const incentives = Array.from(res[1].rewards.entries()).map((e: any) => {
    const currencyId = forceToCurrencyId(api, e[0]);
    const tokenNameId = forceToCurrencyName(currencyId);
    const data = {
      tokenNameId,
      amount: (
        FPNum(e[1][0], _getTokenDecimal(res[4], tokenNameId))
          .times(proportion)
          .minus(withdrawns.find((i) => i.tokenNameId === tokenNameId)?.amount || new FixedPointNumber(0))
          .plus(pendings.find((i) => i.tokenNameId === tokenNameId)?.amount || new FixedPointNumber(0))
          .toNumber() || 0
      ).toString(),
    };
    if (tokenNameId === "KUSD") {
      saving = data.amount;
      return;
    }
    return data;
  });
  return {
    tokenNameId: forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, pool)),
    tokenPair: pool.DEXShare,
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

async function queryIncentives(api: ApiPromise) {
  const pools = await Promise.all([
    api.query.incentives.incentiveRewardAmounts.entries(),
    api.query.incentives.claimRewardDeductionRates.entries(),
    api.query.incentives.dexSavingRewardRates.entries(),
    getAllTokens(api),
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
    const idString =
      incentiveType === "Dex"
        ? createDexShareName(
            forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, id["DexShare"][0])),
            forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, id["DexShare"][1]))
          )
        : forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, id));

    return { incentiveType, idString, value: FPNum(e[1], 18).toString() };
  });
  pools[0].forEach((e, i) => {
    const poolId = e[0].args[0].toHuman();
    const incentiveType = Object.keys(poolId)[0];
    const id = poolId[incentiveType];
    const idString =
      incentiveType === "Dex"
        ? createDexShareName(
            forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, id["DexShare"][0])),
            forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, id["DexShare"][1]))
          )
        : forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, id));
    const incentiveToken = e[0].args[1];
    const incentiveTokenNameId = forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, incentiveToken));
    const incentiveTokenDecimal = _getTokenDecimal(pools[3], incentiveTokenNameId);

    if (!res[incentiveType][idString]) {
      res[incentiveType][idString] = [];
    }
    res[incentiveType][idString].push({
      tokenNameId: incentiveTokenNameId,
      currencyId: incentiveToken.toHuman(),
      amount: FPNum(epochOfYear.mul(new BN(e[1].toString())), incentiveTokenDecimal).toString(),
      deduction: deductions.find((e) => e.incentiveType === incentiveType && e.idString === idString)?.value || "0",
    });
  });
  deductions.forEach((e) => {
    if (!res[e.incentiveType][e.idString]) {
      res[e.incentiveType][e.idString] = [
        {
          tokenNameId: "Any",
          amount: "0",
          deduction: e.value,
        },
      ];
    }
  });
  pools[2].forEach((e) => {
    const poolId = e[0].args[0].toHuman();
    const incentiveType = "DexSaving";
    const id = createDexShareName(
      forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, poolId["Dex"]["DexShare"][0])),
      forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, poolId["Dex"]["DexShare"][1]))
    );

    if (!res[incentiveType][id]) {
      res[incentiveType][id] = [];
    }
    res[incentiveType][id].push({
      tokenNameId: "KUSD",
      currencyId: { Token: "KUSD" },
      amount: FPNum(epochOfYear.mul(new BN(e[1].toString())).div(new BN(2)), 18).toString(),
      deduction: deductions.find((e) => e.idString === id)?.value || "0",
    });
  });
  return res;
}

async function queryAggregatedAssets(api: ApiPromise, address: string) {
  const [allTokens, dexPools, loanTypes] = await Promise.all([getAllTokens(api), getTokenPairs(api), api.derive.loan.allLoanTypes()]);
  const [loans, nativeToken, tokens, poolInfos, loanRewards, incentives] = await Promise.all([
    api.derive.loan.allLoans(address),
    api.query.system.account(address),
    api.query.tokens.accounts.entries(address),
    Promise.all(dexPools.map((e) => fetchDexPoolInfo(api, { DEXShare: e.tokens }, address))),
    Promise.all(loanTypes.map((e) => _fetchCollateralRewards(api, e.currency, address))),
    queryIncentives(api),
  ]);
  const [loansMap, loanRewardsMap] = _calcLoanAssets(api, allTokens, loanTypes, loans, loanRewards, incentives);
  const [tokensMap, lpTokensMap] = _calcFreeTokens(api, allTokens, nativeToken, tokens);
  const [lpStakedMap, lpFreemap, lpRewardsMap] = _calcLPAssets(api, allTokens, poolInfos, lpTokensMap, incentives);
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
function _addAsset(assetsMap: object, tokenSymbol: string, value: number) {
  if (assetsMap[tokenSymbol] == undefined) {
    assetsMap[tokenSymbol] = 0;
  }
  assetsMap[tokenSymbol] += value;
}
function _calcLoanAssets(api: ApiPromise, allTokens: any[], loanTypes: any[], loans: any[], loanRewards: any[], incentives: any) {
  const karura_stable_coin = "KUSD";
  const res = {};
  const rewardsMap = {};
  loans.forEach((e) => {
    const currencyId = api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, e.currency);
    const tokenNameId = forceToCurrencyName(currencyId);
    _addAsset(res, _getTokenSymbol(allTokens, tokenNameId), FPNum(e.collateral, _getTokenDecimal(allTokens, tokenNameId)).toNumber());
    _addAsset(
      res,
      karura_stable_coin,
      0 -
        FPNum(e.debit, _getTokenDecimal(allTokens, karura_stable_coin))
          .times(FPNum(loanTypes.find((t) => t.currency.toString() == e.currency.toString()).debitExchangeRate))
          .toNumber()
    );

    const reward = loanRewards.find((e) => e.tokenNameId === tokenNameId);
    if (!!reward && !!incentives.Loans[tokenNameId]) {
      const loyalty = incentives.Loans[tokenNameId][0].deduction;
      reward.reward.forEach((i) => {
        _addAsset(rewardsMap, "KAR", i.amount * (1 - loyalty));
      });
    }
  });
  return [res, rewardsMap];
}
function _calcFreeTokens(api: ApiPromise, allTokens: any[], native: any, tokens: any[]) {
  const res = {};
  const lpTokens = {};

  res[native_token] = FPNum(native.data.free.add(native.data.reserved), _getTokenDecimal(allTokens, native_token)).toNumber();
  tokens.forEach(
    ([
      {
        args: [_, currency],
      },
      v,
    ]) => {
      const tokenHuman = currency.toHuman();
      if (!!tokenHuman["DexShare"]) {
        const tokenNameId = createDexShareName(
          forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, tokenHuman["DexShare"][0])),
          forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, tokenHuman["DexShare"][1]))
        );
        lpTokens[tokenNameId] = v.free.add(v.reserved);
      } else {
        const tokenNameId = forceToCurrencyName(api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, currency));
        _addAsset(
          res,
          _getTokenSymbol(allTokens, tokenNameId),
          FPNum(v.free.add(v.reserved), _getTokenDecimal(allTokens, tokenNameId)).toNumber()
        );
      }
    }
  );
  return [res, lpTokens];
}
function _calcLPAssets(api: ApiPromise, allTokens: any[], poolInfos: any[], lpTokensMap: any, incentives: any) {
  const res = {};
  const lpTokensFree = {};
  const lpRewards = {};

  poolInfos.map((e) => {
    const currencyId0 = api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, e.tokenPair[0]);
    const currencyId1 = api.createType("AcalaPrimitivesCurrencyCurrencyId" as any, e.tokenPair[1]);
    const pair0 = forceToCurrencyName(currencyId0);
    const pair1 = forceToCurrencyName(currencyId1);
    const poolNameId = createDexShareName(pair0, pair1);
    const decimalPair = [_getTokenDecimal(allTokens, pair0), _getTokenDecimal(allTokens, pair1)];
    [e.shares, lpTokensMap[poolNameId]].forEach((amount, i) => {
      if (!!amount && amount.gt(new BN(0))) {
        const proportion = FPNum(amount).div(FPNum(e.issuance));
        [pair0, pair1].forEach((tokenNameId, index) => {
          _addAsset(
            i === 0 ? res : lpTokensFree,
            _getTokenSymbol(allTokens, tokenNameId),
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

    const loyalty = incentives.Dex[poolNameId] ? incentives.Dex[poolNameId][0].deduction : 0;
    const savingLoyalty = !!incentives.DexSaving[poolNameId] ? incentives.DexSaving[poolNameId][0].deduction : 0;
    e.reward.incentive.forEach((i) => {
      _addAsset(lpRewards, _getTokenSymbol(allTokens, i.tokenNameId), i.amount * (1 - loyalty));
    });
    if ((e.reward.saving || 0) > 0) {
      _addAsset(lpRewards, "KUSD", (e.reward.saving || 0) * (1 - savingLoyalty));
    }
  });
  return [res, lpTokensFree, lpRewards];
}

function _formatHomaEnv(env: HomaEnvironment) {
  return {
    totalStaking: env.totalStaking.toNumber(),
    totalLiquidity: env.totalLiquidity.toNumber(),
    exchangeRate: env.exchangeRate.toNumber(),
    apy: env.apy,
    fastMatchFeeRate: env.fastMatchFeeRate.toNumber(),
    mintThreshold: env.mintThreshold.toNumber(),
    redeemThreshold: env.redeemThreshold.toNumber(),
    stakingSoftCap: env.stakingSoftCap.toNumber(),
    eraFrequency: env.eraFrequency,
  };
}

async function queryHomaNewEnv(api: ApiPromise) {
  if (!homa) {
    homa = new Homa(api, (<any>window).wallet);
  }

  const result = await homa.getEnv();
  return _formatHomaEnv(result);
}

async function calcHomaNewMintAmount(api: ApiPromise, amount: number) {
  if (!homa) {
    homa = new Homa(api, (<any>window).wallet);
  }
  const result = await homa.getEstimateMintResult(new FixedPointNumber(amount, KSM_DECIMAL));

  return {
    pay: result.pay.toNumber(),
    receive: result.receive.toChainData().toString(),
    env: _formatHomaEnv(result.env),
  };
}

async function calcHomaNewRedeemAmount(api: ApiPromise, amount: number, isFastRedeem: boolean) {
  if (!homa) {
    homa = new Homa(api, (<any>window).wallet);
  }

  const result = await homa.getEstimateRedeemResult(new FixedPointNumber(amount, KSM_DECIMAL), isFastRedeem);
  return {
    request: result.request.toNumber(),
    receive: result.receive.toNumber(),
    fee: result.fee.toNumber(),
    canTryFastRedeem: result.canTryFastRedeem,
    env: _formatHomaEnv(result.env),
  };
}

async function queryHomaPendingRedeem(api: ApiPromise, address: string) {
  if (!homa) {
    homa = new Homa(api, (<any>window).wallet);
  }

  const result = await homa.getUserLiquidTokenSummary(address);
  return {
    totalUnbonding: result.totalUnbonding.toNumber(),
    claimable: result.claimable.toNumber(),
    unbondings: result.unbondings.map((e) => ({ era: e.era, amount: e.amount.toNumber() })),
    redeemRequest: {
      amount: result.redeemRequest.amount.toChainData(),
      fastRedeem: result.redeemRequest.fastRedeem,
    },
    currentRelayEra: result.currentRelayEra,
  };
}

async function queryDexIncentiveLoyaltyEndBlock(api: ApiPromise) {
  const data = await api.query.scheduler.agenda.entries();

  const result: { blockNumber: number; pool: any }[] = [];
  const loyalty: { blockNumber: number; pool: any }[] = [];

  data.forEach(([key, value]) => {
    const blockNumber = key.args[0].toNumber();

    const inner = (data: any) => {
      data = data.asValue ? data.asValue : data;

      const call = api.createType("Call", data.callIndex);

      if (call.method === "updateClaimRewardDeductionRates" && call.section === "incentives") {
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
        const args = data.args as any;

        args.forEach((i) => {
          i.forEach((item) => {
            const ratio = item[1].toString();

            if (ratio === "0") {
              loyalty.push({
                blockNumber,
                pool: item[0],
              });
            }
          });
        });
      }

      if (call.method === "updateIncentiveRewards" && call.section === "incentives") {
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
        const args = data.args as any;

        args.forEach((i) => {
          i.forEach((item) => {
            const amount = item[1][0][1].toString();

            if (amount === "0") {
              result.push({
                blockNumber,
                pool: item[0],
              });
            }
          });
        });
      }

      if (call.method === "batchAll" && call.section === "utility") {
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
        ((data.args[0] as any) as any[]).forEach((item) => inner(item));
      }
    };

    value.forEach((item) => inner(item.unwrapOrDefault().call));
  });

  return { result, loyalty };
}

export default {
  getSwapTokens,
  calcTokenSwapAmount,
  getAllTokens,
  getTokenBalance,
  getTokenPairs,
  getTaigaTokenPairs,
  getTaigaPoolInfo,
  getBootstraps,
  fetchCollateralRewards,
  fetchDexPoolInfo,
  fetchHomaUserInfo,
  queryNFTs,
  queryIncentives,
  queryAggregatedAssets,

  // homa new
  queryHomaNewEnv,
  calcHomaNewMintAmount,
  calcHomaNewRedeemAmount,
  queryHomaPendingRedeem,

  queryDexIncentiveLoyaltyEndBlock,

  getBlockDuration: async () => ACA_SYS_BLOCK_TIME.toNumber(),
};
