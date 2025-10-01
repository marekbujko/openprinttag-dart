import 'package:json_annotation/json_annotation.dart';

part 'open_print_tag_meta_data.g.dart';

/// Metadata describing the structure and layout of NDEF regions
@JsonSerializable(explicitToJson: true)
class OpenPrintTagMetaData {
  @JsonKey(name: 'main_region_offset')
  final int? mainRegionOffset;

  @JsonKey(name: 'main_region_size')
  final int? mainRegionSize;

  @JsonKey(name: 'aux_region_offset')
  final int? auxRegionOffset;

  @JsonKey(name: 'aux_region_size')
  final int? auxRegionSize;

  const OpenPrintTagMetaData({
    this.mainRegionOffset,
    this.mainRegionSize,
    this.auxRegionOffset,
    this.auxRegionSize,
  });

  factory OpenPrintTagMetaData.fromJson(Map<String, dynamic> json) =>
      _$OpenPrintTagMetaDataFromJson(json);

  Map<String, dynamic> toJson() => _$OpenPrintTagMetaDataToJson(this);
}
