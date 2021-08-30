import 'dart:async';

import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaServiceHoma {
  AcalaServiceHoma(this.plugin);

  final PluginKarura plugin;

  Future<Map> queryHomaStakingPool() async {
    final Map res = await plugin.sdk.webView
        .evalJavascript('acala.fetchHomaStakingPool(api)');
    return res;
  }

  Future<List> queryHomaLiteStakingPool() async {
    final List res = await plugin.sdk.webView.evalJavascript('Promise.all(['
        'api.query.homaLite.stakingCurrencyMintCap(),'
        'api.query.homaLite.totalStakingCurrency(),'
        'api.query.tokens.totalIssuance({ Token: "L$relay_chain_token_symbol" })'
        '])');
    return res;
  }

  Future<Map> queryHomaUserInfo(String address) async {
    final Map res = await plugin.sdk.webView
        .evalJavascript('acala.fetchHomaUserInfo(api, "$address")');
    return res;
  }

  Future<Map> queryHomaRedeemAmount(double input, int redeemType, era) async {
    final Map res = await plugin.sdk.webView.evalJavascript(
        'acala.queryHomaRedeemAmount(api, $input, $redeemType, $era)');
    return res;
  }
}
