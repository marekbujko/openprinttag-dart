// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_print_tag_aux_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenPrintTagAuxData _$OpenPrintTagAuxDataFromJson(Map<String, dynamic> json) =>
    OpenPrintTagAuxData(
      consumedWeight: json['consumed_weight'] as num?,
      workgroup: json['workgroup'] as String?,
      generalPurposeRangeUser: json['general_purpose_range_user'] as String?,
      lastStirTime: (json['last_stir_time'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OpenPrintTagAuxDataToJson(
  OpenPrintTagAuxData instance,
) => <String, dynamic>{
  'consumed_weight': instance.consumedWeight,
  'workgroup': instance.workgroup,
  'general_purpose_range_user': instance.generalPurposeRangeUser,
  'last_stir_time': instance.lastStirTime,
};
