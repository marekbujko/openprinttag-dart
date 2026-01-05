import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'unknown_fields.g.dart';

typedef UnknownFieldsRegion = Map<String, String>;

@CopyWith()
@JsonSerializable(explicitToJson: true)
class UnknownFields {
  @JsonKey(name: 'meta')
  final UnknownFieldsRegion? meta;
  @JsonKey(name: 'main')
  final UnknownFieldsRegion? main;
  @JsonKey(name: 'aux')
  final UnknownFieldsRegion? aux;

  const UnknownFields({this.meta, this.main, this.aux});

  factory UnknownFields.fromJson(Map<String, dynamic>? json) {
    return _$UnknownFieldsFromJson(json ?? <String, dynamic>{});
  }

  Map<String, dynamic> toJson() => _$UnknownFieldsToJson(this);
}
