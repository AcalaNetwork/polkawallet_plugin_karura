import 'package:polkawallet_plugin_karura/common/constants/base.dart';

const plugin_cache_key = 'plugin_karura';

const plugin_genesis_hash =
    '0xbaf5aabe40646d11f0ee8abbdc64f4a4b7674925cba08e4a05ff9ebed6e2126b';
const acala_price_decimals = 18;
const karura_stable_coin = 'KUSD';
const karura_stable_coin_view = 'kUSD';
const acala_token_ren_btc = 'RENBTC';
const acala_token_ren_btc_view = 'renBTC';
const acala_token_polka_btc = 'POLKABTC';
const acala_token_polka_btc_view = 'polkaBTC';
const foreign_token_RMRK = 'fa://0';
const foreign_token_ARIS = 'fa://1';
const foreign_token_QTZ = 'fa://2';
const foreign_token_MOVR = 'fa://3';

const relay_chain_name = 'kusama';
const para_chain_name_statemine = 'statemine';
const para_chain_name_bifrost = 'bifrost';
const para_chain_name_khala = 'khala';
const para_chain_name_kint = 'kintsugi';
const para_chain_name_quart = 'quartz';
const para_chain_name_moon = 'moonriver';
const para_chain_ids = {
  para_chain_name_statemine: 1000,
  para_chain_name_bifrost: 2001,
  para_chain_name_khala: 2004,
  para_chain_name_quart: 2095,
  para_chain_name_kint: 2092,
  para_chain_name_moon: 2023,
};

const network_ss58_format = {
  plugin_name_karura: 8,
  relay_chain_name: 2,
  para_chain_name_bifrost: 6,
  para_chain_name_khala: 30,
  para_chain_name_quart: 255,
  para_chain_name_kint: 2092,
  para_chain_name_moon: 1285,
};
const relay_chain_token_symbol = 'KSM';
const para_chain_token_symbol_bifrost = 'BNC';
const para_chain_token_symbol_khala = 'PHA';
const para_chain_token_symbol_kint = 'KINT';
const cross_chain_xcm_fees = {
  relay_chain_name: {
    relay_chain_token_symbol: {
      'fee': '79999999',
      'existentialDeposit': '33333333',
    },
  },
  para_chain_name_bifrost: {
    relay_chain_token_symbol: {
      'fee': '64000000',
      'existentialDeposit': '100000000',
    },
    karura_stable_coin: {
      'fee': '25600000000',
      'existentialDeposit': '100000000',
    },
    para_chain_token_symbol_bifrost: {
      'fee': '5120000000',
      'existentialDeposit': '10000000000',
    },
    'VSKSM': {
      'fee': '64000000',
      'existentialDeposit': '100000000',
    }
  },
  para_chain_name_khala: {
    para_chain_token_symbol_khala: {
      'fee': '800000000',
      'existentialDeposit': '10000000000',
    }
  },
  para_chain_name_statemine: {
    foreign_token_RMRK: {
      'fee': '16000000000',
      'existentialDeposit': '100000000',
    },
    foreign_token_ARIS: {
      'fee': '16000000000',
      'existentialDeposit': '10000000',
    }
  },
  para_chain_name_quart: {
    foreign_token_QTZ: {
      'fee': '0',
      'existentialDeposit': '1000000000000000000',
    }
  },
  para_chain_name_kint: {
    para_chain_token_symbol_kint: {
      'fee': '170666666',
      'existentialDeposit': '0',
    }
  }
};
const foreign_asset_xcm_dest_fee = '16000000000';
const xcm_dest_weight_v2 = '5000000000';

const acala_token_ids = [
  'KAR',
  'KUSD',
  'KSM',
  'LKSM',
  'BNC',
  'VSKSM',
  'PHA',
  'USDT',
  'KBTC',
  'KINT',
  'TAI',
  'TAIKSM',
  'RMRK',
  'ARIS',
  'QTZ',
  'MOVR',
  // 'RENBTC',
  // 'XBTC',
  // 'POLKABTC',
];
const default_tokens = [
  karura_stable_coin,
  relay_chain_token_symbol,
  'L$relay_chain_token_symbol',
  para_chain_token_symbol_bifrost,
  foreign_token_RMRK
];

const module_name_assets = 'assets';
const module_name_loan = 'loan';
const module_name_swap = 'swap';
const module_name_earn = 'earn';
const module_name_homa = 'homa';
const module_name_nft = 'nft';
const config_modules = {
  module_name_assets: {
    'visible': true,
    'enabled': true,
  },
  module_name_loan: {
    'visible': true,
    'enabled': true,
  },
  module_name_swap: {
    'visible': true,
    'enabled': true,
  },
  module_name_earn: {
    'visible': true,
    'enabled': true,
  },
  module_name_homa: {
    'visible': true,
    'enabled': true,
  },
  module_name_nft: {
    'visible': true,
    'enabled': true,
  },
};
const config_xcm = {
  relay_chain_token_symbol: [relay_chain_name],
  para_chain_token_symbol_bifrost: [para_chain_name_bifrost],
  "VSKSM": [para_chain_name_bifrost],
  foreign_token_RMRK: [para_chain_name_statemine],
  foreign_token_ARIS: [para_chain_name_statemine],
  foreign_token_QTZ: [para_chain_name_quart],
  para_chain_token_symbol_kint: [para_chain_name_kint],
  "KUSD": [],
  "PHA": []
};

const image_assets_uri = 'packages/polkawallet_plugin_karura/assets/images';

const cross_chain_icons = {
  plugin_name_karura: '$image_assets_uri/tokens/KAR.png',
  relay_chain_name: '$image_assets_uri/tokens/KSM.png',
  para_chain_name_bifrost: '$image_assets_uri/tokens/BNC.png',
  para_chain_name_khala: '$image_assets_uri/tokens/PHA.png',
  para_chain_name_statemine: '$image_assets_uri/paras/statemine.png',
  para_chain_name_quart: '$image_assets_uri/tokens/QTZ.png',
  para_chain_name_kint: '$image_assets_uri/tokens/KINT.png',
  para_chain_name_moon: '$image_assets_uri/tokens/MOVR.png',
};
