import { StakingPool } from "@acala-network/sdk-homa";
import { FixedPointNumber, Token, createLPCurrencyName } from "@acala-network/sdk-core";
import { SwapPromise } from "@acala-network/sdk-swap";
import { ApiPromise } from "@polkadot/api";
import { hexToString } from "@polkadot/util";
import { nft_image_config, tokensForKarura } from "../constants/acala";
import { BN } from "@polkadot/util/bn/bn";
import { WalletPromise } from "@acala-network/sdk-wallet";
import axios from "axios";

const decimalsDOT = 10;
const ONE = FixedPointNumber.ONE;
const ACA_SYS_BLOCK_TIME = new BN(12000);

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
  if (res[0] && res[1]) {
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
  if (res[1] && res[3]) {
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

let homaStakingPool;

async function fetchHomaStakingPool(api: ApiPromise) {
  const [stakingPool, { mockRewardRate }] = (await Promise.all([
    (api.derive as any).homa.stakingPool(),
    api.query.polkadotBridge.subAccounts(1),
  ])) as any;

  const poolInfo = new StakingPool({
    decimal: decimalsDOT,
    params: {
      baseFeeRate: FPNum(stakingPool.params.baseFeeRate),
      targetMaxFreeUnbondedRatio: FPNum(stakingPool.params.targetMaxFreeUnbondedRatio),
      targetMinFreeUnbondedRatio: FPNum(stakingPool.params.targetMinFreeUnbondedRatio),
      targetUnbondingToFreeRatio: FPNum(stakingPool.params.targetUnbondingToFreeRatio),
    },
    defaultExchangeRate: FPNum(stakingPool.defaultExchangeRate),
    liquidTotalIssuance: FPNum(stakingPool.liquidIssuance, decimalsDOT),
    currentEra: stakingPool.currentEra.toNumber(),
    bondingDuration: stakingPool.bondingDuration.toNumber(),
    ledger: {
      toUnbondNextEra: stakingPool.ledger.toUnbondNextEra.map((e: any) => FPNum(e, decimalsDOT)),
      bonded: FPNum(stakingPool.ledger.bonded, decimalsDOT),
      unbondingToFree: FPNum(stakingPool.ledger.unbondingToFree, decimalsDOT),
      freePool: FPNum(stakingPool.ledger.freePool, decimalsDOT),
    },
  });
  homaStakingPool = poolInfo;

  const freeList = await _calacFreeList(api, stakingPool.currentEra.toNumber() + 1, stakingPool.bondingDuration.toNumber(), decimalsDOT);
  const eraLength = api.consts.polkadotBridge.eraLength as any;
  const expectedBlockTime = api.consts.babe?.expectedBlockTime || ACA_SYS_BLOCK_TIME;
  const unbondingDuration = expectedBlockTime.toNumber() * eraLength.toNumber() * stakingPool.bondingDuration.toNumber();
  return {
    // ...stakingPoolHelper,
    rewardRate: mockRewardRate.toString(),
    freeList,
    unbondingDuration,
    liquidTokenIssuance: stakingPool.liquidIssuance.toString(),
    defaultExchangeRate: FPNum(stakingPool.defaultExchangeRate).toNumber(),
    bondingDuration: stakingPool.bondingDuration.toNumber(),
    currentEra: stakingPool.currentEra.toNumber(),
    communalBonded: poolInfo.bondedBelongToLiquidHolders.toNumber(),
    communalTotal: poolInfo.totalBelongToLiquidHolders.toNumber(),
    freePool: poolInfo.freePool.toNumber(),
    unbondingToFree: poolInfo.unbondingToFree.toNumber(),
    communalBondedRatio: poolInfo.bondedBelongToLiquidHolders.div(poolInfo.total).toNumber(),
    liquidExchangeRate: poolInfo.liquidExchangeRate().toNumber(),
  };
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

async function queryHomaRedeemAmount(api: ApiPromise, amount: number, redeemType: number, targetEra: number) {
  if (redeemType == 0) {
    const res = await homaStakingPool.getStakingAmountInRedeemByFreeUnbonded(new FixedPointNumber(amount, decimalsDOT));
    return {
      demand: res.demand.toNumber(),
      fee: res.fee.toNumber(),
      received: res.received.toNumber(),
    };
  } else if (redeemType == 1) {
    const unbonding = await api.query.stakingPool.unbonding(targetEra);
    const res = await homaStakingPool.getStakingAmountInClaimUnbonding(new FixedPointNumber(amount, decimalsDOT), targetEra, {
      unbonding: FPNum(unbonding[0], decimalsDOT),
      claimedUnbonding: FPNum(unbonding[1], decimalsDOT),
      initialClaimedUnbonding: FPNum(unbonding[2], decimalsDOT),
    });
    return {
      atEra: res.atEra,
      demand: res.demand.toNumber(),
      fee: res.fee.toNumber(),
      received: res.received.toNumber(),
    };
  } else if (redeemType == 2) {
    const res = await homaStakingPool.getStakingAmountInRedeemByUnbond(new FixedPointNumber(amount, decimalsDOT));
    return {
      atEra: res.atEra,
      amount: res.amount.toNumber(),
    };
  }
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

let walletPromise: WalletPromise;
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

export default {
  calcTokenSwapAmount,
  queryLPTokens,
  getTokenPairs,
  getBootstraps,
  getAllTokenSymbols,
  fetchCollateralRewards,
  fetchDexPoolInfo,
  fetchHomaStakingPool,
  fetchHomaUserInfo,
  queryHomaRedeemAmount,
  queryNFTs,
  checkExistentialDepositForTransfer,
};
