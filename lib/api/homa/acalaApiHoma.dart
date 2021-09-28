import 'package:polkawallet_plugin_karura/api/homa/acalaServiceHoma.dart';
import 'package:polkawallet_plugin_karura/api/types/homaRedeemAmountData.dart';
import 'package:polkawallet_plugin_karura/api/types/stakingPoolInfoData.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AcalaApiHoma {
  AcalaApiHoma(this.service);

  final AcalaServiceHoma service;

  Future<HomaLitePoolInfoData> queryHomaLiteStakingPool() async {
    final List res = await service.queryHomaLiteStakingPool();
    return HomaLitePoolInfoData(
      cap: Fmt.balanceInt(res[0]),
      staked: Fmt.balanceInt(res[1]),
      liquidTokenIssuance: Fmt.balanceInt(res[2]),
    );
  }

  Future<HomaUserInfoData> queryHomaUserInfo(String address) async {
    final Map res = await service.queryHomaUserInfo(address);
    return HomaUserInfoData.fromJson(Map<String, dynamic>.of(res));
  }

  Future<HomaRedeemAmountData> queryHomaRedeemAmount(
      double input, int redeemType, era) async {
    final Map res = await service.queryHomaRedeemAmount(input, redeemType, era);
    return HomaRedeemAmountData.fromJson(res);
  }
}
