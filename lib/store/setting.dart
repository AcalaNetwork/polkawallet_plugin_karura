import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';

part 'setting.g.dart';

class SettingStore extends _SettingStore with _$SettingStore {
  SettingStore(StoreCache cache) : super(cache);
}

abstract class _SettingStore with Store {
  _SettingStore(this.cache);

  final StoreCache cache;

  @observable
  Map liveModules = Map();

  @action
  void setLiveModules(Map value) {
    liveModules = value;
  }
}
