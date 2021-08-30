import 'package:polkawallet_ui/utils/format.dart';

class TxHomaData extends _TxHomaData {
  static const String actionMint = 'mint';
  static const String actionRedeem = 'redeem';
  static const String actionWithdrawRedemption = 'withdrawRedemption';

  static const String redeemTypeNow = 'Immediately';
  static const String redeemTypeEra = 'Target';
  static const String redeemTypeWait = 'WaitForUnbonding';
  static TxHomaData fromJson(Map<String, dynamic> json) {
    TxHomaData data = TxHomaData();
    data.action = json['extrinsic']['method'];
    data.hash = json['extrinsic']['id'];

    data.action = json['extrinsic']['method'];
    data.amountPay = Fmt.balanceInt(json['data'][1]['value'].toString());
    data.amountReceive = Fmt.balanceInt(json['data'][2]['value'].toString());

    data.time = (json['extrinsic']['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['extrinsic']['isSuccess'];
    return data;
  }
}

abstract class _TxHomaData {
  String block;
  String hash;

  String action;
  BigInt amountPay;
  BigInt amountReceive;

  String time;
  bool isSuccess = true;
}
