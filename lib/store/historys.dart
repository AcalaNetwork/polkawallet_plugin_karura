import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';
part 'historys.g.dart';

class HistoryStore extends _HistoryStore with _$HistoryStore {
  HistoryStore(StoreCache? cache) : super(cache);
}

abstract class _HistoryStore with Store {
  _HistoryStore(this.cache);

  final StoreCache? cache;

  @observable
  Map<String?, List<HistoryData>> transfersMap =
      Map<String, List<HistoryData>>();

  @observable
  List<HistoryData>? swaps;

  @observable
  List<HistoryData>? earns;

  @observable
  List<HistoryData>? loans;

  @observable
  List<HistoryData>? homas;

  @action
  void setTransfersMap(String token, List<HistoryData> list) {
    final map = Map<String?, List<HistoryData>>();
    map.addAll(transfersMap);
    map[token] = list;
    transfersMap = map;
  }

  @action
  void setSwaps(List<HistoryData> list) {
    swaps = list;
  }

  @action
  void setEarns(List<HistoryData> list) {
    earns = list;
  }

  @action
  void setLoans(List<HistoryData> list) {
    loans = list;
  }

  @action
  void setHomas(List<HistoryData> list) {
    homas = list;
  }

  @action
  void loadCache(String? pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    transfersMap = Map<String, List<HistoryData>>();
    swaps = null;
    earns = null;
    loans = null;
    homas = null;
  }
}
