import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/types/loanType.dart';
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
    all.removeWhere((e) => e == karura_stable_coin);
    if (all.length == 0) return;

    final List res =
        await Future.wait(all.map((e) => WalletApi.getTokenPrice(e)).toList());
    final Map<String, double> prices = {karura_stable_coin: 1.0};
    res.forEach((e) {
      if (e != null && e['price'] != null) {
        prices[e['token']] = double.parse(e['price']);
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
    if (tokens.contains(para_chain_token_symbol_bifrost)) {
      final dexPool = plugin.store.earn.dexPoolInfoMap[
          '$karura_stable_coin-$para_chain_token_symbol_bifrost'];
      if (dexPool != null) {
        final priceBNC = dexPool.amountLeft / dexPool.amountRight;
        prices[para_chain_token_symbol_bifrost] = priceBNC;
      }
    }

    store.assets.setMarketPrices(prices);
  }

  Future<void> updateTokenBalances(String tokenId) async {
    String currencyId = '{Token: "$tokenId"}';
    if (tokenId.contains('-')) {
      final pair = tokenId.split('-');
      currencyId = '{DEXShare: [{Token: "${pair[0]}"}, {Token: "${pair[1]}"}]}';
    }
    final res = await plugin.sdk.webView.evalJavascript(
        'api.query.tokens.accounts("${keyring.current.address}", $currencyId)');

    final balances =
        Map<String, TokenBalanceData>.from(store.assets.tokenBalanceMap);
    final data = TokenBalanceData(
        id: balances[tokenId].id,
        name: balances[tokenId].name,
        symbol: balances[tokenId].symbol,
        decimals: balances[tokenId].decimals,
        amount: res['free'].toString(),
        locked: res['frozen'].toString(),
        reserved: res['reserved'].toString(),
        detailPageRoute: balances[tokenId].detailPageRoute,
        price: store.assets.marketPrices[tokenId]);
    balances[tokenId] = data;

    store.assets
        .setTokenBalanceMap(balances.values.toList(), keyring.current.pubKey);
    plugin.balances.setTokens([data]);
  }

  Future<void> queryAggregatedAssets() async {
    plugin.service.earn.updateAllDexPoolInfo();

    final loans = await Future.wait([
      plugin.api.loan.queryLoanTypes(),
      plugin.api.loan.queryAccountLoans(keyring.current.address),
    ]);

    final data = Map<String, LoanData>();
    final stableCoinDecimals = plugin.networkState.tokenDecimals[
        plugin.networkState.tokenSymbol.indexOf(karura_stable_coin)];
    loans[1].forEach((i) {
      final String token = i['currency']['token'];
      final tokenDecimals = plugin.networkState
          .tokenDecimals[plugin.networkState.tokenSymbol.indexOf(token)];
      data[token] = LoanData.fromJson(
        Map<String, dynamic>.from(i),
        loans[0].firstWhere((t) => t.token == token),
        BigInt.zero,
        stableCoinDecimals,
        tokenDecimals,
      );
    });
    plugin.store.loan.setAccountLoans(data);
  }
}
