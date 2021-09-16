import 'package:polkawallet_plugin_karura/api/loan/acalaServiceLoan.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';

class AcalaApiLoan {
  AcalaApiLoan(this.service);

  final AcalaServiceLoan service;

  Future<List> queryAccountLoans(String address) async {
    final List res = await service.queryAccountLoans(address);
    return res;
  }

  Future<List<LoanType>> queryLoanTypes() async {
    final List res = await service.queryLoanTypes();
    return res
        .map((e) => LoanType.fromJson(Map<String, dynamic>.of(e)))
        .toList();
  }

  Future<List<TotalCDPData>> queryTotalCDPs(List<String> pools) async {
    final List res = await service.queryTotalCDPs(pools);
    int index = 0;
    return res.map((e) {
      e['token'] = pools[index];
      index++;
      return TotalCDPData.fromJson(e);
    }).toList();
  }

  Future<List<CollateralIncentiveData>> queryCollateralIncentives() async {
    final res = await service.queryCollateralIncentives();
    return res.map((e) => CollateralIncentiveData.fromJson(e as List)).toList();
  }

  Future<Map<String, double>> queryCollateralLoyaltyBonus() async {
    return service.queryCollateralLoyaltyBonus();
  }

  Future<List<CollateralRewardData>> queryCollateralRewards(
      List<String> collaterals, String address) async {
    final res = await service.queryCollateralRewards(collaterals, address);
    return res.map((e) => CollateralRewardData.fromJson(e)).toList();
  }

  Future<List<CollateralRewardDataV2>> queryCollateralRewardsV2(
      List<String> collaterals, String address) async {
    final res = await service.queryCollateralRewardsV2(collaterals, address);
    return res.map((e) => CollateralRewardDataV2.fromJson(e)).toList();
  }
}
