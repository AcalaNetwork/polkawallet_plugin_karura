import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/homaNewEnvData.dart';
import 'package:polkawallet_plugin_karura/api/types/homaPendingRedeemData.dart';
import 'package:polkawallet_plugin_karura/api/types/stakingPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';

part 'homa.g.dart';

class HomaStore extends _HomaStore with _$HomaStore {
  HomaStore(StoreCache cache) : super(cache);
}

abstract class _HomaStore with Store {
  _HomaStore(this.cache);

  final StoreCache cache;

  @observable
  HomaLitePoolInfoData poolInfo = HomaLitePoolInfoData();

  @observable
  HomaNewEnvData env;

  @observable
  HomaPendingRedeemData userInfo;

  @action
  void setHomaLitePoolInfoData(HomaLitePoolInfoData data) {
    poolInfo = data;
  }

  @action
  void setHomaEnv(HomaNewEnvData data) {
    env = data;
  }

  @action
  void setUserInfo(HomaPendingRedeemData data) {
    userInfo = data;
  }
}
