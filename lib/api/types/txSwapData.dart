import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxSwapData extends _TxSwapData {
  static TxSwapData fromHistory(HistoryData history, PluginKarura plugin) {
    final data = TxSwapData();
    data.action = history.event;
    data.hash = history.hash;

    final tokenPay = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': history.data!['token0Id']});
    final tokenReceive = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': history.data!['token1Id']});
    data.tokenPay = tokenPay.symbol;
    data.tokenReceive = tokenReceive.symbol;
    data.amountPay = Fmt.priceFloorBigInt(
        Fmt.balanceInt(history.data!['token0Amount']), tokenPay.decimals ?? 12,
        lengthMax: 6);
    data.amountReceive = Fmt.priceFloorBigInt(
        Fmt.balanceInt(history.data!['token1Amount']),
        tokenReceive.decimals ?? 12,
        lengthMax: 6);
    data.amountShare = Fmt.priceFloorBigInt(
        Fmt.balanceInt(history.data!['shareAmount']), tokenPay.decimals ?? 12,
        lengthMax: 6);

    data.time = (history.data!['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = true;
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
