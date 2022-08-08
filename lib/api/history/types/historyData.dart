class HistoryData extends _HistoryData {
  static HistoryData fromJson(Map json) {
    final res = new HistoryData();
    res.message = json['message'] as String?;
    res.hash = json['hash'] as String?;
    res.resolveLinks = json['resolveLinks'] as String?;
    res.data = Map.from(json['data']);
    res.event = json['event'] as String?;
    return res;
  }
}

abstract class _HistoryData {
  String? message;
  Map<String, dynamic>? data;
  String? hash;
  String? resolveLinks;
  String? event;
}
