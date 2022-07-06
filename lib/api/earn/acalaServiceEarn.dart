import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaServiceEarn {
  AcalaServiceEarn(this.plugin);

  final PluginKarura plugin;

  Future<Map?> getTaigaMintAmount(
      String poolId, List<String> input, double slippage) async {
    final Map? res = await plugin.sdk.webView!.evalJavascript(
        'acala.getTaigaMintAmount(apiRx,"$poolId",${jsonEncode(input)},$slippage)');
    return res;
  }

  Future<List?> getTaigaRedeemAmount(
      String poolId, String input, double slippage) async {
    final List? res = await plugin.sdk.webView!.evalJavascript(
        'acala.getTaigaRedeemAmount(apiRx,"$poolId","$input",$slippage)');
    return res;
  }

  Future<List?> getTaigaTokenPairs() async {
    final List? res = await plugin.sdk.webView!
        .evalJavascript('acala.getTaigaTokenPairs(apiRx)');
    return res;
  }

  Future<Map?> getTaigaPoolInfo(String address) async {
    final Map? res = await plugin.sdk.webView!
        .evalJavascript('acala.getTaigaPoolInfo(api, "$address")');
    return res;
  }

  Future<Map?> queryIncentives() async {
    final Map? res =
        await plugin.sdk.webView!.evalJavascript('acala.queryIncentives(api)');
    return res;
  }

  Future<Map?> queryDexIncentiveLoyaltyEndBlock() async {
    final res = await plugin.sdk.webView!
        .evalJavascript('acala.queryDexIncentiveLoyaltyEndBlock(api)');
    return res;
  }

  Future<int> getBlockDuration() async {
    final res =
        await plugin.sdk.webView!.evalJavascript('acala.getBlockDuration()');
    return res;
  }
}
