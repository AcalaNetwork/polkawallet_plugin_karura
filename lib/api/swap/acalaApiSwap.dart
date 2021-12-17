import 'package:polkawallet_plugin_karura/api/swap/acalaServiceSwap.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/api/types/swapOutputData.dart';

class AcalaApiSwap {
  AcalaApiSwap(this.service);

  final AcalaServiceSwap service;

  Future<SwapOutputData> queryTokenSwapAmount(
    String supplyAmount,
    String targetAmount,
    List<String> swapPair,
    String slippage,
  ) async {
    final output = await service.queryTokenSwapAmount(
        supplyAmount, targetAmount, swapPair, slippage);
    if (output != null && output['error'] != null) {
      throw new Exception(output['error']['message']);
    }
    return SwapOutputData.fromJson(output);
  }

  Future<List<DexPoolData>> getTokenPairs() async {
    final pairs = await service.getTokenPairs();
    return pairs.map((e) => DexPoolData.fromJson(e)).toList();
  }

  Future<List<DexPoolData>> getBootstraps() async {
    final pairs = await service.getBootstraps();
    return pairs.map((e) => DexPoolData.fromJson(e)).toList();
  }

  Future<Map> queryDexLiquidityPoolRewards(List<DexPoolData> dexPools) async {
    return await service
        .queryDexLiquidityPoolRewards(dexPools.map((e) => e.tokens).toList());
  }

  Future<Map<String, DexPoolInfoData>> queryDexPoolInfo(
      List<String> pools, address) async {
    final List info = await service.queryDexPoolInfo(pools, address);
    final Map<String, DexPoolInfoData> res = {};
    info.forEach((e) {
      res[e['token']] = DexPoolInfoData.fromJson(Map.of(e));
    });
    return res;
  }
}
