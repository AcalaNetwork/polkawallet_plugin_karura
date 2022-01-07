import 'package:polkawallet_plugin_karura/api/earn/acalaServiceEarn.dart';
import 'package:polkawallet_plugin_karura/api/earn/types/incentivesData.dart';

class AcalaApiEarn {
  AcalaApiEarn(this.service);

  final AcalaServiceEarn service;

  Future<IncentivesData> queryIncentives() async {
    final res =
        await (service.queryIncentives() as Future<Map<dynamic, dynamic>>);
    return IncentivesData.fromJson(res);
  }

  Future<List<dynamic>?> queryDexIncentiveLoyaltyEndBlock() async {
    final List<dynamic>? res = await service.queryDexIncentiveLoyaltyEndBlock();
    return res;
  }
}
