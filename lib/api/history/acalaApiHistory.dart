import 'package:polkawallet_plugin_karura/api/history/acalaServiceHistory.dart';
import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';

class AcalaApiHistory {
  AcalaApiHistory(this.service);

  final AcalaServiceHistory service;

  Future<List<HistoryData>> queryHistory(String type, String? address,
      {Map<String, dynamic> params = const {}}) async {
    final List? res = await service.queryHistory(type, address, params);
    return res?.map((e) => HistoryData.fromJson(e)).toList() ?? [];
  }
}
