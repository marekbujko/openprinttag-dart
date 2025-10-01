import 'dart:typed_data';

import 'package:open_print_tag/open_print_tag.dart';
import 'package:open_print_tag/src/data/aux_fields.data.g.dart' as aux_data;
import 'package:open_print_tag/src/data/main_fields.data.g.dart' as main_data;
import 'package:open_print_tag/src/data/material_class_enum.data.g.dart'
    as material_class_data;
import 'package:open_print_tag/src/data/material_type_enum.data.g.dart'
    as material_type_data;
import 'package:open_print_tag/src/data/meta_fields.data.g.dart' as meta_data;
import 'package:open_print_tag/src/data/tags_enum.data.g.dart' as tags_data;
import 'package:open_print_tag/src/data/write_protection_enum.data.g.dart'
    as write_protection_data;

class OpenPrintTagParser {
  final OpenPrintTagDecoder _decoder;
  final OpenPrintTagEncoder _encoder;

  OpenPrintTagParser._({
    required OpenPrintTagDecoder decoder,
    required OpenPrintTagEncoder encoder,
  }) : _decoder = decoder,
       _encoder = encoder;

  /// Creates a parser using generated data constants
  static OpenPrintTagParser create() {
    // Prepare enum data map
    final Map<String, List<Map<String, Object?>>> enumsData =
        <String, List<Map<String, Object?>>>{
          'material_class_enum.yaml': material_class_data.materialClassEnum,
          'material_type_enum.yaml': material_type_data.materialTypeEnum,
          'tags_enum.yaml': tags_data.tagsEnum,
          'write_protection_enum.yaml':
              write_protection_data.writeProtectionEnum,
        };

    final FieldsManager metaFields = FieldsManager.fromData(
      meta_data.metaFields,
      enumsData: enumsData,
    );
    final FieldsManager mainFields = FieldsManager.fromData(
      main_data.mainFields,
      enumsData: enumsData,
    );
    final FieldsManager auxFields = FieldsManager.fromData(
      aux_data.auxFields,
      enumsData: enumsData,
    );

    return OpenPrintTagParser.withFieldManagers(
      metaFields: metaFields,
      mainFields: mainFields,
      auxFields: auxFields,
    );
  }

  factory OpenPrintTagParser.withFieldManagers({
    required FieldsManager metaFields,
    required FieldsManager mainFields,
    required FieldsManager auxFields,
  }) {
    return OpenPrintTagParser._(
      decoder: OpenPrintTagDecoder(
        metaFields: metaFields,
        mainFields: mainFields,
        auxFields: auxFields,
      ),
      encoder: OpenPrintTagEncoder(
        metaFields: metaFields,
        mainFields: mainFields,
        auxFields: auxFields,
      ),
    );
  }

  Future<OpenPrintTagData> decode(Uint8List payload) async {
    return await _decoder.decodePayload(payload);
  }

  Uint8List encode(OpenPrintTagData data) {
    return _encoder.encodePayload(data);
  }
}
