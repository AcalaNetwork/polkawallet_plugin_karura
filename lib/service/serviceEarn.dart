import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceEarn {
  ServiceEarn(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginKarura plugin;
  final Keyring keyring;
  final AcalaApi api;
  final PluginStore store;

  Map<String, double> _calcIncentives(
      Map rewards, List<DexPoolData> pools, int epochOfYear) {
    final res = Map<String, double>();
    rewards.forEach((k, v) {
      final amount =
          Fmt.balanceDouble(v.toString(), plugin.networkState.tokenDecimals[0]);
      final pool = pools
          .firstWhere((e) => e.tokens.map((t) => t['token']).join('-') == k);
      final poolInfo = store.earn.dexPoolInfoMap[k];

      /// poolValue = LPAmountOfPool / LPIssuance * token0Issuance * token0Price * 2;
      final stakingPoolValue = poolInfo.sharesTotal /
          poolInfo.issuance *
          (Fmt.bigIntToDouble(poolInfo.amountLeft, pool.pairDecimals[0]) *
                  store
                      .assets.marketPrices[pool.tokens[0]['token'].toString()] +
              Fmt.bigIntToDouble(poolInfo.amountRight, pool.pairDecimals[1]) *
                  store
                      .assets.marketPrices[pool.tokens[1]['token'].toString()]);

      /// rewardsRate = rewardsAmount * rewardsTokenPrice / poolValue;
      final rate = amount *
          store.assets.marketPrices[plugin.networkState.tokenSymbol[0]] /
          stakingPoolValue;
      if (amount > 0) {
        res[k] = rate * epochOfYear;
      } else {
        res[k] = 0;
      }
    });
    return res;
  }

  Map<String, double> _calcSavingRates(Map savingRates, int epochOfYear) {
    final res = Map<String, double>();
    savingRates.forEach((k, v) {
      final poolInfo = store.earn.dexPoolInfoMap[k];
      final rate = Fmt.balanceDouble(v.toString(), acala_price_decimals) / 2;
      if (rate > 0) {
        res[k] =
            rate * epochOfYear / (poolInfo.sharesTotal / poolInfo.issuance);
      } else {
        res[k] = 0;
      }
    });
    return res;
  }

  Map<String, double> _calcDeductionRates(Map deductionRates) {
    final res = Map<String, double>();
    deductionRates.forEach((k, v) {
      res[k] = Fmt.balanceDouble(v.toString(), acala_price_decimals);
    });
    return res;
  }

  Future<List<DexPoolData>> getDexPools() async {
    final pools = await api.swap.getTokenPairs();
    store.earn.setDexPools(pools);
    return pools;
  }

  Future<List<DexPoolData>> getBootstraps() async {
    final pools = await api.swap.getBootstraps();
    store.earn.setBootstraps(pools);
    return pools;
  }

  Future<void> queryDexPoolRewards(DexPoolData pool) async {
    final rewards = await api.swap.queryDexLiquidityPoolRewards([pool]);

    final blockTime = plugin.networkConst['babe'] == null
        ? BLOCK_TIME_DEFAULT
        : int.parse(plugin.networkConst['babe']['expectedBlockTime']);
    final epoch =
        int.parse(plugin.networkConst['incentives']['accumulatePeriod']);
    final epochOfYear = SECONDS_OF_YEAR * 1000 ~/ blockTime ~/ epoch;

    final res = Map<String, Map<String, double>>();
    res['incentives'] =
        _calcIncentives(rewards['incentives'], [pool], epochOfYear);
    res['savingRates'] = _calcSavingRates(rewards['savingRates'], epochOfYear);
    res['deductionRates'] = _calcDeductionRates(rewards['deductionRates']);
    res['deductionSavingRates'] =
        _calcDeductionRates(rewards['deductionSavingRates']);
    store.earn.setDexPoolRewards(res);
  }

  Future<void> queryDexPoolInfo(String poolId) async {
    final info =
        await api.swap.queryDexPoolInfo(poolId, keyring.current.address);
    store.earn.setDexPoolInfo(info);
  }

  double getSwapFee() {
    return plugin.networkConst['dex']['getExchangeFee'][0] /
        plugin.networkConst['dex']['getExchangeFee'][1];
  }

  Future<void> updateDexPoolInfo({String poolId}) async {
    // 1. query all dexPools
    if (store.earn.dexPools.length == 0) {
      await getDexPools();
    }
    // 2. default poolId is the first pool or KAR-kUSD
    final tabNow = poolId ??
        (store.earn.dexPools.length > 0
            ? store.earn.dexPools[0].tokens.map((e) => e['token']).join('-')
            : (plugin.basic.name == plugin_name_karura
                ? 'KAR-KUSD'
                : 'ACA-AUSD'));
    // 3. query mining pool info
    await Future.wait([
      queryDexPoolInfo(tabNow),
      plugin.service.assets.queryMarketPrices(PluginFmt.getAllDexTokens(plugin))
    ]);

    // 4. query mining pool rewards & calculate APY
    queryDexPoolRewards(plugin.store.earn.dexPools.firstWhere(
        (e) => e.tokens.map((t) => t['token']).join('-') == tabNow));
  }

  Future<void> updateAllDexPoolInfo() async {
    if (store.earn.dexPools.length == 0) {
      await getDexPools();
    }

    plugin.service.assets.queryMarketPrices(PluginFmt.getAllDexTokens(plugin));

    await Future.wait(store.earn.dexPools.map(
        (e) => queryDexPoolInfo(e.tokens.map((e) => e['token']).join('-'))));

    store.earn.dexPools.forEach((e) => queryDexPoolRewards(e));
  }
}
