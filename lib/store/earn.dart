import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/api/types/dexPoolInfoDataV2.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';

part 'earn.g.dart';

class EarnStore extends _EarnStore with _$EarnStore {
  EarnStore(StoreCache cache) : super(cache);
}

abstract class _EarnStore with Store {
  _EarnStore(this.cache);

  final StoreCache cache;

  @observable
  IncentivesData incentives = IncentivesData();

  @observable
  List<DexPoolData> dexPools = [];

  @observable
  List<DexPoolData> bootstraps = [];

  @observable
  ObservableMap<String, DexPoolInfoDataV2> dexPoolInfoMap =
      ObservableMap<String, DexPoolInfoDataV2>();

  @observable
  List<dynamic> dexIncentiveLoyaltyEndBlock;

  @action
  void setDexIncentiveLoyaltyEndBlock(List<dynamic> list) {
    dexIncentiveLoyaltyEndBlock = list;
  }

  @action
  void setDexPools(List<DexPoolData> list) {
    dexPools = list;
  }

  @action
  void setBootstraps(List<DexPoolData> list) {
    bootstraps = list;
  }

  @action
  void setDexPoolInfo(Map<String, DexPoolInfoDataV2> data,
      {bool reset = false}) {
    if (reset) {
      dexPoolInfoMap = ObservableMap<String, DexPoolInfoDataV2>();
    } else {
      dexPoolInfoMap.addAll(data);
    }
  }

  @action
  void setIncentives(IncentivesData data) {
    incentives = data;
  }

  getdexIncentiveLoyaltyEndBlock(PluginKarura plugin) async {
    if (dexIncentiveLoyaltyEndBlock == null) {
      setDexIncentiveLoyaltyEndBlock(
          await plugin.api.earn.queryDexIncentiveLoyaltyEndBlock());
    }
  }
}
