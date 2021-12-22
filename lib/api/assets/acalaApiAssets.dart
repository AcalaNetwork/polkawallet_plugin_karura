import 'package:polkawallet_plugin_karura/api/assets/acalaServiceAssets.dart';
import 'package:polkawallet_plugin_karura/api/types/nftData.dart';
import 'package:polkawallet_plugin_karura/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class AcalaApiAssets {
  AcalaApiAssets(this.service);

  final AcalaServiceAssets service;

  final Map _tokenBalances = {};

  Future<List<TokenBalanceData>> getAllTokenSymbols(
      {bool withCache = false}) async {
    if (withCache) {
      return service.plugin.store.assets.allTokens.toList();
    }

    final res = (await service.getAllTokenSymbols())
        .map((e) => TokenBalanceData(
            id: e['id'],
            type: e['type'],
            symbol: e['symbol'],
            tokenNameId: e['tokenNameId'],
            currencyId: e['currencyId'],
            decimals: e['decimals'],
            minBalance: e['minBalance']))
        .toList();
    service.plugin.store.assets.setAllTokens(res);
    return res;
  }

  void unsubscribeTokenBalances(String address) {
    service.unsubscribeTokenBalances(address);
  }

  Future<void> subscribeTokenBalances(
      String address, Function(List<TokenBalanceData>) callback,
      {bool transferEnabled = true}) async {
    final tokens = await getAllTokenSymbols();
    if (service.plugin.store.setting.tokensConfig['invisible'] != null) {
      final invisible =
          List.of(service.plugin.store.setting.tokensConfig['invisible']);
      if (invisible.length > 0) {
        tokens.removeWhere((token) =>
            invisible.contains(token.tokenNameId) ||
            invisible.contains(token.symbol));
      }
    }

    await service.plugin.service.assets.queryMarketPrices(
        List<String>.from(tokens.map((e) => e.symbol).toList()));
    _tokenBalances.clear();

    await service.subscribeTokenBalances(address, tokens, (Map data) {
      _tokenBalances[data['tokenNameId']] = data;

      // do not callback if we did not receive enough data.
      if (_tokenBalances.keys.length < tokens.length) return;

      callback(_tokenBalances.values.map((e) {
        final decimal = e['decimals'] ??
            tokens.firstWhere((t) => t.symbol == e['symbol']).decimals;
        return TokenBalanceData(
          id: e['id'] ?? e['symbol'],
          symbol: e['symbol'],
          type: e['type'],
          tokenNameId: e['tokenNameId'],
          currencyId: e['currencyId'],
          minBalance: e['minBalance'],
          name: PluginFmt.tokenView(e['symbol']),
          fullName:
              service.plugin.store.setting.tokensConfig['tokenName'] != null
                  ? service.plugin.store.setting.tokensConfig['tokenName']
                      [e['symbol']]
                  : null,
          decimals: decimal,
          amount: e['balance']['free'].toString(),
          locked: e['balance']['frozen'].toString(),
          reserved: e['balance']['reserved'].toString(),
          price: service.plugin.store.assets.marketPrices[e['symbol']],
          detailPageRoute: transferEnabled ? TokenDetailPage.route : null,
        );
      }).toList());
    });
  }

  Future<void> subscribeTokenPrices(
      Function(Map<String, BigInt>) callback) async {
    service.subscribeTokenPrices(callback);
  }

  void unsubscribeTokenPrices() {
    service.unsubscribeTokenPrices();
  }

  Future<List<NFTData>> queryNFTs(String address) async {
    final List res = await service.queryNFTs(address);
    return res
        .map((e) => NFTData.fromJson(Map<String, dynamic>.of(e)))
        .toList();
  }

  Future<Map> queryAggregatedAssets(String address) async {
    return service.queryAggregatedAssets(address);
  }

  Future<bool> checkExistentialDepositForTransfer(
    String address,
    Map currencyId,
    int decimal,
    String amount, {
    String direction = 'to',
  }) async {
    return service.checkExistentialDepositForTransfer(
        address, currencyId, decimal, amount);
  }
}
