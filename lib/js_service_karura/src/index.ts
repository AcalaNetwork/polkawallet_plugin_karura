import { WsProvider, ApiPromise, ApiRx } from "@polkadot/api";
import { subscribeMessage, getNetworkConst, getNetworkProperties } from "./service/setting";
import keyring from "./service/keyring";
import { options } from "@acala-network/api";
import { Wallet } from "@acala-network/sdk";
import account from "./service/account";
import acala from "./service/acala";
import gov from "./service/gov";
import xcm from "./service/xcm";
import { genLinks } from "./utils/config/config";

// console.log will send message to MsgChannel to App
function send(path: string, data: any) {
  console.log(JSON.stringify({ path, data }));
}
send("log", "acala main js loaded");
(<any>window).send = send;

async function connectAll(nodes: string[]) {
  return Promise.race(nodes.map((node) => connect([node])));
}

async function connect(nodes: string[]) {
  (<any>window).api = undefined;

  return new Promise(async (resolve, reject) => {
    const wsProvider = new WsProvider(nodes);
    try {
      const res = new ApiPromise(options({ provider: wsProvider }));
      await res.isReady;
      if (!(<any>window).api) {
        (<any>window).api = res;
        (<any>window).apiRx = new ApiRx(options({ provider: wsProvider }));
        // console.log(res);
        const url = nodes[(<any>res)._options.provider.__private_40_endpointIndex];
        send("log", `${url} wss connected success`);
        resolve(url);

        (<any>window).wallet = new Wallet(res, { wsProvider });
        (<any>window).wallet.isReady;
      } else {
        res.disconnect();
        const url = nodes[(<any>res)._options.provider.__private_40_endpointIndex];
        send("log", `${url} wss success and disconnected`);
        resolve(url);
      }
    } catch (err) {
      send("log", `connect failed`);
      wsProvider.disconnect();
      resolve(null);
    }
  });
}

(<any>window).settings = {
  connectAll,
  connect,
  getNetworkConst,
  getNetworkProperties,
  subscribeMessage,
  genLinks,
};
(<any>window).keyring = keyring;
(<any>window).account = account;
(<any>window).acala = acala;
(<any>window).gov = gov;
(<any>window).xcm = xcm;
