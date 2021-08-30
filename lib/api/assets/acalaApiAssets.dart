import 'package:polkawallet_plugin_karura/api/assets/acalaServiceAssets.dart';
import 'package:polkawallet_plugin_karura/api/types/nftData.dart';
import 'package:polkawallet_plugin_karura/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class AcalaApiAssets {
  AcalaApiAssets(this.service);

  final AcalaServiceAssets service;

  final Map _tokenBalances = {};

  Future<List> getAllTokenSymbols(String chain) async {
    return await service.getAllTokenSymbols(chain);
  }

  void unsubscribeTokenBalances(String chain, String address) {
    service.unsubscribeTokenBalances(chain, address);
  }

  Future<void> subscribeTokenBalances(
      String chain, String address, Function(List<TokenBalanceData>) callback,
      {bool transferEnabled = true}) async {
    final tokens = await getAllTokenSymbols(chain);
    _tokenBalances.clear();

    await service.subscribeTokenBalances(address, tokens, (Map data) {
      _tokenBalances[data['symbol']] = data;

      // do not callback if we did not receive enough data.
      if (_tokenBalances.keys.length < tokens.length) return;

      callback(_tokenBalances.values
          .map((e) => TokenBalanceData(
                id: e['symbol'],
                symbol: PluginFmt.tokenView(e['symbol']),
                name: e['name'],
                decimals: e['decimals'],
                amount: e['balance']['free'].toString(),
                locked: e['balance']['frozen'].toString(),
                reserved: e['balance']['reserved'].toString(),
                detailPageRoute: transferEnabled ? TokenDetailPage.route : null,
              ))
          .toList());
    });
  }

  Future<List<TokenBalanceData>> queryAirdropTokens(String address) async {
    final symbolAll = service.plugin.networkState.tokenSymbol;
    final decimalsAll = service.plugin.networkState.tokenDecimals;

    final res = List<TokenBalanceData>.empty(growable: true);
    final ls = await service.queryAirdropTokens(address);
    if (ls['tokens'] != null) {
      List.of(ls['tokens']).asMap().forEach((i, v) {
        int decimal = decimalsAll[symbolAll.indexOf(v)];
        if (v == symbolAll[0]) {
          decimal = 12;
        }
        res.add(TokenBalanceData(
            name: 'pre$v',
            symbol: v,
            decimals: decimal,
            amount: ls['amount'][i].toString()));
      });
    }
    return res;
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

  Future<bool> checkExistentialDepositForTransfer(
    String address,
    String token,
    int decimal,
    String amount, {
    String direction = 'to',
  }) async {
    return service.checkExistentialDepositForTransfer(
        address, token, decimal, amount);
  }
}
