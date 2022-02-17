import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxSwapData extends _TxSwapData {
  static TxSwapData fromJson(Map json, PluginKarura plugin) {
    final data = TxSwapData();
    data.action = json['type'];
    data.hash = json['extrinsic']['id'];

    switch (data.action) {
      case "swap":
        final List path = jsonDecode(json['data'][1]['value']);
        final tokenPay = AssetsUtils.tokenDataFromCurrencyId(plugin, path[0])!;
        final tokenReceive =
            AssetsUtils.tokenDataFromCurrencyId(plugin, path[path.length - 1])!;
        data.tokenPay = tokenPay.symbol;
        data.tokenReceive = tokenReceive.symbol;
        if (json['data'][2]['type'] == 'Balance') {
          data.amountPay = Fmt.priceFloorBigInt(
              Fmt.balanceInt(json['data'][2]['value'].toString()),
              tokenPay.decimals ?? 12,
              lengthMax: 6);
          data.amountReceive = Fmt.priceFloorBigInt(
              Fmt.balanceInt(json['data'][3]['value'].toString()),
              tokenReceive.decimals ?? 12,
              lengthMax: 6);
        } else {
          data.amountPay = Fmt.priceFloorBigInt(
              Fmt.balanceInt(
                  jsonDecode(json['data'][2]['value'])[0].toString()),
              tokenPay.decimals ?? 12,
              lengthMax: 6);
          data.amountReceive = Fmt.priceFloorBigInt(
              Fmt.balanceInt(
                  jsonDecode(json['data'][2]['value'])[path.length - 1]
                      .toString()),
              tokenReceive.decimals ?? 12,
              lengthMax: 6);
        }
        break;
      case "addProvision":
      case "addLiquidity":
      case "removeLiquidity":
        final tokenPay = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['data'][1]['value']))!;
        final tokenReceive = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['data'][3]['value']))!;
        data.tokenPay = tokenPay.symbol;
        data.tokenReceive = tokenReceive.symbol;
        data.amountPay = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['data'][2]['value'].toString()),
            tokenPay.decimals ?? 12,
            lengthMax: 6);
        data.amountReceive = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['data'][4]['value'].toString()),
            tokenReceive.decimals ?? 12,
            lengthMax: 6);
        data.amountShare = (json['data'] as List).length > 5
            ? Fmt.priceFloorBigInt(
                Fmt.balanceInt(json['data'][5]['value'].toString()),
                tokenPay.decimals ?? 12,
                lengthMax: 6)
            : '';
        break;
    }

    data.time = (json['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['extrinsic']['isSuccess'];
    return data;
  }
}

abstract class _TxSwapData {
  String? block;
  String? hash;
  String? action;
  String? tokenPay;
  String? tokenReceive;
  String? amountPay;
  String? amountReceive;
  String? amountShare;
  late String time;
  bool? isSuccess = true;
}
