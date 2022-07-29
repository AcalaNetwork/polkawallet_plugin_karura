import 'package:polkawallet_plugin_karura/api/history/types/historyData.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxHomaData extends _TxHomaData {
  static const String actionMint = 'homa.Minted';
  static const String actionRedeemed = 'homa.Redeemed';
  static const String actionLiteRedeemed = 'homaLite.Redeemed';
  static const String actionRedeem = 'homa.RequestedRedeem';
  static const String actionLiteRedeem = 'homaLite.RedeemRequested';
  static const String actionRedeemCancel = 'homa.RedeemRequestCancelled';
  static const String actionRedeemedByFastMatch = 'homa.RedeemedByFastMatch';
  static const String actionWithdrawRedemption = 'homa.WithdrawRedemption';
  static const String actionRedeemedByUnbond = 'homa.RedeemedByUnbond';

  static const String actionMintFilter = 'Mint';
  static const String actionRequestedRedeemFilter = 'RequestedRedeem';
  static const String actionUnbondFilter = 'Unbond';
  static const String actionFastRedeemFilter = 'Fast Redeem';

  static TxHomaData fromHistory(HistoryData history) {
    TxHomaData data = TxHomaData();
    data.action = history.event;
    data.resolveLinks = history.resolveLinks;
    data.hash = history.hash;
    data.isSuccess = true;

    switch (data.action) {
      case actionMint:
        final staked = history.data!['amountStaked'] == '0'
            ? history.data!['stakingCurrencyAmount']
            : history.data!['amountStaked'];
        final minted = history.data!['amountMinted'] == '0'
            ? history.data!['liquidAmountReceived']
            : history.data!['amountMinted'];

        data.amountPay = Fmt.balanceInt(staked);
        data.amountReceive = Fmt.balanceInt(minted);
        break;
      case actionRedeem:
      case actionLiteRedeem:
        data.amountPay = Fmt.balanceInt(history.data!['amount']);
        break;
      case actionLiteRedeemed:
        data.amountReceive =
            Fmt.balanceInt(history.data!['stakingAmountRedeemed']);
        break;
      case actionRedeemed:
      case actionRedeemCancel:
      case actionWithdrawRedemption:
        data.amountReceive = Fmt.balanceInt(history.data!['amount']);
        break;
      case actionRedeemedByFastMatch:
        data.amountPay = Fmt.balanceInt(history.data!['matchedLiquidAmount']);
        data.amountReceive =
            Fmt.balanceInt(history.data!['redeemedStakingAmount']);
        break;
      case actionRedeemedByUnbond:
        data.amountReceive =
            Fmt.balanceInt(history.data!['unbondingStakingAmount']);
    }

    data.time = (history.data!['timestamp'] as String).replaceAll(' ', '');
    return data;
  }
}

abstract class _TxHomaData {
  String? block;
  String? hash;
  String? resolveLinks;
  String? action;
  BigInt? amountPay;
  BigInt? amountReceive;

  late String time;
  bool? isSuccess = true;
}
