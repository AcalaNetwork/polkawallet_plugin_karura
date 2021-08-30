import 'package:json_annotation/json_annotation.dart';

part 'nftData.g.dart';

@JsonSerializable()
class NFTData extends _NFTData {
  static NFTData fromJson(Map json) => _$NFTDataFromJson(json);
}

abstract class _NFTData {
  Map attribute;
  Map metadata;
  String classId;
  String dwebMetadata;
  String metadataIpfsUrl;
  List<String> properties;
  String tokenId;
}
