import 'package:polkawallet_plugin_karura/api/swap/acalaServiceSwap.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_karura/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class AcalaApiSwap {
  AcalaApiSwap(this.service);

  final AcalaServiceSwap service;

  Future<List<TokenBalanceData>?> getSwapTokens() async {
    final data = await service.getSwapTokens();
    final tokensConfig =
        service.plugin.store!.setting.remoteConfig['tokens'] ?? {};
    return data
        ?.map((e) => TokenBalanceData(
              id: e['id'] ?? e['symbol'],
              symbol: e['symbol'],
              type: e['type'],
              tokenNameId: e['tokenNameId'],
              currencyId: e['currencyId'],
              minBalance: e['minBalance'],
              name: PluginFmt.tokenView(e['symbol']),
              fullName: tokensConfig['tokenName'] != null
                  ? tokensConfig['tokenName'][e['symbol']]
                  : null,
              decimals: e['decimals'],
              price: AssetsUtils.getMarketPrice(service.plugin, e['symbol']),
              detailPageRoute: TokenDetailPage.route,
            ))
        .toList();
  }

  Future<SwapOutputData> queryTokenSwapAmount(
    String? supplyAmount,
    String? targetAmount,
    List<String?> swapPair,
    String slippage,
  ) async {
    final output = await (service.queryTokenSwapAmount(
            supplyAmount, targetAmount, swapPair, slippage)
        as Future<Map<dynamic, dynamic>>);
    if (output != null && output['error'] != null) {
      throw new Exception(output['error']['message']);
    }
    return SwapOutputData.fromJson(output);
  }

  Future<List<DexPoolData>> getTokenPairs() async {
    final pairs = await (service.getTokenPairs() as Future<List<dynamic>>);
    return pairs.map((e) => DexPoolData.fromJson(e)).toList();
  }

  Future<List<DexPoolData>> getBootstraps() async {
    final pairs = await (service.getBootstraps() as Future<List<dynamic>>);
    return pairs.map((e) => DexPoolData.fromJson(e)).toList();
  }

  Future<Map<String?, DexPoolInfoData>> queryDexPoolInfo(address) async {
    final List info =
        await (service.queryDexPoolInfo(address) as Future<List<dynamic>>);
    final Map<String?, DexPoolInfoData> res = {};
    info.forEach((e) {
      res[e['tokenNameId']] = DexPoolInfoData.fromJson(Map.of(e));
    });
    return res;
  }
}
