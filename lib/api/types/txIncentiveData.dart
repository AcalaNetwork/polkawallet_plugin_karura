import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

const earn_actions_map = {
  'incentives.AddLiquidity': 'earn.AddLiquidity',
  'incentives.RemoveLiquidity': 'earn.RemoveLiquidity',
  'incentives.DepositDexShare': 'earn.DepositDexShare',
  'incentives.WithdrawDexShare': 'earn.WithdrawDexShare',
  'incentives.ClaimRewards': 'earn.ClaimRewards',
};

class TxDexIncentiveData extends _TxDexIncentiveData {
  static const String actionStake = 'incentives.DepositDexShare';
  static const String actionUnStake = 'incentives.WithdrawDexShare';
  static const String actionClaimRewards = 'incentives.ClaimRewards';
  static const String actionPayoutRewards = 'incentives.PayoutRewards';

  static const String actionEarnUnbond = 'earning.Unbonded';
  static const String actionEarnBond = 'earning.Bonded';
  static const String actionEarnRebond = 'earning.Rebonded';

  static const String actionBondFilter = 'Stake KAR';
  static const String actionUnbondFilter = 'Unstake KAR';
  static const String actionStakeFilter = 'Stake LP';
  static const String actionUnStakeFilter = 'Unstake LP';
  static const String actionClaimRewardsFilter = 'Claim Rewards';
  static const String actionPayoutRewardsFilter = 'Payout Rewards';

  static const replacePattern = r'\{"earning":\{.*?\}\} earn';

  static TxDexIncentiveData fromHistory(
      HistoryData history, PluginKarura plugin) {
    final data = TxDexIncentiveData();
    data.hash = history.hash;
    data.resolveLinks = history.resolveLinks;
    data.event = history.event;
    data.message = history.message;
    if (history.event == actionClaimRewards &&
        history.message?.contains(RegExp(replacePattern)) == true) {
      data.message =
          history.message?.replaceAll(RegExp(replacePattern), 'KAR staking');
    }

    data.time = (history.data!['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = true;
    return data;
  }
}

String replacePattern(String input, String replacement) {
  RegExp regex = RegExp(r'\{"earning":\{.*?\}\}');
  return input.replaceAll(regex, replacement);
}

abstract class _TxDexIncentiveData {
  String? hash;
  String? resolveLinks;
  String? event;
  String? message;
  late String time;
  bool? isSuccess = true;
}
