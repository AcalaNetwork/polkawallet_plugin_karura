import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AcalaServiceAssets {
  AcalaServiceAssets(this.plugin);

  final PluginKarura plugin;

  Timer _tokenPricesSubscribeTimer;

  final tokenBalanceChannel = 'tokenBalance';

  Future<List> getAllTokenSymbols() async {
    final List res =
        await plugin.sdk.webView.evalJavascript('acala.getAllTokens(api)');
    return res;
  }

  void unsubscribeTokenBalances(String address) async {
    final tokens = await getAllTokenSymbols();
    tokens.forEach((e) {
      plugin.sdk.api.unsubscribeMessage('$tokenBalanceChannel${e['symbol']}');
    });

    final dexPairs = await plugin.api.swap.getTokenPairs();
    dexPairs.forEach((e) {
      final lpToken = e.getPoolId(plugin);
      plugin.sdk.api
          .unsubscribeMessage('$tokenBalanceChannel${lpToken.join('')}');
    });
  }

  Future<void> subscribeTokenBalances(
      String address, List tokens, Function(Map) callback) async {
    tokens.forEach((e) {
      final channel = '$tokenBalanceChannel${e['symbol']}';
      plugin.sdk.api.subscribeMessage(
        'api.query.tokens.accounts',
        [
          address,
          e['type'] == 'ForeignAsset'
              ? {'ForeignAsset': e['id']}
              : {'token': e['symbol']}
        ],
        channel,
        (Map data) {
          callback({
            'id': e['id'],
            'symbol': e['symbol'],
            'type': e['type'],
            'minBalance': e['minBalance'],
            'decimals': e['decimals'],
            'balance': data
          });
        },
      );
    });
    final dexPairs = await plugin.api.swap.getTokenPairs();
    dexPairs.forEach((e) {
      final lpToken = e.getPoolId(plugin);
      final tokenId = lpToken.join('-');
      final channel = '$tokenBalanceChannel${lpToken.join('')}';
      plugin.sdk.api.subscribeMessage(
        'api.query.tokens.accounts',
        [
          address,
          {'DEXShare': e.tokens}
        ],
        channel,
        (Map data) {
          callback({
            'symbol': tokenId,
            'type': 'DexShare',
            'decimals': e.decimals,
            'balance': data
          });
        },
      );
    });
  }

  Future<Map> queryAirdropTokens(String address) async {
    final res = await plugin.sdk.webView.evalJavascript(
        'JSON.stringify(api.registry.createType("AirDropCurrencyId").defKeys)',
        wrapPromise: false);
    if (res != null) {
      final List tokens = jsonDecode(res);
      final queries = tokens
          .map((i) => 'api.query.airDrop.airDrops("$address", "$i")')
          .join(",");
      final List amount =
          await plugin.sdk.webView.evalJavascript('Promise.all([$queries])');
      return {
        'tokens': tokens,
        'amount': amount,
      };
    }
    return {};
  }

  Future<void> subscribeTokenPrices(
      Function(Map<String, BigInt>) callback) async {
    final List res = await plugin.sdk.webView
        .evalJavascript('api.rpc.oracle.getAllValues("Aggregated")');
    if (res != null) {
      final prices = Map<String, BigInt>();
      res.forEach((e) {
        final token = AssetsUtils.tokenSymbolFromCurrencyId(
            plugin.store.assets.tokenBalanceMap, e[0]);
        prices[token] = Fmt.balanceInt(e[1]['value'].toString());
      });
      callback(prices);
    }

    _tokenPricesSubscribeTimer =
        Timer(Duration(seconds: 20), () => subscribeTokenPrices(callback));
  }

  void unsubscribeTokenPrices() {
    if (_tokenPricesSubscribeTimer != null) {
      _tokenPricesSubscribeTimer.cancel();
      _tokenPricesSubscribeTimer = null;
    }
  }

  Future<List> queryNFTs(String address) async {
    final List res = await plugin.sdk.webView
        .evalJavascript('acala.queryNFTs(api, "$address")');
    return res;
  }

  Future<Map> queryAggregatedAssets(String address) async {
    final Map res = await plugin.sdk.webView
        .evalJavascript('acala.queryAggregatedAssets(api, "$address")');
    return res;
  }

  Future<bool> checkExistentialDepositForTransfer(
    String address,
    String token,
    int decimal,
    String amount, {
    String direction = 'to',
  }) async {
    final res = await plugin.sdk.webView.evalJavascript(
        'acala.checkExistentialDepositForTransfer(api, "$address", "$token", $decimal, $amount, "$direction")');
    return res['result'] as bool;
  }
}
