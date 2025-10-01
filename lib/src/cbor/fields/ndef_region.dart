import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:open_print_tag/src/cbor/cbor_utils.dart';
import 'package:open_print_tag/src/cbor/fields/fields_manager.dart';

class NdefRegion {
  final int offset;
  final int size;
  final FieldsManager fields;

  NdefRegion({required this.offset, required this.size, required this.fields});

  Future<Map<String, dynamic>> read(Uint8List payloadData) async {
    if (offset + size > payloadData.length) {
      throw ArgumentError(
        'Region extends beyond payload: offset=$offset, size=$size, payload=${payloadData.length}',
      );
    }

    final Uint8List regionData = Uint8List.fromList(
      payloadData.sublist(offset, offset + size),
    );

    final CborMap? decoded = await CborUtils.decodeCborMap(regionData);

    if (decoded == null) {
      throw const FormatException('Could not decode CBOR map from region');
    }

    if (decoded.isEmpty) {
      return <String, dynamic>{};
    }

    // Work directly with CBOR types - no conversion needed!
    final Map<CborSmallInt, CborValue> cborData = decoded
        .cast<CborSmallInt, CborValue>();

    return fields.decode(cborData);
  }
}
