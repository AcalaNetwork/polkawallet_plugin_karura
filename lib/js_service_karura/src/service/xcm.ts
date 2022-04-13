import { Wallet } from "@acala-network/sdk";
import { ApiPromise, WsProvider } from "@polkadot/api";
import { decodeAddress } from "@polkadot/util-crypto";
import { u8aToHex } from "@polkadot/util";

interface ChainData {
  name: string;
  paraChainId: number;
}

const chain_name_karura = "karura";
const chain_name_kusama = "kusama";
const chain_name_statemine = "statemine";
const chain_name_kint = "kintsugi";
const chain_name_parallel = "parallel";
const chain_name_khala = "khala";
const chain_name_quart = "quartz";
const chain_name_moon = "moonriver";
const chainNodes = {
  [chain_name_kusama]: [
    "wss://pub.elara.patract.io/kusama",
    "wss://kusama-rpc.polkadot.io/",
    "wss://kusama.api.onfinality.io/public-ws",
    "wss://kusama.geometry.io/websockets",
    "wss://kusama-rpc.dwellir.com",
  ],
  [chain_name_statemine]: ["wss://kusama-statemine-rpc.paritytech.net", "wss://statemine.api.onfinality.io/public-ws"],
  [chain_name_kint]: ["wss://kintsugi.api.onfinality.io/public-ws", "wss://api-kusama.interlay.io/parachain"],
  [chain_name_parallel]: ["wss://parallel-heiko.api.onfinality.io/public-ws", "wss://heiko-rpc.parallel.fi"],
  [chain_name_khala]: ["wss://khala.api.onfinality.io/public-ws", "wss://khala-api.phala.network/ws"],
  [chain_name_quart]: [
    "wss://quartz.api.onfinality.io/public-ws",
    "wss://quartz.unique.network",
    "wss://eu-ws-quartz.unique.network",
    "wss://us-ws-quartz.unique.network",
  ],
};
const xcm_dest_weight_v2 = "5000000000";

const xcmApi: Record<string, ApiPromise> = {};
// let xcmApi: ApiPromise;
let wallet: Wallet;

function getApi(chainName: string) {
  return xcmApi[chainName];
}

async function _connect(nodes: string[], chainName: string) {
  return new Promise(async (resolve, reject) => {
    const wsProvider = new WsProvider(nodes);
    try {
      const res = await ApiPromise.create({
        provider: wsProvider,
      });
      if (!xcmApi[chainName]) {
        xcmApi[chainName] = res;
        (<any>window).send("log", `${chainName} wss connected success`);
        resolve(chainName);
      } else {
        res.disconnect();
        (<any>window).send("log", `${chainName} wss success and disconnected`);
        resolve(chainName);
      }
    } catch (err) {
      (<any>window).send("log", `connect failed`);
      wsProvider.disconnect();
      resolve(null);
    }
  });
}

async function connectFromChain(chainName: string[]) {
  return Promise.all(chainName.map((e) => _connectFromChain(e)));
}

async function _connectFromChain(chainName: string) {
  if (!chainNodes[chainName]) return null;

  if (!wallet) {
    wallet = new Wallet((<any>window).api);
    await wallet.isReady;
  }

  return Promise.race(chainNodes[chainName].map((node) => _connect([node], chainName)));
}

async function disconnectFromChain(chainName: string[]) {
  chainName.map((e) => {
    if (!!xcmApi[e]) {
      xcmApi[e].disconnect();
      xcmApi[e] = undefined;
    }
  });
}

async function getBalances(chainName: string, address: string, tokenNames: string[]) {
  return Promise.all(tokenNames.map((e) => _getTokenBalance(chainName, address, e)));
}

async function _getTokenBalance(chain: string, address: string, tokenNameId: string) {
  const api = xcmApi[chain];
  if (!api) return null;

  const token = await wallet.getToken(tokenNameId);
  if (chain.match(chain_name_statemine)) {
    const res = await api.query.assets.account(token.locations?.generalIndex, address);
    return {
      amount: res.toJSON()["balance"].toString(),
      tokenNameId,
      decimals: token.decimals,
    };
  }

  if (chain.match(chain_name_kint) && tokenNameId === "KINT") {
    const res = await api.query.tokens.accounts(address, { Token: "KINT" });
    return {
      amount: (res as any)?.free?.toString(),
      tokenNameId,
      decimals: token.decimals,
    };
  }

  if (chain.match(chain_name_parallel) && token.symbol !== "HKO") {
    const tokenIds: Record<string, number> = {
      KAR: 107,
      KUSD: 103,
      LKSM: 109,
    };

    if (!tokenIds[token.name]) return null;

    const res = await api.query.assets.account(tokenIds[token.name], address);
    return {
      amount: (res as any).unwrapOrDefault().balance.toString(),
      tokenNameId,
      decimals: token.decimals,
    };
  }

  if (chain.match(chain_name_khala) && tokenNameId !== "PHA") {
    const tokenIds: Record<string, number> = {
      KAR: 1,
      KUSD: 4,
    };

    if (!tokenIds[token.name]) return null;

    const res = await api.query.assets.account(tokenIds[token.name], address);
    return {
      amount: (res as any).unwrapOrDefault().balance.toString(),
      tokenNameId,
      decimals: token.decimals,
    };
  }

  // for kusama/polkadot/khala-pha/heiko-hko
  const res = await api.derive.balances.all(address);
  return {
    amount: res.availableBalance.toString(),
    tokenNameId,
    decimals: token.decimals,
  };
}

