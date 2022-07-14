import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

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
  static TxDexIncentiveData fromHistory(
      HistoryData history, PluginKarura plugin) {
    final data = TxDexIncentiveData();
    data.hash = history.hash;
    data.event = history.event;

    final token = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': history.data!['tokenId']});
    final shareTokenView = PluginFmt.tokenView(token.symbol);
    data.poolId = token.symbol ?? "";

    switch (data.event) {
      case TxDexIncentiveData.actionClaimRewards:
        data.amountShare =
            '${Fmt.balance(history.data!['actualAmount'], token.decimals!)} $shareTokenView';
        break;
      case TxDexIncentiveData.actionPayoutRewards:
        data.amountShare =
            '${Fmt.balance(history.data!['actualPayout'], token.decimals!)} $shareTokenView';
        break;
      default:
        data.amountShare =
            '${Fmt.balance(history.data!['amount'], token.decimals!)} $shareTokenView';
    }

    data.time = (history.data!['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = true;
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
