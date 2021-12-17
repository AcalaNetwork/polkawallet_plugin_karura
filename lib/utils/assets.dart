import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/types/aggregatedAssetsData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class AssetsUtils {
  static const categoryTokens = 'Tokens';
  static const categoryVaults = 'Vaults';
  static const categoryLP = 'LP Staking';
  static const categoryLPFree = 'LP Free';
  static const categoryRewards = 'Rewards';

  static List<AggregatedAssetsData> aggregatedAssetsDataFromJson(
      Map assetsMap, BalancesStore balances, Map<String, double> marketPrices) {
    final lpFreeMapInt = {};
    balances.tokens?.forEach((e) {
      if (e.id.contains('-')) {
        final amount = BigInt.tryParse(e.amount) ?? BigInt.zero;
        if (amount > BigInt.zero) {
          lpFreeMapInt[e.id] = amount;
        }
      }
    });

    final List<AggregatedAssetsData> list = assetsMap.keys.map((k) {
      final data = AggregatedAssetsData();
      data.category = k;
      data.assets =
          List<AggregatedAssetsItemData>.from(assetsMap[k].keys.map((key) {
        final item = AggregatedAssetsItemData();
        item.token = key;
        item.amount = double.parse(assetsMap[k][key].toString());
        item.value = (marketPrices[key] ?? 0) * item.amount;
        return item;
      }).toList());
      data.value = data.assets.length > 0
          ? data.assets.map((e) => e.value).reduce((v, e) => v + e)
          : 0;
      return data;
    }).toList();

    if (assetsMap[categoryLPFree].keys.length > 0) {
      final lpFreeValueItem = AggregatedAssetsItemData();
      lpFreeValueItem.token = 'FreeLP';
      lpFreeValueItem.amount = 0;
      lpFreeValueItem.value = list
          .firstWhere((e) => e.category == categoryLPFree)
          .assets
          .map((e) => e.value)
          .reduce((a, b) => a + b);
      final tokensData = list.firstWhere((e) => e.category == categoryTokens);
      tokensData.assets.add(lpFreeValueItem);
      tokensData.value += lpFreeValueItem.value;
    }

    list.removeWhere((i) => i.category == categoryLPFree);

    return list;
  }

  static Map currencyIdFromTokenData(
      PluginKarura plugin, TokenBalanceData token) {
    switch (token.type) {
      case 'DexShare':
        return {
          'DEXShare': token.symbol
              .toUpperCase()
              .split('-')
              .map((e) => currencyIdFromTokenSymbol(plugin, e))
              .toList(),
          'decimals': token.decimals
        };
      case 'ForeignAsset':
        return {'ForeignAsset': token.id, 'decimals': token.decimals};
      case 'Token':
        return {
          'Token': token.symbol.toUpperCase(),
          'decimals': token.decimals
        };
      default:
        return {
          'Token': token.symbol.toUpperCase(),
          'decimals': token.decimals
        };
    }
  }

  static String tokenSymbolFromCurrencyId(
      Map<String, TokenBalanceData> tokenBalanceMap, Map currencyId) {
    if (currencyId['token'] != null) {
      return currencyId['token'];
    }
    if (currencyId['foreignAsset'] != null) {
      return tokenBalanceMap.values
          .firstWhere((e) => e.id == currencyId['foreignAsset'].toString())
          .symbol;
    }
    return '';
  }

  static Map currencyIdFromTokenSymbol(
      PluginKarura plugin, String tokenSymbol) {
    return currencyIdFromTokenData(
        plugin, getBalanceFromTokenSymbol(plugin, tokenSymbol));
  }

  static TokenBalanceData getBalanceFromTokenSymbol(
      PluginKarura plugin, String tokenSymbol) {
    final symbols = plugin.networkState.tokenSymbol;

    if (tokenSymbol == symbols[0]) {
      return TokenBalanceData(
          id: tokenSymbol,
          symbol: tokenSymbol,
          type: 'Token',
          decimals: plugin.networkState.tokenDecimals[0],
          amount: (plugin.balances.native?.availableBalance ?? 0).toString());
    }
    return plugin.store.assets.tokenBalanceMap[tokenSymbol.toUpperCase()] ??
        TokenBalanceData();
  }

  static List<TokenBalanceData> getBalancePairFromTokenSymbol(
      PluginKarura plugin, List<String> tokenPair) {
    return tokenPair.map((e) => getBalanceFromTokenSymbol(plugin, e)).toList();
  }
}
