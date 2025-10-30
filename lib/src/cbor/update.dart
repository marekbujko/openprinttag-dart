import 'dart:typed_data';

import 'package:open_print_tag/models/open_print_tag_aux_data.dart';
import 'package:open_print_tag/models/open_print_tag_data.dart';
import 'package:open_print_tag/src/cbor/decoder.dart';
import 'package:open_print_tag/src/cbor/encoder.dart';

class OpenPrintTagUpdate {
  final OpenPrintTagDecoder decoder;
  final OpenPrintTagEncoder encoder;

  OpenPrintTagUpdate({required this.decoder, required this.encoder});

  Future<Uint8List> updateAuxPayload(
    Uint8List payload,
    OpenPrintTagAuxData auxData,
  ) async {
    final OpenPrintTagData decoded = await decoder.decodePayload(payload);

    final int? auxOffset = decoded.meta?.auxRegionOffset;

    if (auxOffset == null) {
      throw ArgumentError(
        'Invalid payload: missing aux_region_offset in META section',
      );
    }

    return encoder.updateAux(payload, auxData, auxOffset);
  }
}
