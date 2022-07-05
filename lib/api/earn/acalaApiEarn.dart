import 'package:polkawallet_plugin_karura/api/earn/acalaServiceEarn.dart';
import 'package:polkawallet_plugin_karura/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/pages/types/taigaPoolInfoData.dart';

class AcalaApiEarn {
  AcalaApiEarn(this.service);

  final AcalaServiceEarn service;

  Future<List<DexPoolData>?> getTaigaTokenPairs() async {
    final List? res = await service.getTaigaTokenPairs();
    return res?.map((e) => DexPoolData.fromJson(e)).toList();
  }

  Future<Map<String, TaigaPoolInfoData>> getTaigaPoolInfo(
      String address) async {
    final Map? res = await service.getTaigaPoolInfo(address);
    Map<String, TaigaPoolInfoData> data = {};
    res?.forEach(
        (key, value) => data.addAll({key: TaigaPoolInfoData.fromJson(value)}));
    return data;
  }

  Future<IncentivesData> queryIncentives() async {
    final res =
        await (service.queryIncentives() as Future<Map<dynamic, dynamic>>);
    return IncentivesData.fromJson(res);
  }

  Future<Map?> queryDexIncentiveLoyaltyEndBlock() async {
    return service.queryDexIncentiveLoyaltyEndBlock();
  }

  Future<int> getBlockDuration() async {
    return service.getBlockDuration();
  }
}
