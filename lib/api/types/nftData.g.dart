// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nftData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NFTData _$NFTDataFromJson(Map<String, dynamic> json) {
  return NFTData()
    ..attribute = json['attribute'] as Map<String, dynamic>?
    ..metadata = json['metadata'] as Map<String, dynamic>?
    ..classId = json['classId'] as String?
    ..dwebMetadata = json['dwebMetadata'] as String?
    ..metadataIpfsUrl = json['metadataIpfsUrl'] as String?
    ..properties =
        (json['properties'] as List<dynamic>).map((e) => e as String).toList()
    ..tokenId = json['tokenId'] as String?
    ..deposit = json['deposit'] as String?;
}

Map<String, dynamic> _$NFTDataToJson(NFTData instance) => <String, dynamic>{
      'attribute': instance.attribute,
      'metadata': instance.metadata,
      'classId': instance.classId,
      'dwebMetadata': instance.dwebMetadata,
      'metadataIpfsUrl': instance.metadataIpfsUrl,
      'properties': instance.properties,
      'tokenId': instance.tokenId,
      'deposit': instance.deposit,
    };
