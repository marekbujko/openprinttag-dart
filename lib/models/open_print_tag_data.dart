import 'package:json_annotation/json_annotation.dart';
import 'package:open_print_tag/models/open_print_tag_aux_data.dart';
import 'package:open_print_tag/models/open_print_tag_main_data.dart';
import 'package:open_print_tag/models/open_print_tag_meta_data.dart';

part 'open_print_tag_data.g.dart';

@JsonSerializable(explicitToJson: true)
class OpenPrintTagData {
  final OpenPrintTagMainData? main;
  final OpenPrintTagAuxData? aux;
  final OpenPrintTagMetaData? meta;

  const OpenPrintTagData({this.main, this.aux, this.meta});

  factory OpenPrintTagData.fromJson(Map<String, dynamic> json) =>
      _$OpenPrintTagDataFromJson(json);

  Map<String, dynamic> toJson() => _$OpenPrintTagDataToJson(this);
}
