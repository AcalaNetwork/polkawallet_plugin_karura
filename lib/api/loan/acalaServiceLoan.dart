import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_ui/utils/format.dart';

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

  Future<Map<String, double>> queryCollateralLoyaltyBonus() async {
    final loanTypes = plugin.store.loan.loanTypes;
    final data = await plugin.sdk.webView.evalJavascript(
        'Promise.all([${loanTypes.map((i) => 'api.query.incentives.payoutDeductionRates(${jsonEncode({
                  'LoansIncentive': {'Token': i.token}
                })})').join(',')}])');
    final Map<String, double> res = {};
    loanTypes.asMap().forEach((key, value) {
      res[value.token] = Fmt.balanceDouble(data[key], acala_price_decimals);
    });
    return res;
  }

  Future<List> queryCollateralRewardsV2(
      List<String> collaterals, String address) async {
    final decimals = plugin.networkState.tokenDecimals[0];
    final query = collaterals
        .map((e) =>
            'acala.fetchCollateralRewardsV2(api, {Token: "$e"}, "$address", $decimals)')
        .join(',');
    final List res =
        await plugin.sdk.webView.evalJavascript('Promise.all([$query])');
    return res;
  }
}
