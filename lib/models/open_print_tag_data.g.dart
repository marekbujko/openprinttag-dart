// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_print_tag_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenPrintTagData _$OpenPrintTagDataFromJson(Map<String, dynamic> json) =>
    OpenPrintTagData(
      main: json['main'] == null
          ? null
          : OpenPrintTagMainData.fromJson(json['main'] as Map<String, dynamic>),
      aux: json['aux'] == null
          ? null
          : OpenPrintTagAuxData.fromJson(json['aux'] as Map<String, dynamic>),
      meta: json['meta'] == null
          ? null
          : OpenPrintTagMetaData.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OpenPrintTagDataToJson(OpenPrintTagData instance) =>
    <String, dynamic>{
      'main': instance.main?.toJson(),
      'aux': instance.aux?.toJson(),
      'meta': instance.meta?.toJson(),
    };
