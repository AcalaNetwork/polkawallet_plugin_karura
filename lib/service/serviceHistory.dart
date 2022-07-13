import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ServiceHistory {
  ServiceHistory(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginKarura plugin;
  final Keyring keyring;
  final AcalaApi? api;
  final PluginStore? store;

  Future<List<HistoryData>> getTransfers(String token) async {
    final transfers = await api!.history.queryHistory(
        'transfer', keyring.current.address,
        params: {'token': token});
    store!.history.setTransfersMap(token, transfers);
    return transfers;
  }

  Future<List<HistoryData>> getEarns() async {
    final earns =
        await api!.history.queryHistory('earn', keyring.current.address);
    store!.history.setEarns(earns);
    return earns;
  }

  Future<List<HistoryData>> getSwaps() async {
    final swaps =
        await api!.history.queryHistory('swap', keyring.current.address);
    store!.history.setSwaps(swaps);
    return swaps;
  }

  Future<List<HistoryData>> getLoans() async {
    final loans =
        await api!.history.queryHistory('loan', keyring.current.address);
    store!.history.setLoans(loans);
    return loans;
  }

  Future<List<HistoryData>> getHomas() async {
    final homas =
        await api!.history.queryHistory('homa', keyring.current.address);
    store!.history.setHomas(homas);
    return homas;
  }
}
