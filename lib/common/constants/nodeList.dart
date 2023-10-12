import 'package:polkawallet_plugin_karura/common/constants/base.dart';

const node_list = [
  {
    'name': 'Karura (via Polkawallet)',
    'ss58': ss58_prefix_karura,
    'endpoint': 'wss://karura.polkawallet.io',
  },
  {
    'name': 'Karura (via Acala Foundation 0)',
    'ss58': ss58_prefix_karura,
    'endpoint': 'wss://karura-rpc-0.aca-api.network',
  },
  {
    'name': 'Karura (via Acala Foundation 1)',
    'ss58': ss58_prefix_karura,
    'endpoint': 'wss://karura-rpc-1.aca-api.network',
  },
  {
    'name': 'Karura (via Acala Foundation 2)',
    'ss58': ss58_prefix_karura,
    'endpoint': 'wss://karura-rpc-2.aca-api.network/ws',
  },
  {
    'name': 'Karura (via Acala Foundation 3)',
    'ss58': ss58_prefix_karura,
    'endpoint': 'wss://karura-rpc-3.aca-api.network/ws',
  },
  // {
  //   'name': 'Karura (Polkawallet dev node)',
  //   'ss58': ss58_prefix_karura,
  //   'endpoint': 'wss://crosschain-dev.polkawallet.io:9905',
  // },
  // {
  //   'name': 'Karura (Polkawallet dev node pha)',
  //   'ss58': ss58_prefix_karura,
  //   'endpoint': 'ws://35.215.162.102:9955',
  // },
  // {
  //   'name': 'Acala Karura (acala dev node)',
  //   'ss58': ss58_prefix_karura,
  //   'endpoint': 'wss://kusama-1.polkawallet.io:3000',
  // },
];
