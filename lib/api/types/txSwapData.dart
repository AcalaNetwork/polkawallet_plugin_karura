import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';

class TxSwapData extends _TxSwapData {
  static TxSwapData fromJson(Map json, PluginKarura plugin) {
    final data = TxSwapData();
    data.action = json['type'];
    data.hash = json['extrinsic']['id'];

    switch (data.action) {
      case "swap":
        final List path = jsonDecode(json['data'][1]['value']);
        data.tokenPay =
            AssetsUtils.tokenDataFromCurrencyId(plugin, path[0]).symbol;
        data.tokenReceive =
            AssetsUtils.tokenDataFromCurrencyId(plugin, path[path.length - 1])
                .symbol;
        if (json['data'][2]['type'] == 'Balance') {
          data.amountPay = json['data'][2]['value'].toString();
          data.amountReceive = json['data'][3]['value'].toString();
        } else {
          data.amountPay = jsonDecode(json['data'][2]['value'])[0].toString();
          data.amountReceive =
              jsonDecode(json['data'][2]['value'])[path.length - 1].toString();
        }
        break;
      case "addProvision":
      case "addLiquidity":
      case "removeLiquidity":
        data.tokenPay = AssetsUtils.tokenDataFromCurrencyId(
                plugin, jsonDecode(json['data'][1]['value']))
            .symbol;
        data.tokenReceive = AssetsUtils.tokenDataFromCurrencyId(
                plugin, jsonDecode(json['data'][3]['value']))
            .symbol;
        data.amountPay = json['data'][2]['value'];
        data.amountReceive = json['data'][4]['value'];
        data.amountShare =
            (json['data'] as List).length > 5 ? json['data'][5]['value'] : '';
        break;
    }

    data.time = (json['timestamp'] as String).replaceAll(' ', '');
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
