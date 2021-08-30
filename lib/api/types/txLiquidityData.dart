import 'dart:convert';

import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxDexLiquidityData extends _TxDexLiquidityData {
  static const String actionDeposit = 'addLiquidity';
  static const String actionWithdraw = 'removeLiquidity';
  static TxDexLiquidityData fromJson(Map<String, dynamic> json,
      String stableCoinSymbol, List<String> symbols, List<int> decimals) {
    final args = jsonDecode(json['args']);

    final data = TxDexLiquidityData();
    data.hash = json['extrinsic']['id'];

    if (json['method'] == 'claimRewards') {
      data.action = Map.of(args[0]).keys.toList()[0];
    } else {
      data.action = json['method'];
    }

    final pair = [args[0]['token'], args[1]['token']];
    final pairView = pair.map((e) => PluginFmt.tokenView(e)).toList();
    final poolId = pair.join('-');
    final shareTokenView = PluginFmt.tokenView(poolId);

    final token = pair.firstWhere((e) => e != stableCoinSymbol);
    final stableCoinDecimals = decimals[symbols.indexOf(stableCoinSymbol)];
    final tokenDecimals = decimals[symbols.indexOf(token)];
    final shareDecimals = stableCoinDecimals >= tokenDecimals
        ? stableCoinDecimals
        : tokenDecimals;
    final decimalsLeft =
        pair[0] == stableCoinSymbol ? stableCoinDecimals : tokenDecimals;
    final decimalsRight =
        pair[0] == stableCoinSymbol ? tokenDecimals : stableCoinDecimals;

    switch (data.action) {
      case actionDeposit:
        data.amountLeft =
            '${Fmt.balance(args[2].toString(), decimalsLeft)} ${pairView[0]}';
        data.amountRight =
            '${Fmt.balance(args[3].toString(), decimalsRight)} ${pairView[1]}';
        data.withStake = args[4];
        break;
      case actionWithdraw:
        data.amountShare =
            '${Fmt.balance(args[2].toString(), shareDecimals)} $shareTokenView';
        data.withStake = args[3];
        break;
    }
    data.time = json['extrinsic']['timestamp'] as String;
    data.isSuccess = json['isSuccess'];
    return data;
  }
}

abstract class _TxDexLiquidityData {
  String block;
  String hash;
  String action;
  String amountLeft;
  String amountRight;
  String amountShare;
  String time;
  bool isSuccess = true;
  bool withStake = false;
}
