import 'package:polkawallet_ui/utils/format.dart';

class TxHomaData extends _TxHomaData {
  static const String actionMint = 'Minted';
  static const String actionRedeemed = 'Redeemed';
  static const String actionRedeem = 'RedeemRequest';
  static const String actionRedeemCancel = 'RedeemRequestCancelled';
  static const String actionRedeemedByFastMatch = 'RedeemedByFastMatch';
  static const String actionWithdrawRedemption = 'WithdrawRedemption';
  static const String actionRedeemedByUnbond = 'RedeemedByUnbond';

  static TxHomaData fromJson(Map<String, dynamic> json) {
    TxHomaData data = TxHomaData();
    data.action = json['type'];
    if (json['extrinsic'] != null) {
      data.hash = json['extrinsic']['id'];
      data.isSuccess = json['extrinsic']['isSuccess'];
    }

    switch (data.action) {
      case actionMint:
        data.amountPay = Fmt.balanceInt(json['data'][1]['value'].toString());
        data.amountReceive =
            Fmt.balanceInt(json['data'][2]['value'].toString());
        break;
      case actionRedeem:
        data.amountPay = Fmt.balanceInt(json['data'][1]['value'].toString());
        break;
      case actionRedeemed:
      case actionRedeemCancel:
      case actionWithdrawRedemption:
        data.amountReceive =
            Fmt.balanceInt(json['data'][1]['value'].toString());
        break;
      case actionRedeemedByFastMatch:
        data.amountPay = Fmt.balanceInt(json['data'][1]['value'].toString());
        data.amountReceive =
            Fmt.balanceInt(json['data'][3]['value'].toString());
        break;
      case actionRedeemedByUnbond:
        data.amountReceive =
            Fmt.balanceInt(json['data'][3]['value'].toString());
    }

    data.time = (json['timestamp'] as String).replaceAll(' ', '');
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
