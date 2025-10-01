import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:open_print_tag/models/open_print_tag_data.dart';
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

  Uint8List encodePayload(OpenPrintTagData data) {
    if (data.main == null) {
      throw ArgumentError('Main data must be provided');
    }
    final Map<String, dynamic> mainJson = data.main!.toJson();
    CborUtils.removeNullValues(mainJson);
    final Map<int, CborValue> mainEncoded = mainFields.encode(mainJson);
    final Uint8List mainBytes = Uint8List.fromList(
      cbor.encode(CborMap(_toCborMap(mainEncoded))),
    );

    Uint8List? auxBytes;
    if (data.aux != null) {
      final Map<String, dynamic> auxJson = data.aux!.toJson();
      CborUtils.removeNullValues(auxJson);
      final Map<int, CborValue> auxEncoded = auxFields.encode(auxJson);
      auxBytes = Uint8List.fromList(
        cbor.encode(CborMap(_toCborMap(auxEncoded))),
      );
    }

    final Map<String, dynamic> metaJson =
        data.meta?.toJson() ?? <String, dynamic>{};
    CborUtils.removeNullValues(metaJson);
    final bool userProvidedMainOffset = metaJson.containsKey(
      'main_region_offset',
    );
    final bool userProvidedAuxOffset = metaJson.containsKey(
      'aux_region_offset',
    );

    Uint8List? metaBytesFinal;
    int iteration = 0;
    int metaSize = 0;

    while (iteration < 10) {
      final int mainOffset = userProvidedMainOffset
          ? metaJson['main_region_offset'] as int
          : (metaSize == 0 ? 4 : metaSize);

      final int? auxOffset = auxBytes != null
          ? (userProvidedAuxOffset
                ? metaJson['aux_region_offset'] as int
                : mainOffset + mainBytes.length)
          : null;

      if (!userProvidedMainOffset) {
        metaJson['main_region_offset'] = mainOffset;
      }

      metaJson.remove('main_region_size');
      metaJson.remove('aux_region_size');

      if (auxOffset != null && !userProvidedAuxOffset) {
        metaJson['aux_region_offset'] = auxOffset;
      }

      final Map<int, CborValue> metaEncoded = metaFields.encode(metaJson);
      final Uint8List metaBytes = Uint8List.fromList(
        cbor.encode(CborMap(_toCborMap(metaEncoded))),
      );

      if (metaBytes.length == metaSize) {
        metaBytesFinal = metaBytes;
        break;
      }

      metaSize = metaBytes.length;
      iteration++;
    }

    if (metaBytesFinal == null) {
      throw StateError(
        'Could not stabilize meta region size after 10 iterations',
      );
    }

    final BytesBuilder builder = BytesBuilder();
    builder.add(metaBytesFinal);
    builder.add(mainBytes);
    if (auxBytes != null) {
      builder.add(auxBytes);
    }

    return builder.toBytes();
  }

  // Helper to convert Map<int, CborValue> to Map<CborValue, CborValue>
  static Map<CborValue, CborValue> _toCborMap(Map<int, CborValue> map) {
    return map.map(
      (int k, CborValue v) =>
          MapEntry<CborValue, CborValue>(CborSmallInt(k), v),
    );
  }
}
