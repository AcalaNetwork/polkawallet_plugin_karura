import 'dart:convert';

import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxDexIncentiveData extends _TxDexIncentiveData {
  static const String actionStake = 'DepositDexShare';
  static const String actionUnStake = 'WithdrawDexShare';
  static const String actionClaimRewards = 'ClaimRewards';
  static const String actionPayoutRewards = 'PayoutRewards';
  static TxDexIncentiveData fromJson(Map<String, dynamic> json,
      String stableCoinSymbol, List<String> symbols, List<int> decimals) {
    final data = TxDexIncentiveData();
    data.hash = json['extrinsic']['id'];
    data.event = json['type'];

    switch (data.event) {
      case actionClaimRewards:
        final pair =
            (jsonDecode(json['data'][1]['value'])['dex']['dexShare'] as List)
                .map((e) => e['token'])
                .toList();
        final poolId = pair.join('-');
        final rewardToken = jsonDecode(json['data'][2]['value'])['token'];
        data.poolId = poolId;
        data.amountShare =
            '${Fmt.balance(json['data'][3]['value'], decimals[symbols.indexOf(rewardToken)])} ${PluginFmt.tokenView(rewardToken)}';
        break;
      case actionPayoutRewards:
        final pair = (jsonDecode(json['data'][1]['value'])['dexIncentive']
                ['dexShare'] as List)
            .map((e) => e['token'])
            .toList();
        final poolId = pair.join('-');
        final rewardToken = jsonDecode(json['data'][2]['value'])['token'];
        data.poolId = poolId;
        data.amountShare =
            '${Fmt.balance(json['data'][3]['value'], decimals[symbols.indexOf(rewardToken)])} ${PluginFmt.tokenView(rewardToken)}';
        break;
      case actionStake:
      case actionUnStake:
        final pair = (jsonDecode(json['data'][1]['value'])['dexShare'] as List)
            .map((e) => e['token'])
            .toList();
        final poolId = pair.join('-');
        final shareTokenView = PluginFmt.tokenView(poolId);
        data.poolId = poolId;
        data.amountShare =
            '${Fmt.balance(json['data'][2]['value'], decimals[symbols.indexOf(pair[0])])} $shareTokenView';
        break;
    }
    data.time = (json['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['extrinsic']['isSuccess'];
    return data;
  }
}

abstract class _TxDexIncentiveData {
  String block;
  String hash;
  String event;
  String poolId;
  String amountShare;
  String time;
  bool isSuccess = true;
}
