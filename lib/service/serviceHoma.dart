import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/types/stakingPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ServiceHoma {
  ServiceHoma(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginKarura plugin;
  final Keyring keyring;
  final AcalaApi api;
  final PluginStore store;

  Future<StakingPoolInfoData> queryHomaStakingPool() async {
    final res = await api.homa.queryHomaStakingPool();
    store.homa.setStakingPoolInfoData(res);
    return res;
  }

  Future<HomaLitePoolInfoData> queryHomaLiteStakingPool() async {
    final res = await api.homa.queryHomaLiteStakingPool();
    store.homa.setHomaLitePoolInfoData(res);
    return res;
  }

  Future<HomaUserInfoData> queryHomaUserInfo(String address) async {
    final res = await api.homa.queryHomaUserInfo(address);
    store.homa.setHomaUserInfo(res);
    return res;
  }
}
