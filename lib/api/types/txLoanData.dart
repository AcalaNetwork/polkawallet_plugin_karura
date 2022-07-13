import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxLoanData extends _TxLoanData {
  static const String actionTypeDeposit = 'deposit';
  static const String actionTypeWithdraw = 'withdraw';
  static const String actionTypeBorrow = 'mint';
  static const String actionTypePayback = 'payback';
  static const String actionTypeCreate = 'create';
  static const String actionLiquidate = 'liquidate';
  static TxLoanData fromJson(HistoryData history, PluginKarura plugin) {
    TxLoanData data = TxLoanData();
    data.event = history.event;
    data.hash = history.hash;

    final token = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': history.data!['collateralId']});
    data.token = token.symbol;

    data.collateral = Fmt.balanceInt(history.data!["collateralAdjustment"]);
    data.debit = Fmt.balanceInt(history.data!["debitAdjustment"]);

    data.amountCollateral = Fmt.priceFloorBigInt(
        BigInt.zero - data.collateral!, token.decimals ?? 12);
    data.amountDebit = Fmt.priceCeilBigInt(data.debit,
        plugin.store!.assets.tokenBalanceMap[karura_stable_coin]!.decimals!);
    if (data.event == 'ConfiscateCollateralAndDebit') {
      data.actionType = TxLoanData.actionLiquidate;
    } else if (data.collateral == BigInt.zero) {
      data.actionType = data.debit! > BigInt.zero
          ? TxLoanData.actionTypeBorrow
          : TxLoanData.actionTypePayback;
    } else if (data.debit == BigInt.zero) {
      data.actionType = data.collateral! > BigInt.zero
          ? TxLoanData.actionTypeDeposit
          : TxLoanData.actionTypeWithdraw;
    } else if (data.debit! < BigInt.zero) {
      data.actionType = TxLoanData.actionTypePayback;
    } else {
      data.actionType = TxLoanData.actionTypeCreate;
    }

    data.time = (history.data!['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = true;
    return data;
  }
}

abstract class _TxLoanData {
  String? block;
  String? hash;

  String? token;
  String? event;
  String? actionType;
  BigInt? collateral;
  BigInt? debit;
  String? amountCollateral;
  String? amountDebit;

  late String time;
  bool? isSuccess = true;
}
