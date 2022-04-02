import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/service/walletApi.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceAssets {
  ServiceAssets(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginKarura plugin;
  final Keyring keyring;
  final AcalaApi? api;
  final PluginStore? store;

  Future<void> queryMarketPrices(List<String?> tokens) async {
    final all = tokens.toList();
    all.removeWhere((e) =>
        e == karura_stable_coin ||
        e == 'L$relay_chain_token_symbol' ||
        e == 'USDT');
    if (all.length == 0) return;

    final Map? res = await WalletApi.getTokenPrice();
    final Map<String, double> prices = {
      karura_stable_coin: 1.0,
      'USDT': 1.0,
      ...((res?['prices'] as Map?) ?? {})
    };

    try {
      if (prices[relay_chain_token_symbol] != null) {
        final homaEnv = await plugin.service!.homa.queryHomaEnv();
        prices['L$relay_chain_token_symbol'] =
            prices[relay_chain_token_symbol]! * homaEnv.exchangeRate;
      }
    } catch (err) {
      print(err);
      // ignore
    }

    store!.assets.setMarketPrices(prices);
  }

  Future<void> updateTokenBalances(TokenBalanceData token) async {
    final res = await plugin.sdk.webView!.evalJavascript(
        'api.query.tokens.accounts("${keyring.current.address}", ${jsonEncode(token.currencyId)})');

    final balances =
        Map<String?, TokenBalanceData>.from(store!.assets.tokenBalanceMap);
    final data = TokenBalanceData(
        id: token.id,
        name: token.name,
        fullName: token.fullName,
        symbol: token.symbol,
        tokenNameId: token.tokenNameId,
        src: token.src,
        currencyId: token.currencyId,
        type: token.type,
        decimals: token.decimals,
        minBalance: token.minBalance,
        amount: res['free'].toString(),
        locked: res['frozen'].toString(),
        reserved: res['reserved'].toString(),
        detailPageRoute: token.detailPageRoute,
        price: store!.assets.marketPrices[token.symbol]);
    balances[token.tokenNameId] = data;

    store!.assets
        .setTokenBalanceMap(balances.values.toList(), keyring.current.pubKey);
    plugin.balances.setTokens([data]);
  }

  Future<void> queryAggregatedAssets() async {
    queryMarketPrices([plugin.networkState.tokenSymbol![0]]);
    final data = await plugin.api!.assets
        .queryAggregatedAssets(keyring.current.address!);
    store!.assets.setAggregatedAssets(data, keyring.current.pubKey);
  }

  void calcLPTokenPrices() {
    final Map<String, double> prices = {};
    store!.earn.dexPoolInfoMap.values.forEach((e) {
      final pool = store!.earn.dexPools
          .firstWhere((i) => i.tokenNameId == e.tokenNameId);
      final tokenPair = pool.tokens!
          .map((id) => AssetsUtils.tokenDataFromCurrencyId(plugin, id))
          .toList();
      prices[tokenPair.map((e) => e!.symbol).join('-')] =
          (Fmt.bigIntToDouble(e.amountLeft, tokenPair[0]!.decimals!) *
                      (store!.assets.marketPrices[tokenPair[0]!.symbol] ?? 0) +
                  Fmt.bigIntToDouble(e.amountRight, tokenPair[1]!.decimals!) *
                      (store!.assets.marketPrices[tokenPair[1]!.symbol] ?? 0)) /
              Fmt.bigIntToDouble(e.issuance, tokenPair[0]!.decimals!);
    });
    store!.assets.setMarketPrices(prices);
  }

  Future<void> queryIconsSrc() async {
    final data = await Future.wait(
        [WalletApi.getTokenIcons(), WalletApi.getCrossChainIcons()]);
    if (data[0] != null && data[1] != null) {
      final icons = Map.of(data[0]!);
      icons.removeWhere(
          (key, value) => plugin.tokenIcons.keys.toList().indexOf(key) > -1);
      plugin.tokenIcons.addAll(icons.map((k, v) {
        return MapEntry(
            (k as String).toUpperCase(),
            (v as String).contains('.svg')
                ? SvgPicture.network(v)
                : Image.network(v));
      }));

      store!.assets.crossChainIcons = data[1]!;
    }
  }
}