async function getTansferParams(chainFrom: ChainData, chainTo: ChainData, tokenName: string, amount: string, addressTo: string) {
  if (!wallet) {
    wallet = new Wallet((<any>window).api);
    await wallet.isReady;
  }

  const token = await wallet.getToken(tokenName);

  // from karura
  if (chainFrom.name === chain_name_karura) {
    let dst: any;
    if (chainTo.name === chain_name_kusama) {
      // to relay-chain
      dst = { parents: 1, interior: { X1: { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } } } };
    } else if (chainTo.name === chain_name_moon) {
      // to moon river
      dst = {
        parents: 1,
        interior: {
          X2: [{ Parachain: token.locations?.paraChainId }, { AccountKey20: { key: addressTo, network: "Any" } }],
        },
      };
      return {
        module: "xTokens",
        call: "transferMulticurrencies",
        params: [
          [
            [token.toChainData(), amount],
            [{ Token: "KAR" }, 9880000000],
          ],
          1,
          dst,
          xcm_dest_weight_v2,
        ],
      };
    } else {
      // to other parachains
      dst = {
        parents: 1,
        interior: {
          X2: [{ Parachain: token.locations?.paraChainId }, { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } }],
        },
      };
    }

    return chainTo.name === chain_name_statemine
      ? {
          module: "xTokens",
          call: "transferMulticurrencies",
          params: [
            [
              [token.toChainData(), amount],
              [{ Token: "KSM" }, 16000000000],
            ],
            1,
            dst,
            xcm_dest_weight_v2,
          ],
        }
      : {
          module: "xTokens",
          call: "transfer",
          params: [token.toChainData() as any, amount, { V1: dst }, xcm_dest_weight_v2],
        };
  }

  // from other chains to karura
  // kusama
  if (chainFrom.name === chain_name_kusama && tokenName.toLowerCase() === "ksm") {
    const dst = { X1: { ParaChain: chainTo.paraChainId }, parents: 0 };
    const acc = { X1: { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } } };
    const ass = [{ ConcreteFungible: { amount } }];

    return {
      module: "xcmPallet",
      call: "reserveTransferAssets",
      params: [{ V0: dst }, { V0: acc }, { V0: ass }, 0],
    };
  }

  // statemine
  if (chainFrom.name === chain_name_statemine && chainTo.name === chain_name_karura) {
    const dst = { X2: ["Parent", { ParaChain: chainTo.paraChainId }] };
    const acc = { X1: { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } } };
    const ass = [
      {
        ConcreteFungible: {
          id: { X2: [{ PalletInstance: token.locations?.palletInstance }, { GeneralIndex: token.locations?.generalIndex }] },
          amount,
        },
      },
    ];

    return {
      module: "polkadotXcm",
      call: "limitedReserveTransferAssets",
      params: [{ V0: dst }, { V0: acc }, { V0: ass }, 0, "Unlimited"],
    };
  }

  // kintsugi
  if (chainFrom.name === chain_name_kint && chainTo.name === chain_name_karura) {
    const dst = {
      parents: 1,
      interior: {
        X2: [{ Parachain: chainTo.paraChainId }, { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } }],
      },
    };

    return {
      module: "xTokens",
      call: "transfer",
      params: [token.toChainData() as any, amount, { V1: dst }, xcm_dest_weight_v2],
    };
  }

  // parallel
  if (chainFrom.name === chain_name_parallel && chainTo.name === chain_name_karura) {
    const tokenIds: Record<string, number> = {
      HKO: 0,
      KAR: 107,
      KUSD: 103,
      LKSM: 109,
    };

    if (typeof tokenIds[token.symbol] === "undefined") return;

    const dst = {
      parents: 1,
      interior: { X2: [{ Parachain: chainTo.paraChainId }, { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } }] },
    };

    return {
      module: "xTokens",
      call: "transfer",
      params: [tokenIds[token.symbol], amount, { V1: dst }, xcm_dest_weight_v2],
    };
  }

  // khala
  if (chainFrom.name === chain_name_khala) {
    if (tokenName === "PHA") {
      const dst = {
        parents: 1,
        interior: { X2: [{ Parachain: chainTo.paraChainId }, { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } }] },
      };

      return {
        module: "xcmTransfer",
        call: "transferNative",
        params: [dst, amount, xcm_dest_weight_v2],
      };
    } else {
      const tokenIds: Record<string, string> = {
        KUSD: "0x0081",
        KAR: "0x0080",
      };

      const id = tokenIds[token.name];

      if (!id) return;

      const asset = { parents: 1, interior: { X2: [{ Parachain: chainTo.paraChainId }, { GeneralKey: id }] } };
      const dst = {
        parents: 1,
        interior: { X2: [{ Parachain: chainTo.paraChainId }, { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } }] },
      };

      return {
        module: "xcmTransfer",
        call: "transferAsset",
        params: [asset, dst, amount, xcm_dest_weight_v2],
      };
    }
  }

  //quartz
  if (chainFrom.name === chain_name_quart) {
    const dst = { X2: ["Parent", { ParaChain: chainTo.paraChainId }] };
    const acc = { X1: { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } } };
    const ass = [{ ConcreteFungible: { amount } }];

    return {
      module: "polkadotXcm",
      call: "limitedReserveTransferAssets",
      params: [{ V0: dst }, { V0: acc }, { V0: ass }, 0, "Unlimited"],
    };
  }

  return null;
}

export default { getApi, connectFromChain, disconnectFromChain, getBalances, getTansferParams };
