import 'package:cbor/cbor.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'open_print_tag_aux_data.g.dart';

@CopyWith()
@JsonSerializable(explicitToJson: true)
class OpenPrintTagAuxData {
  @JsonKey(name: 'consumed_weight')
  final num? consumedWeight;

  final String? workgroup;

  @JsonKey(name: 'general_purpose_range_user')
  final String? generalPurposeRangeUser;

  @JsonKey(name: 'last_stir_time')
  final int? lastStirTime;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final Map<int, CborValue>? unknownFields;

  const OpenPrintTagAuxData({
    this.consumedWeight,
    this.workgroup,
    this.generalPurposeRangeUser,
    this.lastStirTime,
    this.unknownFields,
  });

  factory OpenPrintTagAuxData.fromJson(Map<String, dynamic> json) {
    final OpenPrintTagAuxData data = _$OpenPrintTagAuxDataFromJson(json);

    return data.copyWith(
      unknownFields: json['unknown_fields'] as Map<int, CborValue>?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = _$OpenPrintTagAuxDataToJson(this);

    if (unknownFields != null && unknownFields!.isNotEmpty) {
      json['unknown_fields'] = unknownFields;
    }

    return json;
  }
}
