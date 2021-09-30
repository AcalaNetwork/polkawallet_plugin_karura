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

const relay_chain_name = 'kusama';
const para_chain_name_bifrost = 'bifrost';
const para_chain_ids = {
  para_chain_name_bifrost: 2001,
};

const network_ss58_format = {
  plugin_name_karura: 8,
  relay_chain_name: 2,
  para_chain_name_bifrost: 6,
};
const relay_chain_token_symbol = 'KSM';
const para_chain_token_symbol_bifrost = 'BNC';
const cross_chain_xcm_fees = {
  relay_chain_name: {
    relay_chain_token_symbol: {
      'fee': '79999999',
      'existentialDeposit': '33333333',
    },
  },
  para_chain_name_bifrost: {
    relay_chain_token_symbol: {
      'fee': '4848000000',
      'existentialDeposit': '100000000',
    },
    karura_stable_coin: {
      'fee': '19200000000',
      'existentialDeposit': '100000000',
    },
    para_chain_token_symbol_bifrost: {
      'fee': '3840000000',
      'existentialDeposit': '100000000',
    },
    'VSKSM': {
      'fee': '48000000',
      'existentialDeposit': '100000000',
    }
  }
};
const xcm_dest_weight_kusama = '3000000000';
const xcm_dest_weight_karura = '600000000';

const existential_deposit = {
  'KSM': '100000000',
  'KUSD': '10000000000',
  'LKSM': '500000000',
  'BNC': '8000000000',
  'VSKSM': '100000000',
};

const acala_token_ids = [
  'KAR',
  'KUSD',
  'KSM',
  'LKSM',
  'BNC',
  'VSKSM',
  // 'RENBTC',
  // 'XBTC',
  // 'POLKABTC',
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
    'enabled': false,
  },
  module_name_loan: {
    'visible': true,
    'enabled': false,
  },
  module_name_swap: {
    'visible': true,
    'enabled': false,
  },
  module_name_earn: {
    'visible': true,
    'enabled': false,
  },
  module_name_homa: {
    'visible': true,
    'enabled': false,
  },
  module_name_nft: {
    'visible': true,
    'enabled': true,
  },
};

const image_assets_uri = 'packages/polkawallet_plugin_karura/assets/images';
const module_icons_uri = {
  module_name_loan: '$image_assets_uri/loan.svg',
  module_name_swap: '$image_assets_uri/swap.svg',
  module_name_earn: '$image_assets_uri/earn.svg',
  module_name_homa: '$image_assets_uri/homa.svg',
  module_name_nft: '$image_assets_uri/nft.svg',
};

const cross_chain_icons = {
  plugin_name_karura: '$image_assets_uri/tokens/KAR.png',
  relay_chain_name: '$image_assets_uri/tokens/KSM.png',
  para_chain_name_bifrost: '$image_assets_uri/tokens/BNC.png',
};

const dex_incentive_loyalty_end_block = {
  'KUSD-KSM': 1538140,
  'KAR-KSM': 2799580,
  'KSM-LKSM': 1503600,
  'LKSM': 1503600,
};

const action_loan_adjust = 'honzon.adjustLoan';
const action_loan_close = 'honzon.closeLoanHasDebitByDex';
const action_swap_add_lp = 'dex.addLiquidity';
const action_swap_remove_lp = 'dex.removeLiquidity';
const action_earn_claim = 'incentives.claimRewards';
const action_earn_deposit_lp = 'incentives.depositDexShare';
const action_earn_withdraw_lp = 'incentives.withdrawDexShare';
