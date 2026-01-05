import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ndef/ndef.dart' as ndef;
import 'package:open_print_tag/open_print_tag.dart';
import 'package:test/test.dart';

void main() {
  late OpenPrintTagParser parser;

  setUpAll(() {
    parser = OpenPrintTagParser.create();
  });

  group('NDEF Binary Tag Tests', () {
    test('loads and parses 01_data.bin', () async {
      await _testBinaryFile('test/fixtures/01_data.bin', parser);
    });

    test('loads and parses 02_data.bin', () async {
      await _testBinaryFile('test/fixtures/02_data.bin', parser);
    });

    test('loads and parses 03_data.bin', () async {
      await _testBinaryFile('test/fixtures/03_data.bin', parser);
    });

    test('loads and parses 04_data.bin', () async {
      await _testBinaryFile('test/fixtures/04_data.bin', parser);
    });

    test('loads and parses unknown_data_1.bin', () async {
      await _testBinaryFile('test/fixtures/unknown_data_1.bin', parser);
    });

    test('loads and parses unknown_data_2.bin', () async {
      await _testBinaryFile('test/fixtures/unknown_data_2.bin', parser);
    });
  });

  group('Round-trip encode/decode with modifications', () {
    test(
      '01_data.bin: modify value and verify unknown fields preserved',
      () async {
        await _testRoundTripWithModification(
          'test/fixtures/01_data.bin',
          parser,
        );
      },
    );

    test(
      '02_data.bin: modify value and verify unknown fields preserved',
      () async {
        await _testRoundTripWithModification(
          'test/fixtures/02_data.bin',
          parser,
        );
      },
    );

    test(
      'unknown_data_1.bin: modify value and verify unknown fields preserved',
      () async {
        await _testRoundTripWithModification(
          'test/fixtures/unknown_data_1.bin',
          parser,
        );
      },
    );

    test(
      'unknown_data_2.bin: modify value and verify unknown fields preserved',
      () async {
        await _testRoundTripWithModification(
          'test/fixtures/unknown_data_2.bin',
          parser,
        );
      },
    );
  });
}

Future<void> _testBinaryFile(String filePath, OpenPrintTagParser parser) async {
  final File file = File(filePath);
  final Uint8List bytes = await file.readAsBytes();

  print('Loaded ${bytes.length} bytes from ${filePath.split('/').last}');

  final Uint8List? ndefBytes = _extractNdefTlv(bytes);
  expect(ndefBytes, isNotNull, reason: 'Should find NDEF TLV in binary data');

  final List<ndef.NDEFRecord> records = ndef.decodeRawNdefMessage(ndefBytes!);
  print('Found ${records.length} NDEF records');

  final Uint8List? openPrintTagPayload = _findOpenPrintTagPayload(records);
  expect(
    openPrintTagPayload,
    isNotNull,
    reason: 'Should find OpenPrintTag MIME record',
  );

  print('Found OpenPrintTag payload: ${openPrintTagPayload!.length} bytes');

  final OpenPrintTagPayload payload = await parser.decode(openPrintTagPayload);
  expect(payload.data, isNotNull);
  print('✅ Successfully decoded\n');

  _inspectData(payload);
}

void _inspectData(OpenPrintTagPayload payload) {
  final Map<String, dynamic> json = payload.toJson();

  final JsonEncoder encoder = JsonEncoder.withIndent(
    '  ',
    (dynamic obj) => obj.toString(),
  );
  final String prettyJson = encoder.convert(json);

  print('📦 Decoded OpenPrintTag Data:');
  print(prettyJson);
  print('');
}

Uint8List? _extractNdefTlv(Uint8List data) {
  const int ndefMagic = 0xE1;
  const int ndefTlvType = 0x03;
  const int nullTlv = 0x00;
  const int terminatorTlv = 0xFE;
  const int extendedLengthMarker = 0xFF;
  const int capabilityContainerSize = 4;

  int offset = data.length >= 4 && data[0] == ndefMagic
      ? capabilityContainerSize
      : 0;

  while (offset < data.length) {
    if (data[offset] == ndefTlvType) {
      offset++;
      if (offset >= data.length) {
        break;
      }

      int length = data[offset++];

      if (length == extendedLengthMarker) {
        if (offset + 1 >= data.length) {
          break;
        }
        length = (data[offset] << 8) | data[offset + 1];
        offset += 2;
      }

      if (offset + length > data.length) {
        break;
      }

      return data.sublist(offset, offset + length);
    } else if (data[offset] == nullTlv) {
      offset++;
    } else if (data[offset] == terminatorTlv) {
      break;
    } else {
      offset++;
      if (offset < data.length) {
        offset += 1 + data[offset];
      }
    }
  }

  return null;
}

