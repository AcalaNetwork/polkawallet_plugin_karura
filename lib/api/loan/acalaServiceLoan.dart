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

  Future<List> queryTotalCDPs(List<Map> pools) async {
    final query = pools
        .map((currencyId) =>
            'api.query.loans.totalPositions(${jsonEncode(currencyId)})')
        .join(',');
    final List res =
        await plugin.sdk.webView.evalJavascript('Promise.all([$query])');
    return res;
  }

  Future<Map<String, double>> queryCollateralLoyaltyBonus() async {
    final loanTypes = plugin.store.loan.loanTypes;
    final data = await plugin.sdk.webView.evalJavascript(
        'Promise.all([${loanTypes.map((i) => 'api.query.incentives.payoutDeductionRates(${jsonEncode({
                  'LoansIncentive': i.token.currencyId
                })})').join(',')}])');
    final Map<String, double> res = {};
    loanTypes.asMap().forEach((key, value) {
      res[value.token.tokenNameId] =
          Fmt.balanceDouble(data[key], acala_price_decimals);
    });
    return res;
  }

  Future<List> queryCollateralRewards(
      List<Map> collaterals, String address) async {
    final query = collaterals
        .map((e) =>
            'acala.fetchCollateralRewards(api, ${jsonEncode(e)}, "$address")')
        .join(',');
    final List res =
        await plugin.sdk.webView.evalJavascript('Promise.all([$query])');
    return res;
  }
}
