import 'package:polkawallet_plugin_karura/api/homa/acalaServiceHoma.dart';
import 'package:polkawallet_plugin_karura/api/types/calcHomaMintAmountData.dart';
import 'package:polkawallet_plugin_karura/api/types/calcHomaRedeemAmount.dart';
import 'package:polkawallet_plugin_karura/api/types/homaNewEnvData.dart';
import 'package:polkawallet_plugin_karura/api/types/homaRedeemAmountData.dart';
import 'package:polkawallet_plugin_karura/api/types/stakingPoolInfoData.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'dart:convert';

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

  // Future<HomaUserInfoData> queryHomaUserInfo(String address) async {
  //   final Map res = await service.queryHomaUserInfo(address);
  //   return HomaUserInfoData.fromJson(Map<String, dynamic>.of(res));
  // }

  Future<HomaRedeemAmountData> queryHomaRedeemAmount(
      double input, int redeemType, era) async {
    final Map res = await service.queryHomaRedeemAmount(input, redeemType, era);
    // final Map res = await service.queryHomaPendingRedeem(input, redeemType, era);
    return HomaRedeemAmountData.fromJson(res);
  }

  Future<Map> calcHomaMintAmount(double input) async {
    final Map res = await service.calcHomaMintAmount(input);
    return res;
  }

  Future<Map> calcHomaNewMintAmount(double input) async {
    final Map res = await service.calcHomaNewMintAmount(input);
    return res;
  }

  Future<CalcHomaRedeemAmount> calcHomaRedeemAmount(
      String address, double input, bool isByDex) async {
    // final Map res = await service.calcHomaRedeemAmount(address, input, isByDex);
    final Map res = await service.calcHomaNewRedeemAmount(input);
    print("calcHomaNewRedeemAmount=======${res}");
    return CalcHomaRedeemAmount.fromJson(res);
  }

  Future<dynamic> redeemRequested(String address) async {
    final dynamic res = await service.redeemRequested(address);
    return res;
  }

  Future<dynamic> specVersion() async {
    final dynamic res = await service.specVersion();
    return res['words'][0];
  }

  Future<HomaNewEnvData> queryHomaNewEnv() async {
    final dynamic res = await service.queryHomaNewEnv();
    return HomaNewEnvData.fromJson(res);
  }
}
