import 'dart:async';

import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaServiceHoma {
  AcalaServiceHoma(this.plugin);

  final PluginKarura plugin;

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

  Future<Map> calcHomaMintAmount(double input) async {
    final Map res = await plugin.sdk.webView
        .evalJavascript('acala.calcHomaMintAmount(api, $input)');
    return res;
  }

  Future<Map> calcHomaRedeemAmount(double input, bool isByDex) async {
    final Map res = await plugin.sdk.webView
        .evalJavascript('acala.calcHomaRedeemAmount(api, $input,$isByDex)');
    return res;
  }

  Future<dynamic> redeemRequested(String address) async {
    final dynamic res = await plugin.sdk.webView
        .evalJavascript('api.query.homaLite.redeemRequests("$address")');
    return res;
  }
}
