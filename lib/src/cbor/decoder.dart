import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:open_print_tag/models/open_print_tag_aux_data.dart';
import 'package:open_print_tag/models/open_print_tag_data.dart';
import 'package:open_print_tag/models/open_print_tag_main_data.dart';
import 'package:open_print_tag/models/open_print_tag_meta_data.dart';
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

  Future<OpenPrintTagData> decodePayload(Uint8List payload) async {
    final CborMap? decoded = await CborUtils.decodeCborMap(payload);

    if (decoded == null) {
      throw const FormatException('Could not decode CBOR map from payload');
    }

    final CborMap cborMap = decoded;

    // Convert CborMap keys to native int values
    final Map<int, dynamic> firstMap = <int, dynamic>{};
    for (final MapEntry<CborValue, CborValue> entry in cborMap.entries) {
      final int key = (entry.key as CborSmallInt).value;
      firstMap[key] = entry.value;
    }

    final bool hasMeta = firstMap.keys.any((int k) => k >= 0 && k <= 3);
    if (!hasMeta) {
      throw const FormatException('Invalid payload: meta section missing');
    }

    final List<int> metaBytes = cbor.encode(cborMap);
    final int metaSize = metaBytes.length;

    final NdefRegion metaRegion = NdefRegion(
      offset: 0,
      size: metaSize,
      fields: metaFields,
    );
    final Map<String, dynamic> metaData = await metaRegion.read(payload);

    final int mainOffset = metaData['main_region_offset'] as int? ?? metaSize;
    final int? mainSize = metaData['main_region_size'] as int?;
    final int? auxOffset = metaData['aux_region_offset'] as int?;
    final int? auxSize = metaData['aux_region_size'] as int?;
    final List<int> regionStops = <int>[
      mainOffset,
      if (auxOffset != null) auxOffset,
      payload.length,
    ]..sort();

    final int actualMainSize =
        mainSize ?? _calculateRegionSize(mainOffset, regionStops);
    final int? actualAuxSize = auxOffset != null
        ? (auxSize ?? _calculateRegionSize(auxOffset, regionStops))
        : null;

    final NdefRegion mainRegion = NdefRegion(
      offset: mainOffset,
      size: actualMainSize,
      fields: mainFields,
    );

    final NdefRegion? auxRegion = auxOffset != null && actualAuxSize != null
        ? NdefRegion(offset: auxOffset, size: actualAuxSize, fields: auxFields)
        : null;

    final Map<String, dynamic> mainData = await mainRegion.read(payload);
    final Map<String, dynamic>? auxData = auxRegion != null
        ? await auxRegion.read(payload)
        : null;

    return OpenPrintTagData(
      main: mainData.isNotEmpty
          ? OpenPrintTagMainData.fromJson(mainData)
          : null,
      aux: auxData != null && auxData.isNotEmpty
          ? OpenPrintTagAuxData.fromJson(auxData)
          : null,
      meta: metaData.isNotEmpty
          ? OpenPrintTagMetaData.fromJson(metaData)
          : null,
    );
  }

  int _calculateRegionSize(int offset, List<int> stops) {
    for (final int stop in stops) {
      if (stop > offset) {
        return stop - offset;
      }
    }
    return 0;
  }
}
