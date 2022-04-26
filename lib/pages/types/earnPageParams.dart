import 'package:json_annotation/json_annotation.dart';

part 'earnPageParams.g.dart';

@JsonSerializable()
class EarnPageParams extends _EarnPageParams {
  static EarnPageParams fromJson(Map json) =>
      _$EarnPageParamsFromJson(json as Map<String, dynamic>);
  Map toJson() => _$EarnPageParamsToJson(this);
}

abstract class _EarnPageParams {
  String? tab;
}

@JsonSerializable()
class EarnDetailPageParams extends _EarnDetailPageParams {
  static EarnDetailPageParams fromJson(Map json) =>
      _$EarnDetailPageParamsFromJson(json as Map<String, dynamic>);
  Map toJson() => _$EarnDetailPageParamsToJson(this);
}

abstract class _EarnDetailPageParams {
  String? poolId;
}
