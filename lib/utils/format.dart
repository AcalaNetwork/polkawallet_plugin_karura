import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class PluginFmt {
  static String tokenView(String token) {
    if (token == karura_stable_coin) {
      return karura_stable_coin_view;
    }
    if (token == acala_token_ren_btc) {
      return acala_token_ren_btc_view;
    }
    if (token == acala_token_polka_btc) {
      return acala_token_polka_btc_view;
    }
    if (token == 'VSKSM') {
      return 'vsKSM';
    }
    if (token.contains('-')) {
      return '${token.split('-').map((e) => PluginFmt.tokenView(e)).join('-')} LP';
    }
    return token ?? '';
  }

  static LiquidityShareInfo calcLiquidityShare(
      List<double> pool, List<double> user) {
    final isPoolLeftZero = pool[0] == 0.0;
    final isPoolRightZero = pool[1] == 0.0;
    final xRate = isPoolRightZero ? 0 : pool[0] / pool[1];
    final totalShare = isPoolRightZero
        ? (pool[0] * 2)
        : isPoolLeftZero
            ? (pool[1] * 2)
            : pool[0] + pool[1] * xRate;

    final userShare = isPoolRightZero
        ? (user[0] * 2)
        : isPoolLeftZero
            ? (user[1] * 2)
            : user[0] + user[1] * xRate;
    return LiquidityShareInfo(userShare, userShare / totalShare);
  }

  static List<TokenBalanceData> getBalancePair(
      PluginKarura plugin, List<String> tokenPair) {
    final symbols = plugin.networkState.tokenSymbol;

    TokenBalanceData balanceLeft;
    TokenBalanceData balanceRight;
    if (tokenPair.length > 0) {
      if (tokenPair[0] == symbols[0]) {
        balanceLeft = TokenBalanceData(
            id: tokenPair[0],
            symbol: tokenPair[0],
            decimals: plugin.networkState.tokenDecimals[0],
            amount: (plugin.balances.native?.availableBalance ?? 0).toString());
        balanceRight =
            plugin.store.assets.tokenBalanceMap[tokenPair[1].toUpperCase()];
      } else if (tokenPair[1] == symbols[0]) {
        balanceRight = TokenBalanceData(
            id: tokenPair[1],
            symbol: tokenPair[1],
            decimals: plugin.networkState.tokenDecimals[0],
            amount: (plugin.balances.native?.availableBalance ?? 0).toString());
        balanceLeft =
            plugin.store.assets.tokenBalanceMap[tokenPair[0].toUpperCase()];
      } else {
        balanceLeft =
            plugin.store.assets.tokenBalanceMap[tokenPair[0].toUpperCase()];
        balanceRight =
            plugin.store.assets.tokenBalanceMap[tokenPair[1].toUpperCase()];
      }
    }
    return [balanceLeft, balanceRight];
  }

  static List<String> getAllDexTokens(PluginKarura plugin) {
    final List<String> tokens = [];
    plugin.store.earn.dexPools.forEach((e) {
      e.tokens.forEach((token) {
        if (tokens.indexOf(token['token']) < 0) {
          tokens.add(token['token']);
        }
      });
    });
    return tokens;
  }
}

class LiquidityShareInfo {
  LiquidityShareInfo(this.lp, this.ratio);
  final double lp;
  final double ratio;
}