Uint8List? _findOpenPrintTagPayload(List<ndef.NDEFRecord> records) {
  for (final ndef.NDEFRecord record in records) {
    if (record is ndef.MimeRecord &&
        record.decodedType == OpenPrintTagConstants.mimeType) {
      return record.payload;
    }
  }
  return null;
}

Future<void> _testRoundTripWithModification(
  String filePath,
  OpenPrintTagParser parser,
) async {
  final File file = File(filePath);
  final Uint8List bytes = await file.readAsBytes();

  final Uint8List? ndefBytes = _extractNdefTlv(bytes);
  expect(ndefBytes, isNotNull);

  final List<ndef.NDEFRecord> records = ndef.decodeRawNdefMessage(ndefBytes!);
  final Uint8List? openPrintTagPayload = _findOpenPrintTagPayload(records);
  expect(openPrintTagPayload, isNotNull);

  final OpenPrintTagPayload originalPayload = await parser.decode(
    openPrintTagPayload!,
  );

  final Map<String, String>? originalMainUnknownFields =
      originalPayload.unknownFields?.main;
  final Map<String, String>? originalAuxUnknownFields =
      originalPayload.unknownFields?.aux;
  final OpenPrintTagMetaData? originalMeta = originalPayload.data.meta;

  final OpenPrintTagMainData? modifiedMain = originalPayload.data.main
      ?.copyWith(
        materialClass:
            originalPayload.data.main?.materialClass ?? MaterialClassEnum.FFF,
        materialType:
            originalPayload.data.main?.materialType ?? MaterialTypeEnum.PLA,
        minPrintTemperature:
            (originalPayload.data.main?.minPrintTemperature ?? 200) + 10,
      );

  final OpenPrintTagPayload modifiedPayload = OpenPrintTagPayload(
    data: OpenPrintTagData(
      meta: originalPayload.data.meta,
      main: modifiedMain,
      aux: originalPayload.data.aux,
    ),
    unknownFields: originalPayload.unknownFields,
  );

  final Uint8List encodedPayload = originalMeta != null
      ? parser.encode(modifiedPayload, size: openPrintTagPayload.length)
      : parser.encode(modifiedPayload, size: 320);

  final OpenPrintTagPayload redecodedPayload = await parser.decode(
    encodedPayload,
  );

  expect(
    redecodedPayload.data.main?.minPrintTemperature,
    (originalPayload.data.main?.minPrintTemperature ?? 200) + 10,
  );

  if (originalMainUnknownFields != null) {
    expect(redecodedPayload.unknownFields?.main, isNotNull);
    expect(
      redecodedPayload.unknownFields!.main!.length,
      originalMainUnknownFields.length,
    );

    for (final MapEntry<String, String> entry
        in originalMainUnknownFields.entries) {
      expect(
        redecodedPayload.unknownFields!.main!.containsKey(entry.key),
        true,
      );
      expect(
        redecodedPayload.unknownFields!.main![entry.key],
        entry.value,
        reason: 'MAIN field ${entry.key}',
      );
    }
  }

  if (originalAuxUnknownFields != null) {
    expect(redecodedPayload.unknownFields?.aux, isNotNull);
    expect(
      redecodedPayload.unknownFields!.aux!.length,
      originalAuxUnknownFields.length,
    );

    for (final MapEntry<String, String> entry
        in originalAuxUnknownFields.entries) {
      expect(redecodedPayload.unknownFields!.aux!.containsKey(entry.key), true);
      expect(
        redecodedPayload.unknownFields!.aux![entry.key],
        entry.value,
        reason: 'AUX field ${entry.key}',
      );
    }
  }

  expect(redecodedPayload.data.meta, isNotNull);
  expect(redecodedPayload.data.meta!.auxRegionOffset, isNotNull);
}
