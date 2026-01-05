import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:open_print_tag/models/open_print_tag_aux_data.dart';
import 'package:open_print_tag/models/open_print_tag_data.dart';
import 'package:open_print_tag/models/open_print_tag_main_data.dart';
import 'package:open_print_tag/models/open_print_tag_meta_data.dart';
import 'package:open_print_tag/models/open_print_tag_payload.dart';
import 'package:open_print_tag/models/unknown_fields.dart';
import 'package:open_print_tag/src/cbor/cbor_hex_utils.dart';
import 'package:open_print_tag/src/cbor/cbor_utils.dart';
import 'package:open_print_tag/src/cbor/fields/fields_manager.dart';
import 'package:open_print_tag/src/cbor/fields/ndef_region.dart';

class OpenPrintTagDecoder {
  final FieldsManager metaFields;
  final FieldsManager mainFields;
  final FieldsManager auxFields;

  OpenPrintTagDecoder({
    required this.metaFields,
    required this.mainFields,
    required this.auxFields,
  });

  Future<OpenPrintTagPayload> decodePayload(Uint8List payload) async {
    final CborMap? metaCborMap = await CborUtils.getFirstCborMap(payload);

    if (metaCborMap == null) {
      throw const FormatException('Could not decode CBOR map from payload');
    }
    final int metaSize = cbor.encode(metaCborMap).length;

    final DecodeResult metaResult = await _readRegion(
      payload,
      offset: 0,
      size: metaSize,
      fields: metaFields,
    );

    final DecodeResult mainResult = await _readMainRegion(
      payload,
      metaResult.data,
      metaSize,
    );

    final DecodeResult? auxResult = await _readAuxRegion(
      payload,
      metaResult.data,
    );

    final OpenPrintTagData data = OpenPrintTagData(
      meta: OpenPrintTagMetaData.fromJson(metaResult.data),
      main: OpenPrintTagMainData.fromJson(mainResult.data),
      aux: auxResult != null
          ? OpenPrintTagAuxData.fromJson(auxResult.data)
          : null,
    );

    final UnknownFieldsRegion? metaUnknown = _toHexMap(
      metaResult.unknownFields,
    );
    final UnknownFieldsRegion? mainUnknown = _toHexMap(
      mainResult.unknownFields,
    );
    final UnknownFieldsRegion? auxUnknown = _toHexMap(auxResult?.unknownFields);

    final UnknownFields? unknownFields =
        metaUnknown == null && mainUnknown == null && auxUnknown == null
        ? null
        : UnknownFields(meta: metaUnknown, main: mainUnknown, aux: auxUnknown);

    return OpenPrintTagPayload(data: data, unknownFields: unknownFields);
  }

  UnknownFieldsRegion? _toHexMap(Map<int, CborValue>? cborMap) {
    if (cborMap == null || cborMap.isEmpty) {
      return null;
    }

    return <String, String>{
      for (final MapEntry<int, CborValue> e in cborMap.entries)
        CborHexUtils.intToHex(e.key): CborHexUtils.cborValueToHex(e.value),
    };
  }

  Future<DecodeResult> _readMainRegion(
    Uint8List payload,
    Map<String, dynamic> metaData,
    int metaSize,
  ) async {
    final int mainOffset = metaData['main_region_offset'] as int? ?? metaSize;
    final int? mainSize = metaData['main_region_size'] as int?;
    final int? auxOffset = metaData['aux_region_offset'] as int?;

    final int actualMainSize =
        mainSize ?? (auxOffset ?? payload.length) - mainOffset;

    return await _readRegion(
      payload,
      offset: mainOffset,
      size: actualMainSize,
      fields: mainFields,
    );
  }

  Future<DecodeResult?> _readAuxRegion(
    Uint8List payload,
    Map<String, dynamic> metaData,
  ) async {
    final int? auxOffset = metaData['aux_region_offset'] as int?;
    if (auxOffset == null) {
      return null;
    }

    final int? auxSize = metaData['aux_region_size'] as int?;
    final int actualAuxSize = auxSize ?? payload.length - auxOffset;

    return await _readRegion(
      payload,
      offset: auxOffset,
      size: actualAuxSize,
      fields: auxFields,
    );
  }

  Future<DecodeResult> _readRegion(
    Uint8List payload, {
    required int offset,
    required int size,
    required FieldsManager fields,
  }) async {
    final NdefRegion region = NdefRegion(
      offset: offset,
      size: size,
      fields: fields,
    );
    return await region.read(payload);
  }
}
