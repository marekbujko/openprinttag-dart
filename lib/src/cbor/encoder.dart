import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:open_print_tag/models/open_print_tag_aux_data.dart';
import 'package:open_print_tag/models/open_print_tag_payload.dart';
import 'package:open_print_tag/models/unknown_fields.dart';
import 'package:open_print_tag/src/cbor/cbor_hex_utils.dart';
import 'package:open_print_tag/src/cbor/cbor_utils.dart';
import 'package:open_print_tag/src/cbor/fields/fields_manager.dart';

class OpenPrintTagEncoder {
  final FieldsManager metaFields;
  final FieldsManager mainFields;
  final FieldsManager auxFields;

  OpenPrintTagEncoder({
    required this.metaFields,
    required this.mainFields,
    required this.auxFields,
  });

  Uint8List encodePayload(OpenPrintTagPayload payload, {required int size}) {
    if (payload.data.main == null) {
      throw ArgumentError('Main data must be provided');
    }

    const int auxSize = 32;
    final int auxOffset = size - auxSize;

    final Uint8List metaBytes = _encodeSection(
      <String, dynamic>{'aux_region_offset': auxOffset},
      metaFields,
      unknownFields: payload.unknownFields?.meta,
    );

    final Uint8List mainBytes = _encodeSection(
      payload.data.main!.toJson(),
      mainFields,
      unknownFields: payload.unknownFields?.main,
    );

    final Uint8List auxBytes = _encodeSection(
      payload.data.aux?.toJson() ?? <String, dynamic>{},
      auxFields,
      unknownFields: payload.unknownFields?.aux,
    );

    final int mainOffset = metaBytes.length;
    final int availableMainSpace = auxOffset - mainOffset;

    if (mainBytes.length > availableMainSpace) {
      throw ArgumentError(
        'MAIN section (${mainBytes.length} bytes) exceeds available space ($availableMainSpace bytes)',
      );
    }

    if (auxBytes.length > auxSize) {
      throw ArgumentError(
        'AUX section (${auxBytes.length} bytes) exceeds allocated size ($auxSize bytes)',
      );
    }

    return _buildPayload(
      metaBytes,
      mainBytes,
      auxBytes,
      auxOffset,
      auxSize,
      size,
    );
  }

  Uint8List encodeAuxSection(OpenPrintTagAuxData auxData) {
    return _encodeSection(auxData.toJson(), auxFields);
  }

  Uint8List _encodeSection(
    Map<String, dynamic> data,
    FieldsManager fields, {
    UnknownFieldsRegion? unknownFields,
  }) {
    CborUtils.removeNullValues(data);

    final Map<int, CborValue> encoded = fields.encode(
      data,
      unknownFields: unknownFields != null
          ? CborHexUtils.hexMapToCborMap(unknownFields)
          : null,
    );

    final CborMap cborMap = CborMap(<CborSmallInt, CborValue>{
      for (final MapEntry<int, CborValue> e in encoded.entries)
        CborSmallInt(e.key): e.value,
    });

    final Uint8List bytes = Uint8List.fromList(cbor.encode(cborMap));

    if (bytes.length > 512) {
      throw ArgumentError(
        'Section size ${bytes.length} exceeds 512 byte limit',
      );
    }
    return bytes;
  }

  Uint8List _buildPayload(
    Uint8List metaBytes,
    Uint8List mainBytes,
    Uint8List auxBytes,
    int auxOffset,
    int auxSize,
    int totalSize,
  ) {
    final BytesBuilder builder = BytesBuilder();

    builder.add(metaBytes);
    builder.add(mainBytes);
    _addPadding(builder, auxOffset);
    builder.add(auxBytes);
    _addPadding(builder, totalSize);

    return builder.toBytes();
  }

  void _addPadding(BytesBuilder builder, int targetLength) {
    if (builder.length < targetLength) {
      builder.add(Uint8List(targetLength - builder.length));
    }
  }
}
