import 'package:json_annotation/json_annotation.dart';
import 'package:polkawallet_ui/utils/format.dart';

part 'dexPoolInfoData.g.dart';

class DexPoolInfoData extends _DexPoolInfoData {
  static DexPoolInfoData fromJson(Map json) {
    DexPoolInfoData data = DexPoolInfoData();
    data.tokenNameId = json['tokenNameId'];
    // json['pool'] contains liquidity pool info
    data.amountLeft = Fmt.balanceInt(json['pool'][0].toString());
    data.amountRight = Fmt.balanceInt(json['pool'][1].toString());
    // json['shares']&json['proportion'] contains stake pool info
    data.sharesTotal = Fmt.balanceInt(json['sharesTotal'].toString());
    data.shares = Fmt.balanceInt(json['shares'].toString());
    data.proportion = double.parse(json['proportion'].toString());
    data.reward = LPRewardData(
      List.of(json['reward']['incentive']),
      double.parse(json['reward']['saving']),
    );
    data.issuance = Fmt.balanceInt(json['issuance'].toString());
    return data;
  }
}

abstract class _DexPoolInfoData {
  String? tokenNameId;
  BigInt? amountLeft;
  BigInt? amountRight;
  BigInt? sharesTotal;
  BigInt? shares;
  LPRewardData? reward;
  double? proportion;
  BigInt? issuance;
}

class LPRewardData {
  LPRewardData(this.incentive, this.saving);
  List incentive;
  double saving;
}

@JsonSerializable()
class DexPoolData extends _DexPoolData {
  static DexPoolData fromJson(Map<String, dynamic> json) =>
      _$DexPoolDataFromJson(json);
  Map<String, dynamic> toJson() => _$DexPoolDataToJson(this);
}

abstract class _DexPoolData {
  String? tokenNameId;
  List? tokens;
  ProvisioningData? provisioning;
  double? rewards;
  double? rewardsLoyalty;
}

@JsonSerializable()
class ProvisioningData extends _ProvisioningData {
  static ProvisioningData fromJson(Map json) =>
      _$ProvisioningDataFromJson(json as Map<String, dynamic>);
  Map toJson() => _$ProvisioningDataToJson(this);
}

abstract class _ProvisioningData {
  List? minContribution;
  List? targetProvision;
  List? accumulatedProvision;
  int? notBefore;
}
