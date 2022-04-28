import 'dart:async';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaServiceEarn {
  AcalaServiceEarn(this.plugin);

  final PluginKarura plugin;

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
