import 'package:json_annotation/json_annotation.dart';

part 'transferPageParams.g.dart';

@JsonSerializable()
class TransferPageParams extends _TransferPageParams {
  static TransferPageParams fromJson(Map json) =>
      _$TransferPageParamsFromJson(json as Map<String, dynamic>);
  Map toJson() => _$TransferPageParamsToJson(this);
}

abstract class _TransferPageParams {
  String? tokenNameId;
  String? address;
  String? isXCM = 'false'; // 'true' or 'false'
  String? chainFrom;
  String? chainTo;
}
