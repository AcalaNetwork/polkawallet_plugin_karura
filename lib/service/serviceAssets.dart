import 'dart:convert';

import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/service/walletApi.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceAssets {
  ServiceAssets(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginKarura plugin;
  final Keyring keyring;
  final AcalaApi api;
  final PluginStore store;

  Future<void> queryMarketPrices(List<String> tokens) async {
    final all = tokens.toList();
    all.removeWhere((e) =>
        e == karura_stable_coin ||
        e == 'L$relay_chain_token_symbol' ||
        e == 'USDT');
    if (all.length == 0) return;

    final List res =
        await Future.wait(all.map((e) => WalletApi.getTokenPrice(e)).toList());
    final Map<String, double> prices = {karura_stable_coin: 1.0, 'USDT': 1.0};
    res.asMap().forEach((k, e) {
      if (e != null && e['data'] != null) {
        prices[all[k]] = double.parse(e['data']['price'][0].toString());
      }
    });

    if (prices[relay_chain_token_symbol] != null) {
      await plugin.service.homa.queryHomaLiteStakingPool();
      final poolInfo = plugin.store.homa.poolInfo;
      final exchangeRate = (poolInfo.staked ?? BigInt.zero) > BigInt.zero
          ? (poolInfo.liquidTokenIssuance / poolInfo.staked)
          : Fmt.balanceDouble(
              plugin.networkConst['homaLite']['defaultExchangeRate'],
              acala_price_decimals);
      prices['L$relay_chain_token_symbol'] =
          prices[relay_chain_token_symbol] / exchangeRate;
    }
    if (tokens.contains(para_chain_token_symbol_bifrost) &&
        prices[para_chain_token_symbol_bifrost] == null) {
      final dexPool = plugin.store.earn.dexPoolInfoMap[
          'lp://$karura_stable_coin/$para_chain_token_symbol_bifrost'];
      if (dexPool != null) {
        final priceBNC = dexPool.amountLeft / dexPool.amountRight;
        prices[para_chain_token_symbol_bifrost] = priceBNC;
      }
    }

    store.assets.setMarketPrices(prices);
  }

  Future<void> updateTokenBalances(TokenBalanceData token) async {
    final res = await plugin.sdk.webView.evalJavascript(
        'api.query.tokens.accounts("${keyring.current.address}", ${jsonEncode(token.currencyId)})');

    final balances =
        Map<String, TokenBalanceData>.from(store.assets.tokenBalanceMap);
    final data = TokenBalanceData(
        id: token.id,
        name: token.name,
        fullName: token.fullName,
        symbol: token.symbol,
        tokenNameId: token.tokenNameId,
        currencyId: token.currencyId,
        type: token.type,
        decimals: token.decimals,
        minBalance: token.minBalance,
        amount: res['free'].toString(),
        locked: res['frozen'].toString(),
        reserved: res['reserved'].toString(),
        detailPageRoute: token.detailPageRoute,
        price: store.assets.marketPrices[token.symbol]);
    balances[token.tokenNameId] = data;

    store.assets
        .setTokenBalanceMap(balances.values.toList(), keyring.current.pubKey);
    plugin.balances.setTokens([data]);
  }

  Future<void> queryAggregatedAssets() async {
    queryMarketPrices([plugin.networkState.tokenSymbol[0]]);
    final data =
        await plugin.api.assets.queryAggregatedAssets(keyring.current.address);
    plugin.store.assets.setAggregatedAssets(data, keyring.current.pubKey);
  }
}
