import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaServiceSwap {
  AcalaServiceSwap(this.plugin);

  final PluginKarura plugin;

  Future<Map> queryTokenSwapAmount(
    String supplyAmount,
    String targetAmount,
    List<String> swapPair,
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

  Future<Map> queryDexLiquidityPoolRewards(List<List> dexPools) async {
    final pools =
        dexPools.map((pool) => jsonEncode({'DEXShare': pool})).toList();
    final incentiveQuery = pools
        .map((i) =>
            'api.query.incentives.incentiveRewardAmount({ DexIncentive: $i})')
        .join(',');
    final savingRateQuery = pools
        .map(
            (i) => 'api.query.incentives.dexSavingRewardRate({ DexSaving: $i})')
        .join(',');
    final res = await Future.wait([
      plugin.sdk.webView.evalJavascript('Promise.all([$incentiveQuery])'),
      plugin.sdk.webView.evalJavascript('Promise.all([$savingRateQuery])')
    ]);
    List deductions = [];
    final deductionQuery = dexPools
        .map((i) => 'api.query.incentives.payoutDeductionRates(${jsonEncode({
                  'DexIncentive': {'DEXShare': i}
                })})')
        .join(',');
    final deductionSavingQuery = dexPools
        .map((i) => 'api.query.incentives.payoutDeductionRates(${jsonEncode({
                  'DexSaving': {'DEXShare': i}
                })})')
        .join(',');
    deductions = await Future.wait([
      plugin.sdk.webView.evalJavascript('Promise.all([$deductionQuery])'),
      plugin.sdk.webView.evalJavascript('Promise.all([$deductionSavingQuery])')
    ]);
    final incentives = Map<String, dynamic>();
    final savingRates = Map<String, dynamic>();
    final deductionRates = Map<String, dynamic>();
    final deductionSavingRates = Map<String, dynamic>();
    final tokenPairs =
        dexPools.map((e) => e.map((i) => i['token']).join('-')).toList();
    tokenPairs.asMap().forEach((k, v) {
      incentives[v] = res[0][k];
      savingRates[v] = res[1][k];
      if (deductions.length > 0) {
        deductionRates[v] = deductions[0][k];
        deductionSavingRates[v] = deductions[1][k];
      }
    });
    return {
      'incentives': incentives,
      'savingRates': savingRates,
      'deductionRates': deductionRates,
      'deductionSavingRates': deductionSavingRates,
    };
  }

  Future<Map> queryDexPoolInfo(String pool, address) async {
    final Map info = await plugin.sdk.webView
        .evalJavascript('acala.fetchDexPoolInfo(api, ${jsonEncode({
          'DEXShare':
              pool.split('-').map((e) => ({'Token': e.toUpperCase()})).toList()
        })}, "$address")');
    return info;
  }
}
