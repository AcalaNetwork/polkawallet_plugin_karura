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
      String pool, address) async {
    final Map info = await service.queryDexPoolInfo(pool, address);
    return {pool: DexPoolInfoData.fromJson(Map<String, dynamic>.of(info))};
  }
}
