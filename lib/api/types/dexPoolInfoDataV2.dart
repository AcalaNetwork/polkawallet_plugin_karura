import 'package:polkawallet_ui/utils/format.dart';

class DexPoolInfoDataV2 extends _DexPoolInfoData {
  static DexPoolInfoDataV2 fromJson(Map json) {
    DexPoolInfoDataV2 data = DexPoolInfoDataV2();
    data.token = json['token'];
    // json['pool'] contains liquidity pool info
    data.amountLeft = Fmt.balanceInt(json['pool'][0].toString());
    data.amountRight = Fmt.balanceInt(json['pool'][1].toString());
    // json['shares']&json['proportion'] contains stake pool info
    data.sharesTotal = Fmt.balanceInt(json['sharesTotal'].toString());
    data.shares = Fmt.balanceInt(json['shares'].toString());
    data.proportion = double.parse(json['proportion'].toString());
    data.reward = LPRewardDataV2(
      List.of(json['reward']['incentive']),
      double.parse(json['reward']['saving']),
    );
    data.issuance = Fmt.balanceInt(json['issuance'].toString());
    return data;
  }
}

abstract class _DexPoolInfoData {
  String token;
  BigInt amountLeft;
  BigInt amountRight;
  BigInt sharesTotal;
  BigInt shares;
  LPRewardDataV2 reward;
  double proportion;
  BigInt issuance;
}

class LPRewardDataV2 {
  LPRewardDataV2(this.incentive, this.saving);
  List incentive;
  double saving;
}
