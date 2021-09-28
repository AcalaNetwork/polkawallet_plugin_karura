import { FixedPointNumber, Token, createLPCurrencyName, forceToCurrencyIdName } from "@acala-network/sdk-core";
import { SwapPromise } from "@acala-network/sdk-swap";
import { ApiPromise } from "@polkadot/api";
import { hexToString } from "@polkadot/util";
import { nft_image_config, tokensForKarura } from "../constants/acala";
import { BN } from "@polkadot/util/bn/bn";
import { WalletPromise } from "@acala-network/sdk-wallet";
import axios from "axios";
import { IncentiveResult } from "../types/acalaTypes";

const ONE = FixedPointNumber.ONE;
const ACA_SYS_BLOCK_TIME = new BN(12000);
const SECONDS_OF_YEAR = new BN(365 * 24 * 3600);

let walletPromise: WalletPromise;

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

  const inputToken = Token.fromCurrencyId(api.createType("CurrencyId" as any, { token: swapPair[0] }), _getTokenDecimal(api, swapPair[0]));
  const outputToken = Token.fromCurrencyId(api.createType("CurrencyId" as any, { token: swapPair[1] }), _getTokenDecimal(api, swapPair[1]));
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
            priceImpact: res.priceImpact.toNumber(6),
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
    api.createType("CurrencyId" as any, {
      DEXShare: [item[0].asToken.toString(), item[1].asToken.toString()],
    })
  );

  const res = await api.queryMulti(allTokens.map((e) => [api.query.tokens.accounts, [address, e]]));
  return (res as any)
    .map((e: any, i: number) => ({ free: e.free.toString(), currencyId: allTokens[i].asDexShare }))
    .filter((e: any) => e.free > 0);
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
          decimals: pairDecimals[0] > pairDecimals[1] ? pairDecimals[0] : pairDecimals[1],
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

async function getAllTokenSymbols() {
  const allTokens: any[] = (<any>window).api.registry.chainTokens;
  return tokensForKarura.filter((e) => allTokens.indexOf(e.token) > -1);
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
  const res = (await Promise.all([
    api.query.dex.liquidityPool(pool.DEXShare),
    api.query.rewards.pools({ DexIncentive: pool }),
    api.query.rewards.pools({ DexSaving: pool }),
    api.query.rewards.shareAndWithdrawnReward({ DexIncentive: pool }, address),
    api.query.rewards.shareAndWithdrawnReward({ DexSaving: pool }, address),
    api.query.tokens.totalIssuance(pool),
  ])) as any;
  const pendingRewards = (!!api.query.incentives.pendingRewards
    ? await Promise.all([
        api.query.incentives?.pendingRewards({ DexIncentive: pool }, address),
        api.query.incentives?.pendingRewards({ DexSaving: pool }, address),
      ])
    : [null, null]) as any;
  let proportion = new FixedPointNumber(0);
  if (res[1] && res[3] && FPNum(res[1].totalShares).gt(new FixedPointNumber(0))) {
    proportion = FPNum(res[3][0]).div(FPNum(res[1].totalShares));
  }
  const decimalsACA = 12;
  const decimalsAUSD = 12;
  return {
    token: pool.DEXShare.map((e) => e.Token).join("-"),
    pool: res[0],
    sharesTotal: res[1].totalShares,
    shares: res[3][0],
    proportion: proportion.toNumber() || 0,
    reward: {
      incentive: (
        FPNum(res[1].totalRewards, decimalsACA)
          .times(proportion)
          .minus(FPNum(res[3][1], decimalsACA))
          .plus(FPNum(pendingRewards[0] || 0, decimalsACA))
          .toNumber() || 0
      ).toString(),
      saving: (
        FPNum(res[2].totalRewards, decimalsAUSD)
          .times(proportion)
          .minus(FPNum(res[4][1], decimalsAUSD))
          .plus(FPNum(pendingRewards[1] || 0, decimalsAUSD))
          .toNumber() || 0
      ).toString(),
    },
    issuance: res[5],
  };
}

/**
 * fetchDexPoolInfo
 * @param {String} poolId
 * @param {String} address
 */
async function fetchDexPoolInfoV2(api: ApiPromise, pool: any, address: string) {
  if (!walletPromise) {
    walletPromise = new WalletPromise(api);
  }
  const res = (await Promise.all([
    api.query.dex.liquidityPool(pool.DEXShare),
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
    token: pool.DEXShare.map((e) => e.Token).join("-"),
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
async function _transformClassInfo(id: number, data: any): Promise<Omit<any, "tokenId">> {
  const cid = hexToString(data.metadata.toString());
  const properties = (data.data.properties.toJSON() as unknown) as any[];
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

    const data = metadataResult.data;

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
      return [api.query.ormlNft.classes, id];
    })
  );
  const infos = await Promise.all(classes.map((e: any, i) => _transformClassInfo(i, e.unwrapOrDefault())));
  const data = await Promise.all(
    NFT_CLASS_ALL.map((id) => {
      return api.query.ormlNft.tokensByOwner.entries(address, id);
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

  const deposits = await Promise.all(res.map((e) => api.query.ormlNft.tokens(e.classId, e.tokenId)));
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
    const idString = incentiveType === "Dex" ? id["DEXShare"].map((e: any) => e["Token"]).join("-") : id["Token"];

    return { incentiveType, idString, value: FPNum(e[1], 18).toString() };
  });
  pools[0].forEach((e, i) => {
    const poolId = e[0].args[0].toHuman();
    const incentiveType = Object.keys(poolId)[0];
    const id = poolId[incentiveType];
    const idString = incentiveType === "Dex" ? id["DEXShare"].map((e: any) => e["Token"]).join("-") : id["Token"];
    const incentiveToken = e[0].args[1];
    const incentiveTokenView = incentiveToken.toHuman()["Token"];
    const incentiveTokenDecimal = walletPromise.getToken(incentiveToken).decimal;

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
    const id = poolId["Dex"]["DEXShare"].map((e: any) => e["Token"]).join("-");

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

export default {
  calcTokenSwapAmount,
  queryLPTokens,
  getTokenPairs,
  getBootstraps,
  getAllTokenSymbols,
  fetchCollateralRewards,
  fetchCollateralRewardsV2,
  fetchDexPoolInfo,
  fetchDexPoolInfoV2,
  fetchHomaUserInfo,
  queryNFTs,
  checkExistentialDepositForTransfer,
  queryIncentives,
};
