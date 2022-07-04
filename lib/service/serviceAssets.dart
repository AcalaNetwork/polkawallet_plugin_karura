import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/service/walletApi.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
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

  Future<void> queryMarketPrices() async {
    if (store!.earn.dexPools.length == 0) {
      await plugin.service?.earn.getDexPools();
    }

    queryDexPrices();

    final all = PluginFmt.getAllDexTokens(plugin).map((e) => e.symbol).toList();
    all.removeWhere((e) =>
        e!.contains('USD') ||
        e.toLowerCase().contains('tai') ||
        (e != relay_chain_token_symbol &&
            e.contains(relay_chain_token_symbol)));
    if (all.length == 0) return;

    final Map? res = await WalletApi.getTokenPrice(all);
    final Map<String, double> prices = {
      karura_stable_coin: 1.0,
      'USDT': 1.0,
      ...(res ?? {})
    };

    try {
      if (prices[relay_chain_token_symbol] != null) {
        prices['taiKSM'] = prices[relay_chain_token_symbol]!;

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

  Future<void> queryDexPrices() async {
    final tokens = PluginFmt.getAllDexTokens(plugin);
    tokens.removeWhere((e) =>
        e.tokenNameId == karura_stable_coin ||
        (e.symbol ?? '').toLowerCase().contains('tai'));

    final output = await plugin.sdk.webView?.evalJavascript(
        'Promise.all([${tokens.map((e) => 'acala.calcTokenSwapAmount(apiRx, 1, null, ${jsonEncode([
                  e.tokenNameId,
                  karura_stable_coin
                ])}, "0.05")').join(',')}])');

    final Map<String, double> prices = {};
    output.asMap().forEach((k, v) {
      prices[tokens[k].symbol!] = v?['amount'] ?? 0;
    });

    store?.assets.setDexPrices(prices);
  }

  Future<TokenBalanceData> updateTokenBalances(TokenBalanceData token) async {
    final res = await plugin.sdk.webView!.evalJavascript(
        'acala.getTokenBalance(api, "${keyring.current.address}", "${token.tokenNameId}")');

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
        price: AssetsUtils.getMarketPrice(plugin, token.symbol ?? ''));
    balances[token.tokenNameId] = data;

    store!.assets
        .setTokenBalanceMap(balances.values.toList(), keyring.current.pubKey);
    plugin.balances.setTokens([data]);
    return data;
  }

  Future<void> queryAggregatedAssets() async {
    queryMarketPrices();
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
      prices[tokenPair.map((e) => e.symbol).join('-')] =
          (Fmt.bigIntToDouble(e.amountLeft, tokenPair[0].decimals!) *
                      AssetsUtils.getMarketPrice(
                          plugin, tokenPair[0].symbol ?? '') +
                  Fmt.bigIntToDouble(e.amountRight, tokenPair[1].decimals!) *
                      AssetsUtils.getMarketPrice(
                          plugin, tokenPair[1].symbol ?? '')) /
              Fmt.bigIntToDouble(e.issuance, tokenPair[0].decimals!);
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
