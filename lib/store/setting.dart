import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';

part 'setting.g.dart';

class SettingStore extends _SettingStore with _$SettingStore {
  SettingStore(StoreCache? cache) : super(cache);
}

abstract class _SettingStore with Store {
  _SettingStore(this.cache);

  final StoreCache? cache;

  @observable
  Map liveModules = Map();

  Map remoteConfig = {
    "modules": {
      "assets": {"visible": true, "enabled": true},
      "multiply": {"visible": true, "enabled": true},
      "loan": {"visible": true, "enabled": true},
      "swap": {"visible": true, "enabled": true},
      "earn": {"visible": true, "enabled": true},
      "homa": {"visible": true, "enabled": true},
      "nft": {"visible": true, "enabled": true}
    },
    "tokens": {
      "default": ["KUSD", "KSM", "LKSM", "BNC", "fa://0"],
      "tokenName": {
        "KUSD": "",
        "KSM": "Kusama",
        "LKSM": "Liquid KSM",
        "BNC": "Bifrost",
        "VSKSM": "Bifrost Liquid KSM",
        "PHA": "Khala",
        "KINT": "kintsugi",
        "KBTC": "kintsugi BTC",
        "fa://1": "PolarisDAO",
        "fa://2": "Quartz",
        "fa://3": "Moonriver",
        "fa://4": "Heiko",
        "fa://6": "KICO",
        "fa://7": "Tether USD",
        "fa://8": "Integritee Trusted Execution Environment",
        "fa://9": "Metaverse.Network Pioneer",
        "fa://10": "Calamari",
        "fa://11": "Basilisk",
        "fa://12": "Altair",
        "fa://13": "Crab Parachain Token",
        "fa://14": "Genshiro Native Token",
        "fa://15": "Equilibrium USD",
        "fa://16": "Turing"
      },
      "xcm": {
        "KAR": [
          "calamari",
          "khala",
          "bifrost",
          "parallel heiko",
          "moonriver",
          "kico"
        ],
        "KSM": ["kusama"],
        "BNC": ["bifrost"],
        "VSKSM": ["bifrost"],
        "fa://0": [],
        "fa://7": [],
        "LKSM": ["calamari", "parallel heiko"],
        "KUSD": [
          "altair",
          "calamari",
          "khala",
          "parallel heiko",
          "kico",
          "moonriver"
        ],
        "PHA": ["khala"],
        "KINT": ["kintsugi"],
        "KBTC": ["kintsugi"],
        "fa://1": [],
        "fa://2": ["quartz"],
        "fa://3": ["moonriver"],
        "fa://4": ["parallel heiko"],
        "fa://5": ["crust shadow"],
        "fa://6": ["kico"],
        "fa://10": ["calamari"],
        "fa://8": ["integritee"],
        "fa://12": ["altair"]
      },
      "xcmFrom": {
        "KSM": ["kusama"],
        "PHA": ["khala"],
        "KUSD": ["altair", "calamari", "khala", "parallel heiko", "kico"],
        "KAR": ["calamari", "khala", "parallel heiko", "kico"],
        "LKSM": ["calamari", "parallel heiko"],
        "BNC": ["bifrost"],
        "fa://0": [],
        "fa://7": [],
        "fa://1": [],
        "fa://2": ["quartz"],
        "fa://4": ["parallel heiko"],
        "fa://5": ["crust shadow"],
        "KINT": ["kintsugi"],
        "KBTC": ["kintsugi"],
        "fa://6": ["kico"],
        "fa://10": ["calamari"],
        "fa://8": ["integritee"],
        "fa://12": ["altair"]
      },
      "xcmInfo": {
        "kusama": {
          "KSM": {
            "fee": "79999999",
            "receiveFee": "64000000",
            "existentialDeposit": "33333333"
          }
        },
        "bifrost": {
          "KAR": {"fee": "4800000000", "existentialDeposit": "148000000"},
          "KSM": {"fee": "64000000", "existentialDeposit": "100000000"},
          "KUSD": {"fee": "25600000000", "existentialDeposit": "100000000"},
          "BNC": {"fee": "5120000000", "existentialDeposit": "10000000000"},
          "VSKSM": {"fee": "64000000", "existentialDeposit": "100000000"}
        },
        "statemine": {
          "RMRK": {
            "fee": "0",
            "receiveFee": "6400000",
            "sendFee": [
              {"Token": "KSM"},
              "16000000000"
            ],
            "existentialDeposit": "100000000"
          },
          "USDT": {
            "fee": "0",
            "receiveFee": "64",
            "sendFee": [
              {"Token": "KSM"},
              "16000000000"
            ],
            "existentialDeposit": "1000"
          },
          "ARIS": {
            "fee": "0",
            "receiveFee": "6400000",
            "sendFee": [
              {"Token": "KSM"},
              "16000000000"
            ],
            "existentialDeposit": "10000000"
          }
        },
        "quartz": {
          "QTZ": {
            "fee": "0",
            "receiveFee": "64000000000000000",
            "existentialDeposit": "1000000000000000000"
          }
        },
        "kintsugi": {
          "KINT": {
            "fee": "170666666",
            "receiveFee": "170666666",
            "existentialDeposit": "0"
          },
          "KBTC": {"fee": "85", "receiveFee": "85", "existentialDeposit": "0"}
        },
        "parallel heiko": {
          "KAR": {
            "fee": "2400000000",
            "receiveFee": "6400000000",
            "existentialDeposit": "0"
          },
          "KUSD": {
            "fee": "19200000000",
            "receiveFee": "8305746640",
            "existentialDeposit": "0"
          },
          "LKSM": {
            "fee": "48000000",
            "receiveFee": "589618748",
            "existentialDeposit": "0"
          },
          "HKO": {
            "fee": "1440000000",
            "receiveFee": "6400000000",
            "existentialDeposit": "100000000000"
          }
        },
        "khala": {
          "PHA": {
            "fee": "64000000000",
            "receiveFee": "51200000000",
            "existentialDeposit": "40000000000"
          },
          "KUSD": {
            "fee": "16000000000",
            "receiveFee": "4616667257",
            "existentialDeposit": "10000000000"
          },
          "KAR": {
            "fee": "8000000000",
            "receiveFee": "6400000000",
            "existentialDeposit": "10000000000"
          }
        },
        "moonriver": {
          "MOVR": {
            "fee": "80000000000000",
            "existentialDeposit": "1000000000000000"
          },
          "KAR": {"fee": "9880000000", "existentialDeposit": "0"},
          "KUSD": {"fee": "16536000000", "existentialDeposit": "0"}
        },
        "kico": {
          "KICO": {
            "fee": "96000000000",
            "receiveFee": "6400000000000",
            "existentialDeposit": "100000000000000"
          },
          "KAR": {
            "fee": "160000000000",
            "receiveFee": "6400000000",
            "existentialDeposit": "0"
          },
          "KUSD": {
            "fee": "320000000000",
            "receiveFee": "10011896008",
            "existentialDeposit": "0"
          }
        },
        "crust shadow": {
          "CSM": {
            "fee": "4000000000",
            "receiveFee": "64000000000",
            "existentialDeposit": "1000000000000"
          }
        },
        "calamari": {
          "KMA": {
            "fee": "4000000",
            "receiveFee": "6400000000",
            "existentialDeposit": "100000000000"
          },
          "KUSD": {
            "fee": "100000000000",
            "receiveFee": "6381112603",
            "existentialDeposit": "10000000000"
          },
          "KAR": {
            "fee": "100000000000",
            "receiveFee": "6400000000",
            "existentialDeposit": "100000000000"
          },
          "LKSM": {
            "fee": "7692307692",
            "receiveFee": "452334406",
            "existentialDeposit": "500000000"
          },
          "KSM": {
            "fee": "666666666",
            "receiveFee": "54632622",
            "existentialDeposit": "100000000"
          }
        },
        "integritee": {
          "TEER": {
            "fee": "4000000",
            "receiveFee": "6400000000",
            "existentialDeposit": "100000000000"
          }
        },
        "altair": {
          "AIR": {
            "fee": "6400000000000000",
            "receiveFee": "6400000000000000",
            "existentialDeposit": "1000000000000"
          },
          "KUSD": {
            "fee": "51200000000",
            "receiveFee": "3481902463",
            "existentialDeposit": "10000000000"
          }
        },
        "crab": {
          "CRAB": {
            "fee": "4000000000",
            "receiveFee": "64000000000000000",
            "existentialDeposit": "0"
          }
        },
        "turing": {
          "KAR": {
            "fee": "32000000000",
            "receiveFee": "6400000000",
            "existentialDeposit": "100000000000"
          },
          "KUSD": {
            "fee": "256000000000",
            "receiveFee": "2626579278",
            "existentialDeposit": "10000000000"
          },
          "LKSM": {
            "fee": "6400000000",
            "receiveFee": "480597195",
            "existentialDeposit": "500000000"
          },
          "TUR": {
            "fee": "1664000000",
            "receiveFee": "2560000000",
            "existentialDeposit": "100000000"
          }
        }
      },
      "xcmSendFee": {
        "statemine": [
          {"Token": "KSM"},
          "16000000000"
        ],
        "moonriver": [
          {"Token": "KAR"},
          "9880000000"
        ]
      },
      "xcmChains": {
        "karura": {"id": "2000", "nativeToken": "KAR", "ss58": 8},
        "kusama": {"id": "0", "nativeToken": "KSM", "ss58": 2},
        "statemine": {"id": "1000", "nativeToken": "KSM", "ss58": 2},
        "bifrost": {"id": "2001", "nativeToken": "BNC", "ss58": 6},
        "khala": {"id": "2004", "nativeToken": "PHA", "ss58": 30},
        "quartz": {"id": "2095", "nativeToken": "QTZ", "ss58": 255},
        "kintsugi": {"id": "2092", "nativeToken": "KINT", "ss58": 2092},
        "moonriver": {"id": "2023", "nativeToken": "MOVR", "ss58": 1285},
        "parallel heiko": {"id": "2085", "nativeToken": "HKO", "ss58": 110},
        "kico": {"id": "2107", "nativeToken": "KICO", "ss58": 42},
        "crust shadow": {"id": "2012", "nativeToken": "CSM", "ss58": 66},
        "calamari": {"id": "2084", "nativeToken": "KMA", "ss58": 78},
        "integritee": {"id": "2015", "nativeToken": "TEER", "ss58": 13},
        "altair": {"id": "2088", "nativeToken": "AIR", "ss58": 136},
        "crab": {"id": "2105", "nativeToken": "CRAB", "ss58": 42},
        "turing": {"id": "2114", "nativeToken": "TUR", "ss58": 51}
      },
      "invisible": [],
      "disabled": []
    }
  };

  @action
  void setLiveModules(Map value) {
    liveModules = value;
  }

  void setRemoteConfig(Map config) {
    remoteConfig = config;
  }
}
