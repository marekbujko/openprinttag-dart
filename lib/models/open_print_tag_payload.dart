import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:open_print_tag/models/open_print_tag_data.dart';
import 'package:open_print_tag/models/unknown_fields.dart';

part 'open_print_tag_payload.g.dart';

@CopyWith()
@JsonSerializable(explicitToJson: true)
class OpenPrintTagPayload {
  @JsonKey(name: 'data')
  final OpenPrintTagData data;

  @JsonKey(name: 'unknown_fields')
  final UnknownFields? unknownFields;

  const OpenPrintTagPayload({required this.data, this.unknownFields});

  factory OpenPrintTagPayload.fromJson(Map<String, dynamic> json) =>
      _$OpenPrintTagPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$OpenPrintTagPayloadToJson(this);
}
