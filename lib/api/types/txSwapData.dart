import 'dart:convert';

class TxSwapData extends _TxSwapData {
  static TxSwapData fromJson(
      Map json, List<String> symbols, List<int> decimals) {
    final data = TxSwapData();
    data.action = json['extrinsic']['method'];
    data.hash = json['extrinsic']['id'];

    switch (data.action) {
      case "swapWithExactSupply":
      case "swapWithExactTarget":
        final List path = jsonDecode(json['data'][1]['value']);
        data.tokenPay = path[0]['token'];
        data.tokenReceive = path[path.length - 1]['token'];
        if (json['data'][2]['type'] == 'Balance') {
          data.amountPay = json['data'][2]['value'].toString();
          data.amountReceive = json['data'][3]['value'].toString();
        } else {
          data.amountPay = jsonDecode(json['data'][2]['value'])[0].toString();
          data.amountReceive =
              jsonDecode(json['data'][2]['value'])[1].toString();
        }
        break;
      case "addProvision":
      case "addLiquidity":
      case "removeLiquidity":
        data.tokenPay = jsonDecode(json['data'][1]['value'])['token'];
        data.tokenReceive = jsonDecode(json['data'][3]['value'])['token'];
        data.amountPay = json['data'][2]['value'];
        data.amountReceive = json['data'][4]['value'];
        data.amountShare =
            (json['data'] as List).length > 5 ? json['data'][5]['value'] : '';
        break;
    }

    data.time = (json['extrinsic']['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['extrinsic']['isSuccess'];
    return data;
  }
}

abstract class _TxSwapData {
  String block;
  String hash;
  String action;
  String tokenPay;
  String tokenReceive;
  String amountPay;
  String amountReceive;
  String amountShare;
  String time;
  bool isSuccess = true;
}
