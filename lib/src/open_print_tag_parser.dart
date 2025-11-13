import 'dart:typed_data';

import 'package:open_print_tag/open_print_tag.dart';
import 'package:open_print_tag/src/data/aux_fields.data.g.dart' as aux_data;
import 'package:open_print_tag/src/data/main_fields.data.g.dart' as main_data;
import 'package:open_print_tag/src/data/meta_fields.data.g.dart' as meta_data;

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
    final FieldsManager metaFields = FieldsManager.fromData(
      meta_data.metaFields,
    );
    final FieldsManager mainFields = FieldsManager.fromData(
      main_data.mainFields,
    );
    final FieldsManager auxFields = FieldsManager.fromData(aux_data.auxFields);

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
    final OpenPrintTagDecoder decoder = OpenPrintTagDecoder(
      metaFields: metaFields,
      mainFields: mainFields,
      auxFields: auxFields,
    );
    final OpenPrintTagEncoder encoder = OpenPrintTagEncoder(
      metaFields: metaFields,
      mainFields: mainFields,
      auxFields: auxFields,
    );

    return OpenPrintTagParser._(decoder: decoder, encoder: encoder);
  }

  Future<OpenPrintTagData> decode(Uint8List payload) async {
    return await _decoder.decodePayload(payload);
  }

  Uint8List encode(OpenPrintTagData data, {required int size}) {
    return _encoder.encodePayload(data, size: size);
  }

  Uint8List encodeAuxSection(OpenPrintTagAuxData auxData) {
    return _encoder.encodeAuxSection(auxData);
  }
}
