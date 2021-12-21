import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaServiceSwap {
  AcalaServiceSwap(this.plugin);

  final PluginKarura plugin;

  Future<Map> queryTokenSwapAmount(
    String supplyAmount,
    String targetAmount,
    List<Map> swapPair,
    String slippage,
  ) async {
    final code =
        'acala.calcTokenSwapAmount(api, $supplyAmount, $targetAmount, ${jsonEncode(swapPair)}, $slippage)';
    final output = await plugin.sdk.webView.evalJavascript(code);
    return output;
  }

  Future<List> getTokenPairs() async {
    return await plugin.sdk.webView.evalJavascript('acala.getTokenPairs(api)');
  }

  Future<List> getBootstraps() async {
    return await plugin.sdk.webView.evalJavascript('acala.getBootstraps(api)');
  }

  Future<List> queryDexPoolInfo(address) async {
    if (plugin.store.earn.dexPools.length == 0) return [];

    final query = plugin.store.earn.dexPools
        .map((e) =>
            'acala.fetchDexPoolInfo(api, {DEXShare: ${jsonEncode(e.tokens)}}, "$address")')
        .join(',');
    final List info =
        await plugin.sdk.webView.evalJavascript('Promise.all([$query])');
    return info;
  }
}
