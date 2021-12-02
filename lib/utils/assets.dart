import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_plugin_karura/utils/types/aggregatedAssetsData.dart';
import 'package:polkawallet_sdk/api/types/networkStateData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AssetsUtils {
  static _addAsset(Map assetsMap, String token, double amount) {
    if (assetsMap[token] == null) {
      assetsMap[token] = amount;
    } else {
      assetsMap[token] += amount;
    }
  }

  static List<AggregatedAssetsData> calcAggregatedAssets(
    NetworkStateData networkState,
    BalancesStore balances,
    PluginStore store,
  ) {
    final categoryTokens = 'Tokens';
    final categoryVaults = 'Vaults';
    final categoryLP = 'LP Staking';
    final categoryLPFree = 'LP Free';
    final categoryRewards = 'Rewards';
    final Map<String, Map<String, double>> assetsMap = {
      categoryTokens: {},
      categoryVaults: {},
      categoryLP: {},
      categoryLPFree: {},
      categoryRewards: {},
    };
    final lpFreeMapInt = {};
    String res = '';

    /// 0. tokens.
    assetsMap[categoryTokens][networkState.tokenSymbol[0]] = Fmt.bigIntToDouble(
        Fmt.balanceTotal(balances.native), networkState.tokenDecimals[0]);
    balances.tokens?.forEach((e) {
      final amount = BigInt.tryParse(e.amount);
      if (amount > BigInt.zero) {
        if (e.id.contains('-')) {
          lpFreeMapInt[e.id] = amount;
        } else {
          _addAsset(assetsMap[categoryTokens], e.id,
              Fmt.bigIntToDouble(amount, e.decimals));
        }
      }
    });

    /// 1. vaults.
    final vaults = store.loan.loans.values.toList();
    vaults.forEach((e) {
      if (e.collaterals > BigInt.zero) {
        final collateralDecimal = networkState
            .tokenDecimals[networkState.tokenSymbol.indexOf(e.token)];
        final debitDecimal = networkState.tokenDecimals[
            networkState.tokenSymbol.indexOf(karura_stable_coin)];
        _addAsset(assetsMap[categoryVaults], e.token,
            Fmt.bigIntToDouble(e.collaterals, collateralDecimal));
        _addAsset(assetsMap[categoryVaults], karura_stable_coin,
            -Fmt.bigIntToDouble(e.debits, debitDecimal));

        res +=
            'collateral: ${Fmt.priceFloorBigInt(e.collaterals, collateralDecimal)} ${e.token}';
        res +=
            '\ndebts: ${Fmt.priceFloorBigInt(e.debits, debitDecimal)} $karura_stable_coin_view';
      }

      if (store.loan.collateralRewardsV2[e.token] != null) {
        String rewards = '';
        final loyalty = store.earn.incentives.loans[e.token] != null
            ? store.earn.incentives.loans[e.token][0].deduction
            : 0;
        store.loan.collateralRewardsV2[e.token].reward.forEach((i) {
          _addAsset(assetsMap[categoryRewards], networkState.tokenSymbol[0],
              double.tryParse(i['amount']) * (1 - loyalty));

          rewards +=
              '${Fmt.priceFloor(double.tryParse(i['amount']) * (1 - loyalty))} ';
        });

        res += '\nloan rewards: $rewards';
      }
    });

    /// 2. LP staking.
    final lp = store.earn.dexPoolInfoMap.values.toList();
    lp.forEach((e) {
      final tokenPair = e.token.split('-');
      final decimalPair = tokenPair
          .map((i) =>
              networkState.tokenDecimals[networkState.tokenSymbol.indexOf(i)])
          .toList();

      /// 2.1. LP staked & transferable.
      [e.shares, lpFreeMapInt[e.token] ?? BigInt.zero]
          .asMap()
          .forEach((i, lpAmount) {
        if (lpAmount > BigInt.zero) {
          final proportion = lpAmount / e.issuance;
          tokenPair.asMap().forEach((key, value) {
            _addAsset(
                i == 0 ? assetsMap[categoryLP] : assetsMap[categoryLPFree],
                tokenPair[key],
                Fmt.bigIntToDouble(key == 0 ? e.amountLeft : e.amountRight,
                        decimalPair[key]) *
                    proportion);
          });

          if (i == 0) {
            res +=
                '\nlp staked: ${Fmt.priceFloor(Fmt.bigIntToDouble(e.amountLeft, decimalPair[0]) * proportion)} '
                '+ ${Fmt.priceFloor(Fmt.bigIntToDouble(e.amountRight, decimalPair[1]) * proportion)} ${e.token} LP';
          }
        }
      });

      /// 2.2. lp rewards.
      String rewards = '';
      final loyalty = store.earn.incentives.dex != null
          ? store.earn.incentives.dex[e.token][0].deduction
          : 0;
      final savingLoyalty = store.earn.incentives.dexSaving != null &&
              store.earn.incentives.dexSaving[e.token] != null
          ? store.earn.incentives.dexSaving[e.token][0].deduction
          : 0;

      e.reward?.incentive?.forEach((i) {
        _addAsset(assetsMap[categoryRewards], i['token'],
            double.tryParse(i['amount']) * (1 - (loyalty ?? 0)));

        rewards +=
            '${Fmt.priceFloor(double.tryParse(i['amount']) * (1 - (loyalty ?? 0)))} ${i['token']} ';
      });
      if ((e?.reward?.saving ?? 0) > 0) {
        double rewardSaving =
            (e?.reward?.saving ?? 0) * (1 - (savingLoyalty ?? 0));
        if (rewardSaving < 0) {
          rewardSaving = 0;
        }
        _addAsset(assetsMap[categoryRewards], karura_stable_coin, rewardSaving);

        rewards += '+ $rewardSaving $karura_stable_coin_view';
      }
      res += '\n${e.token} pool rewards: $rewards';
    });

    final List<AggregatedAssetsData> data = assetsMap.keys.map((k) {
      final data = AggregatedAssetsData();
      data.category = k;
      data.assets = assetsMap[k].keys.map((key) {
        final item = AggregatedAssetsItemData();
        item.token = key;
        item.amount = assetsMap[k][key];
        item.value = (store.assets.marketPrices[key] ?? 0) * item.amount;
        return item;
      }).toList();
      data.value = data.assets.length > 0
          ? data.assets.map((e) => e.value).reduce((v, e) => v + e)
          : 0;
      return data;
    }).toList();

    if (assetsMap[categoryLPFree].keys.length > 0) {
      data.firstWhere((i) => i.category == categoryTokens).assets.addAll(data
              .firstWhere((e) => e.category == categoryLPFree)
              .assets
              .map((e) {
            final item = AggregatedAssetsItemData();
            item.token = e.token;
            item.amount = Fmt.bigIntToDouble(lpFreeMapInt[e.token],
                balances.tokens.firstWhere((t) => t.id == e.token).decimals);
            item.value = e.value;
            return item;
          }));
    }
    data.forEach((element) => print(element));

    // print('tokens:');
    // print(tokensMap);
    // print('vaults:');
    // print(vaultsMap);
    // print('lp staked:');
    // print(lpStakingMap);
    // print('lp free:');
    // print(lpFreeMap);
    // print('rewards:');
    // print(rewardsMap);
    print(res);
    return data;
  }
}
