import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
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

  IncentivesData _calcIncentivesAPR(IncentivesData data) {
    final pools = plugin.store.earn.dexPools.toList();
    data.dex.forEach((k, v) {
      final poolIndex = pools.indexWhere((e) => e.tokenNameId == k);
      if (poolIndex < 0) {
        return;
      }
      final pool = pools[poolIndex];
      final balancePair = pool.tokens
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
          .toList();

      final poolInfo = store.earn.dexPoolInfoMap[k];
      final prices = store.assets.marketPrices;

      /// poolValue = LPAmountOfPool / LPIssuance * token0Issuance * token0Price * 2;
      final stakingPoolValue = poolInfo.sharesTotal /
          poolInfo.issuance *
          (Fmt.bigIntToDouble(poolInfo.amountLeft, balancePair[0].decimals) *
                  (prices[balancePair[0].symbol] ?? 0) +
              Fmt.bigIntToDouble(
                      poolInfo.amountRight, balancePair[1].decimals) *
                  (prices[balancePair[1].symbol] ?? 0));

      v.forEach((e) {
        /// rewardsRate = rewardsAmount * rewardsTokenPrice / poolValue;
        final rate = e.amount * (prices[e.tokenNameId] ?? 0) / stakingPoolValue;
        e.apr = rate > 0 ? rate : 0;
      });
    });

    data.dexSaving.forEach((k, v) {
      final poolInfo = store.earn.dexPoolInfoMap[k];
      v.forEach((e) {
        e.apr = e.amount > 0
            ? e.amount / (poolInfo.sharesTotal / poolInfo.issuance)
            : 0;
      });
    });

    return data;
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

  Future<void> queryIncentives() async {
    final res = await api.earn.queryIncentives();
    store.earn.setIncentives(_calcIncentivesAPR(res));
  }

  Future<void> queryDexPoolInfo() async {
    final info = await api.swap.queryDexPoolInfo(keyring.current.address);
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
            ? store.earn.dexPools[0].tokenNameId
            : (plugin.basic.name == plugin_name_karura
                ? 'lp://KAR/KUSD'
                : 'lp://ACA/AUSD'));
    // 3. query mining pool info
    await Future.wait([
      queryDexPoolInfo(),
      plugin.service.assets.queryMarketPrices(
          PluginFmt.getAllDexTokens(plugin).map((e) => e.symbol).toList())
    ]);
  }

  Future<void> updateAllDexPoolInfo() async {
    if (store.earn.dexPools.length == 0) {
      await getDexPools();
    }

    plugin.service.assets.queryMarketPrices(
        PluginFmt.getAllDexTokens(plugin).map((e) => e.symbol).toList());

    await queryDexPoolInfo();

    queryIncentives();
  }
}
