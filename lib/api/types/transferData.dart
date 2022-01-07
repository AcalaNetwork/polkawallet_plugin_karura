import 'package:polkawallet_ui/utils/format.dart';

class TransferData extends _TransferData {
  static TransferData fromJson(Map json, int decimals) {
    final res = TransferData();
    res.from = json['from']['id'];
    res.to = json['to']['id'];
    res.token = json['token']['id'];
    res.amount = Fmt.balance(json['amount'].toString(), decimals);
    res.hash = json['extrinsic']['id'];
    res.timestamp = (json['timestamp'] as String).replaceAll(' ', '');
    res.isSuccess = json['isSuccess'];
    return res;
  }
}

abstract class _TransferData {
  String? block;
  String? from = "";
  String? to = "";
  String amount = "";
  String? token = "";
  String? hash = "";
  String timestamp = "";
  bool? isSuccess = true;
}
