import 'package:json_annotation/json_annotation.dart';

part 'earnPageParams.g.dart';

@JsonSerializable()
class EarnPageParams extends _EarnPageParams {
  static EarnPageParams fromJson(Map json) =>
      _$EarnPageParamsFromJson(Map<String, dynamic>.from(json));
  Map toJson() => _$EarnPageParamsToJson(this);
}

abstract class _EarnPageParams {
  String? tab;
}

@JsonSerializable()
class EarnDetailPageParams extends _EarnDetailPageParams {
  static EarnDetailPageParams fromJson(Map json) =>
      _$EarnDetailPageParamsFromJson(Map<String, dynamic>.from(json));
  Map toJson() => _$EarnDetailPageParamsToJson(this);
}

abstract class _EarnDetailPageParams {
  String? poolId;
}
