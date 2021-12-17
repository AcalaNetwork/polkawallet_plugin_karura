import 'dart:convert';
import 'dart:math';

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
  static TxLoanData fromJson(
      Map json, String stableCoinSymbol, PluginKarura plugin) {
    TxLoanData data = TxLoanData();
    data.event = json['type'];
    data.hash = json['extrinsic']['id'];

    final jsonData = json['data'] as List;
    data.token = AssetsUtils.tokenSymbolFromCurrencyId(
        plugin.store.assets.tokenBalanceMap, jsonDecode(jsonData[1]['value']));
    final token = AssetsUtils.getBalanceFromTokenSymbol(plugin, data.token);

    data.collateral = Fmt.balanceInt(jsonData[2]['value'].toString());
    data.debit = jsonData.length > 4
        ? Fmt.balanceInt(jsonData[3]['value'].toString()) *
            Fmt.balanceInt(
                (jsonData[4]['value'] ?? '1000000000000').toString()) ~/
            BigInt.from(pow(10, acala_price_decimals))
        : BigInt.zero;
    data.amountCollateral =
        Fmt.priceFloorBigInt(BigInt.zero - data.collateral, token.decimals);
    data.amountDebit = Fmt.priceCeilBigInt(data.debit,
        plugin.store.assets.tokenBalanceMap[karura_stable_coin].decimals);
    if (data.event == 'ConfiscateCollateralAndDebit') {
      data.actionType = actionLiquidate;
    } else if (data.collateral == BigInt.zero) {
      data.actionType =
          data.debit > BigInt.zero ? actionTypeBorrow : actionTypePayback;
    } else if (data.debit == BigInt.zero) {
      data.actionType = data.collateral > BigInt.zero
          ? actionTypeDeposit
          : actionTypeWithdraw;
    } else if (data.debit < BigInt.zero) {
      data.actionType = actionTypePayback;
    } else {
      data.actionType = actionTypeCreate;
    }

    data.time = (json['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['extrinsic']['isSuccess'];
    return data;
  }
}

abstract class _TxLoanData {
  String block;
  String hash;

  String token;
  String event;
  String actionType;
  BigInt collateral;
  BigInt debit;
  String amountCollateral;
  String amountDebit;

  String time;
  bool isSuccess = true;
}
