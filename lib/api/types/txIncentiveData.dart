import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxDexIncentiveData extends _TxDexIncentiveData {
  static const String actionStake = 'DepositDexShare';
  static const String actionUnStake = 'WithdrawDexShare';
  static const String actionClaimRewards = 'ClaimRewards';
  static const String actionPayoutRewards = 'PayoutRewards';
  static TxDexIncentiveData fromJson(
      Map<String, dynamic> json, PluginKarura plugin) {
    final data = TxDexIncentiveData();
    data.hash = json['extrinsic']['id'];
    data.event = json['type'];

    switch (data.event) {
      case actionClaimRewards:
        final pair = (jsonDecode(json['data'][1]['value'])['dex']['dexShare']
                as List)
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e).symbol)
            .toList();
        final poolId = pair.join('-');
        final rewardToken = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['data'][2]['value']));
        data.poolId = poolId;
        data.amountShare =
            '${Fmt.balance(json['data'][3]['value'], rewardToken.decimals!)} ${PluginFmt.tokenView(rewardToken.symbol)}';
        break;
      case actionPayoutRewards:
        final pair = (jsonDecode(json['data'][1]['value'])['dexIncentive']
                ['dexShare'] as List)
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e).symbol)
            .toList();
        final poolId = pair.join('-');
        final rewardToken = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['data'][2]['value']));
        data.poolId = poolId;
        data.amountShare =
            '${Fmt.balance(json['data'][3]['value'], rewardToken.decimals!)} ${PluginFmt.tokenView(rewardToken.symbol)}';
        break;
      case actionStake:
      case actionUnStake:
        final pair = (jsonDecode(json['data'][1]['value'])['dexShare'] as List)
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
            .toList();
        final poolId = pair.map((e) => e.symbol).join('-');
        final shareTokenView = PluginFmt.tokenView(poolId);
        data.poolId = poolId;
        data.amountShare =
            '${Fmt.balance(json['data'][2]['value'], pair[0].decimals!)} $shareTokenView';
        break;
    }
    data.time = (json['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['extrinsic']['isSuccess'];
    return data;
  }
}

abstract class _TxDexIncentiveData {
  String? block;
  String? hash;
  String? event;
  late String poolId;
  String? amountShare;
  late String time;
  bool? isSuccess = true;
}
