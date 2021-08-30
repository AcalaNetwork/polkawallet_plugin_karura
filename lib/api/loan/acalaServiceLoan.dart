import 'dart:async';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaServiceLoan {
  AcalaServiceLoan(this.plugin);

  final PluginKarura plugin;

  Future<List> queryAccountLoans(String address) async {
    return await plugin.sdk.webView
        .evalJavascript('api.derive.loan.allLoans("$address")');
  }

  Future<List> queryLoanTypes() async {
    return await plugin.sdk.webView
        .evalJavascript('api.derive.loan.allLoanTypes()');
  }

  Future<List> queryTotalCDPs(List<String> pools) async {
    final query = pools
        .map((e) => 'api.query.loans.totalPositions({Token: "$e"})')
        .join(',');
    final List res =
        await plugin.sdk.webView.evalJavascript('Promise.all([$query])');
    return res;
  }

  Future<List> queryCollateralIncentives() async {
    final pools = await plugin.sdk.webView.evalJavascript(
        'api.query.incentives.incentiveRewardAmount.entries()'
        '.then(ls => ls.map(i => ([i[0].toHuman(), i[1]])).filter(i => !!i[0][0].LoansIncentive))');
    return pools;
  }

  Future<List> queryCollateralIncentivesTC6() async {
    final pools = await plugin.sdk.webView
        .evalJavascript('api.query.incentives.loansIncentiveRewards.entries()'
            '.then(ls => ls.map(i => ([i[0].toHuman(), i[1]])))');
    return pools;
  }

  Future<List> queryCollateralRewards(
      List<String> collaterals, String address) async {
    final decimals = plugin.networkState.tokenDecimals[0];
    final query = collaterals
        .map((e) =>
            'acala.fetchCollateralRewards(api, {Token: "$e"}, "$address", $decimals)')
        .join(',');
    final List res =
        await plugin.sdk.webView.evalJavascript('Promise.all([$query])');
    return res;
  }
}
