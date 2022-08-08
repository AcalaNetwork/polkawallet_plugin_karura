import 'dart:math';

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
  static const String actionClose = 'close';

  static const String actionTypeDepositFilter = 'Deposit';
  static const String actionTypeWithdrawFilter = 'Withdraw';
  static const String actionTypeBorrowFilter = 'Mint';
  static const String actionTypePaybackFilter = 'Payback';
  static const String actionTypeCreateFilter = 'Create';
  static const String actionLiquidateFilter = 'Liquidate';

  static TxLoanData fromJson(HistoryData history, PluginKarura plugin) {
    TxLoanData data = TxLoanData();
    data.event = history.event;
    data.hash = history.hash;
    data.message = history.message;
    data.resolveLinks = history.resolveLinks;
    final token = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': history.data!['collateralId']});
    data.token = token.symbol;

    switch (history.event) {
      case 'loans.PositionUpdated':
        data.collateral = Fmt.balanceInt(history.data!["collateralAdjustment"]);
        data.debit = Fmt.balanceInt(
                (history.data!['debitAdjustment'] ?? '0').toString()) *
            Fmt.balanceInt(
                (history.data!['debitExchangeRate'] ?? '1000000000000')
                    .toString()) ~/
            BigInt.from(pow(10, acala_price_decimals));
        break;
      case 'cdpEngine.LiquidateUnsafeCDP':
        data.collateral = Fmt.balanceInt(history.data!["collateralAmount"]);
        data.debit = Fmt.balanceInt(history.data!["badDebitVolumeUSD"]);
        break;
      case 'loans.CloseCDPInDebitByDEX':
        data.collateral = Fmt.balanceInt(history.data!["refundAmount"]) +
            Fmt.balanceInt(history.data!["soldAmount"]);
        data.debit = Fmt.balanceInt(history.data!["debitVolumeUSD"]);
    }

    data.amountCollateral = Fmt.priceFloorBigInt(
        data.collateral!, token.decimals ?? 12,
        lengthMax: 6);
    data.amountDebit = Fmt.priceCeilBigInt(data.debit,
        plugin.store!.assets.tokenBalanceMap[karura_stable_coin]!.decimals!,
        lengthMax: 6);
    if (data.event == 'cdpEngine.LiquidateUnsafeCDP') {
      data.actionType = TxLoanData.actionLiquidate;
    } else if (data.event == 'loans.CloseCDPInDebitByDEX') {
      data.actionType = TxLoanData.actionClose;
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
  String? resolveLinks;
  String? token;
  String? event;
  String? actionType;
  BigInt? collateral;
  BigInt? debit;
  String? amountCollateral;
  String? amountDebit;
  String? message;
  late String time;
  bool? isSuccess = true;
}
