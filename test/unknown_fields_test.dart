import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:open_print_tag/open_print_tag.dart';
import 'package:test/test.dart';

void main() {
  late OpenPrintTagParser parser;

  setUpAll(() {
    parser = OpenPrintTagParser.create();
  });

  group('Unknown fields preservation', () {
    test('preserves unknown fields in MAIN section', () async {
      final OpenPrintTagMainData mainWithUnknown = OpenPrintTagMainData(
        materialClass: 'FFF',
        materialType: 'PLA',
        materialName: 'Test Material',
        unknownFields: <int, CborValue>{
          999: const CborSmallInt(42),
          998: CborString('future_data'),
        },
      );

      final OpenPrintTagData dataWithUnknown = OpenPrintTagData(
        main: mainWithUnknown,
      );

      final Uint8List payloadWithUnknown = parser.encode(
        dataWithUnknown,
        size: 320,
      );
      final OpenPrintTagData decoded = await parser.decode(payloadWithUnknown);

      expect(decoded.main, isNotNull);
      expect(decoded.main!.unknownFields, isNotNull);
      expect(decoded.main!.unknownFields!.length, 2);
      expect(decoded.main!.unknownFields![999], isA<CborSmallInt>());
      expect((decoded.main!.unknownFields![999] as CborSmallInt).value, 42);
      expect(decoded.main!.unknownFields![998], isA<CborString>());
      expect(
        (decoded.main!.unknownFields![998] as CborString).toString(),
        'future_data',
      );

      expect(decoded.main!.materialClass, 'FFF');
      expect(decoded.main!.materialType, 'PLA');
      expect(decoded.main!.materialName, 'Test Material');
    });

    test('preserves unknown fields in AUX section', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(materialClass: 'FFF', materialType: 'PLA'),
        aux: OpenPrintTagAuxData(consumedWeight: 50.5, workgroup: 'TestGrp'),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded1 = await parser.decode(payload);

      final OpenPrintTagAuxData auxWithUnknown = OpenPrintTagAuxData(
        consumedWeight: decoded1.aux!.consumedWeight,
        workgroup: decoded1.aux!.workgroup,
        unknownFields: <int, CborValue>{777: const CborSmallInt(123)},
      );

      final OpenPrintTagData dataWithUnknown = OpenPrintTagData(
        main: decoded1.main,
        aux: auxWithUnknown,
      );

      final Uint8List payloadWithUnknown = parser.encode(
        dataWithUnknown,
        size: 320,
      );
      final OpenPrintTagData decoded2 = await parser.decode(payloadWithUnknown);

      expect(decoded2.aux, isNotNull);
      expect(decoded2.aux!.unknownFields, isNotNull);
      expect(decoded2.aux!.unknownFields!.length, 1);
      expect(decoded2.aux!.unknownFields![777], isA<CborSmallInt>());
      expect((decoded2.aux!.unknownFields![777] as CborSmallInt).value, 123);

      expect(decoded2.aux!.consumedWeight, 50.5);
      expect(decoded2.aux!.workgroup, 'TestGrp');
    });

    test('preserves binary unknown fields exactly', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(materialClass: 'FFF', materialType: 'PLA'),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded1 = await parser.decode(payload);

      final Uint8List binaryData = Uint8List.fromList(<int>[
        0xDE,
        0xAD,
        0xBE,
        0xEF,
      ]);
      final OpenPrintTagMainData mainWithBinary = OpenPrintTagMainData(
        materialClass: decoded1.main!.materialClass,
        materialType: decoded1.main!.materialType,
        unknownFields: <int, CborValue>{888: CborBytes(binaryData)},
      );

      final OpenPrintTagData dataWithBinary = OpenPrintTagData(
        main: mainWithBinary,
      );

      final Uint8List payloadWithBinary = parser.encode(
        dataWithBinary,
        size: 320,
      );
      final OpenPrintTagData decoded2 = await parser.decode(payloadWithBinary);

      expect(decoded2.main!.unknownFields, isNotNull);
      expect(decoded2.main!.unknownFields![888], isA<CborBytes>());

      final List<int> decodedBytes =
          (decoded2.main!.unknownFields![888] as CborBytes).bytes;
      expect(decodedBytes, <int>[0xDE, 0xAD, 0xBE, 0xEF]);
    });
  });
}
