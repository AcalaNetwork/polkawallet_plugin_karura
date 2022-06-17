import 'dart:math';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';

class TxMultiplyData extends _TxMultiplyData {
  static const String expand = 'expandPositionCollateral';
  static const String shrink = 'shrinkPositionDebit';

  static TxMultiplyData fromJson(Map json, PluginKarura plugin) {
    final data = TxMultiplyData();
    data.action = json['method'];
    data.hash = json['id'];

    final jsonData = json['updatePositions']["nodes"][0];
    final token = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {"token": jsonData['collateralId']});
    data.token = token.symbol;
    data.collateral =
        Fmt.balanceInt(jsonData['collateralAdjustment'].toString());
    data.debit = Fmt.balanceInt(
            (jsonData['debitAdjustment'] ?? '0').toString()) *
        Fmt.balanceInt(
            (jsonData['debitExchangeRate'] ?? '1000000000000').toString()) ~/
        BigInt.from(pow(10, acala_price_decimals));
    data.amountCollateral =
        Fmt.priceFloorBigInt(data.collateral!, token.decimals ?? 12);
    data.amountDebit = Fmt.priceCeilBigInt(data.debit,
        plugin.store!.assets.tokenBalanceMap[karura_stable_coin]!.decimals!);

    data.time = (json['updatePositions']["nodes"][0]['timestamp'] as String)
        .replaceAll(' ', '');
    data.isSuccess = json['updatePositions']["nodes"][0]['isSuccess'];
    return data;
  }
}

abstract class _TxMultiplyData {
  String? hash;
  String? action;
  String? token;
  BigInt? collateral;
  BigInt? debit;
  String? amountCollateral;
  String? amountDebit;
  late String time;
  bool? isSuccess = true;
}
