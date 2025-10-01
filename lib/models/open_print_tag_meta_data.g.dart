// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_print_tag_meta_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenPrintTagMetaData _$OpenPrintTagMetaDataFromJson(
  Map<String, dynamic> json,
) => OpenPrintTagMetaData(
  mainRegionOffset: (json['main_region_offset'] as num?)?.toInt(),
  mainRegionSize: (json['main_region_size'] as num?)?.toInt(),
  auxRegionOffset: (json['aux_region_offset'] as num?)?.toInt(),
  auxRegionSize: (json['aux_region_size'] as num?)?.toInt(),
);

Map<String, dynamic> _$OpenPrintTagMetaDataToJson(
  OpenPrintTagMetaData instance,
) => <String, dynamic>{
  'main_region_offset': instance.mainRegionOffset,
  'main_region_size': instance.mainRegionSize,
  'aux_region_offset': instance.auxRegionOffset,
  'aux_region_size': instance.auxRegionSize,
};
