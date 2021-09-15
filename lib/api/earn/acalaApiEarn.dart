import 'package:polkawallet_plugin_karura/api/earn/acalaServiceEarn.dart';
import 'package:polkawallet_plugin_karura/api/earn/types/incentivesData.dart';

class AcalaApiEarn {
  AcalaApiEarn(this.service);

  final AcalaServiceEarn service;

  Future<IncentivesData> queryIncentives() async {
    final res = await service.queryIncentives();
    return IncentivesData.fromJson(res);
  }
}
