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
      final Map<String, String> unknownFields = <String, String>{
        CborHexUtils.intToHex(999): CborHexUtils.cborValueToHex(
          const CborSmallInt(42),
        ),
        CborHexUtils.intToHex(998): CborHexUtils.cborValueToHex(
          CborString('future_data'),
        ),
      };

      final OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: const OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            materialName: 'Test Material',
          ),
        ),
        unknownFields: UnknownFields(main: unknownFields),
      );

      final Uint8List encodedPayload = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encodedPayload);

      expect(decoded.data.main, isNotNull);
      expect(decoded.unknownFields, isNotNull);
      expect(decoded.unknownFields!.main, isNotNull);
      expect(decoded.unknownFields!.main!.length, 2);

      final String key999Hex = CborHexUtils.intToHex(999);
      final String key998Hex = CborHexUtils.intToHex(998);
      expect(decoded.unknownFields!.main!.containsKey(key999Hex), isTrue);
      expect(decoded.unknownFields!.main!.containsKey(key998Hex), isTrue);

      final CborValue val999 = CborHexUtils.hexToCborValue(
        decoded.unknownFields!.main![key999Hex]!,
      );
      expect(val999, isA<CborSmallInt>());
      expect((val999 as CborSmallInt).value, 42);

      final CborValue val998 = CborHexUtils.hexToCborValue(
        decoded.unknownFields!.main![key998Hex]!,
      );
      expect(val998, isA<CborString>());
      expect((val998 as CborString).toString(), 'future_data');

      expect(decoded.data.main!.materialClass, MaterialClassEnum.FFF);
      expect(decoded.data.main!.materialType, MaterialTypeEnum.PLA);
      expect(decoded.data.main!.materialName, 'Test Material');
    });

    test('preserves unknown fields in AUX section', () async {
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
          aux: OpenPrintTagAuxData(consumedWeight: 50.5, workgroup: 'TestGrp'),
        ),
      );

      final Uint8List encodedPayload1 = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded1 = await parser.decode(encodedPayload1);

      final Map<String, String> auxUnknownFields = <String, String>{
        CborHexUtils.intToHex(777): CborHexUtils.cborValueToHex(
          const CborSmallInt(123),
        ),
      };

      final OpenPrintTagPayload payloadWithUnknown = OpenPrintTagPayload(
        data: decoded1.data,
        unknownFields: UnknownFields(aux: auxUnknownFields),
      );

      final Uint8List encodedPayload2 = parser.encode(
        payloadWithUnknown,
        size: 320,
      );
      final OpenPrintTagPayload decoded2 = await parser.decode(encodedPayload2);

      expect(decoded2.data.aux, isNotNull);
      expect(decoded2.unknownFields, isNotNull);
      expect(decoded2.unknownFields!.aux, isNotNull);
      expect(decoded2.unknownFields!.aux!.length, 1);

      final String key777Hex = CborHexUtils.intToHex(777);
      expect(decoded2.unknownFields!.aux!.containsKey(key777Hex), isTrue);

      final CborValue val777 = CborHexUtils.hexToCborValue(
        decoded2.unknownFields!.aux![key777Hex]!,
      );
      expect(val777, isA<CborSmallInt>());
      expect((val777 as CborSmallInt).value, 123);

      expect(decoded2.data.aux!.consumedWeight, 50.5);
      expect(decoded2.data.aux!.workgroup, 'TestGrp');
    });

    test('preserves binary unknown fields exactly', () async {
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
        ),
      );

      final Uint8List encodedPayload1 = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded1 = await parser.decode(encodedPayload1);

      final Uint8List binaryData = Uint8List.fromList(<int>[
        0xDE,
        0xAD,
        0xBE,
        0xEF,
      ]);

      final Map<String, String> mainUnknownFields = <String, String>{
        CborHexUtils.intToHex(888): CborHexUtils.cborValueToHex(
          CborBytes(binaryData),
        ),
      };

      final OpenPrintTagPayload payloadWithBinary = OpenPrintTagPayload(
        data: decoded1.data,
        unknownFields: UnknownFields(main: mainUnknownFields),
      );

      final Uint8List encodedPayload2 = parser.encode(
        payloadWithBinary,
        size: 320,
      );
      final OpenPrintTagPayload decoded2 = await parser.decode(encodedPayload2);

      expect(decoded2.unknownFields, isNotNull);
      expect(decoded2.unknownFields!.main, isNotNull);

      final String key888Hex = CborHexUtils.intToHex(888);
      expect(decoded2.unknownFields!.main!.containsKey(key888Hex), isTrue);

      final CborValue val888 = CborHexUtils.hexToCborValue(
        decoded2.unknownFields!.main![key888Hex]!,
      );
      expect(val888, isA<CborBytes>());
      expect((val888 as CborBytes).bytes, <int>[0xDE, 0xAD, 0xBE, 0xEF]);
    });
  });
}
