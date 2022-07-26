import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxSwapData extends _TxSwapData {
  static TxSwapData fromJson(Map json, PluginKarura plugin) {
    final data = TxSwapData();
    data.action = json['type'];
    data.hash = json['extrinsic']['id'];

    switch (data.action) {
      case "swap":
        final List path = jsonDecode(json['data'][1]['value']);
        final tokenPay = AssetsUtils.tokenDataFromCurrencyId(plugin, path[0]);
        final tokenReceive =
            AssetsUtils.tokenDataFromCurrencyId(plugin, path[path.length - 1]);
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
            plugin, jsonDecode(json['data'][1]['value']));
        final tokenReceive = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['data'][3]['value']));
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

  static TxSwapData fromTaigaJson(Map json, PluginKarura plugin) {
    final data = TxSwapData();
    data.action = json['__typename'].toString().toLowerCase();
    data.hash = json['extrinsicId'];

    switch (data.action) {
      case "swap":
        final tokenPay = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['outputAsset']));
        final tokenReceive = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['inputAsset']));
        data.tokenPay = tokenPay.symbol;
        data.tokenReceive = tokenReceive.symbol;
        data.amountPay = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['outputAmount']), tokenPay.decimals ?? 12,
            lengthMax: 6);
        data.amountReceive = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['inputAmount']), tokenReceive.decimals ?? 12,
            lengthMax: 6);
        break;
      case "mint":
        final taigaData = plugin.store!.earn.taigaTokenPairs.firstWhere(
            (element) => element.tokenNameId == "sa://${json['poolId']}");
        final tokenPair = taigaData.tokens!
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
            .toList();

        tokenPair.forEach((element) {
          final index = tokenPair.indexOf(element);
          data.amounts.add(_token()
            ..amount = Fmt.priceFloorBigInt(
                Fmt.balanceInt(
                    json['inputAmounts'].toString().split(",")[index]),
                tokenPair[index].decimals ?? 12,
                lengthMax: 6)
            ..symbol = element.symbol);
        });
        break;
      case "proportionredeem":
      case "singleredeem":
      case "multiredeem":
        final tokenPay = AssetsUtils.getBalanceFromTokenNameId(
            plugin, "sa://${json['poolId']}");
        data.tokenPay = tokenPay.symbol;
        data.amountPay = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['inputAmount']), tokenPay.decimals ?? 12,
            lengthMax: 6);
        break;
    }

    data.time = (json['timestamp'] as String).replaceAll(' ', '');
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
  bool? isSuccess;
  List<_token> amounts = [];
}

class _token {
  String? symbol;
  String? amount;

  String toTokenString() {
    return "$amount ${PluginFmt.tokenView(symbol)}";
  }
}
