import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoDataV2.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';

part 'earn.g.dart';

class EarnStore extends _EarnStore with _$EarnStore {
  EarnStore(StoreCache cache) : super(cache);
}

abstract class _EarnStore with Store {
  _EarnStore(this.cache);

  final StoreCache cache;

  @observable
  ObservableMap<String, double> swapPoolRewards =
      ObservableMap<String, double>();

  @observable
  ObservableMap<String, double> swapPoolSavingRewards =
      ObservableMap<String, double>();

  @observable
  ObservableMap<String, double> loyaltyBonus = ObservableMap<String, double>();

  @observable
  ObservableMap<String, double> savingLoyaltyBonus =
      ObservableMap<String, double>();

  @observable
  IncentivesData incentives = IncentivesData();

  @observable
  List<DexPoolData> dexPools = [];

  @observable
  List<DexPoolData> bootstraps = [];

  @observable
  ObservableMap<String, DexPoolInfoData> dexPoolInfoMap =
      ObservableMap<String, DexPoolInfoData>();

  @observable
  ObservableMap<String, DexPoolInfoDataV2> dexPoolInfoMapV2 =
      ObservableMap<String, DexPoolInfoDataV2>();

  @action
  void setDexPools(List<DexPoolData> list) {
    dexPools = list;
  }

  @action
  void setBootstraps(List<DexPoolData> list) {
    bootstraps = list;
  }

  @action
  void setDexPoolInfo(Map<String, DexPoolInfoData> data) {
    dexPoolInfoMap.addAll(data);
  }

  @action
  void setDexPoolInfoV2(Map<String, DexPoolInfoDataV2> data) {
    dexPoolInfoMapV2.addAll(data);
  }

  @action
  void setDexPoolRewards(Map<String, Map<String, double>> data) {
    swapPoolRewards.addAll(data['incentives']);
    swapPoolSavingRewards.addAll(data['savingRates']);
    loyaltyBonus.addAll(data['deductionRates']);
    savingLoyaltyBonus.addAll(data['deductionSavingRates']);
  }

  @action
  void setIncentives(IncentivesData data) {
    incentives = data;
  }

  @action
  void loadCache(String pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    dexPoolInfoMap = ObservableMap<String, DexPoolInfoData>();
  }
}
