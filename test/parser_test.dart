import 'dart:typed_data';

import 'package:open_print_tag/open_print_tag.dart';
import 'package:test/test.dart';

void main() {
  late OpenPrintTagParser parser;

  setUpAll(() {
    parser = OpenPrintTagParser.create();
  });

  group('OpenPrintTagParser', () {
    test('throws FormatException on invalid CBOR payload', () async {
      final Uint8List invalidPayload = Uint8List.fromList(<int>[
        0xFF,
        0xFF,
        0xFF,
      ]);

      await expectLater(
        parser.decode(invalidPayload),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on non-map CBOR', () async {
      final Uint8List arrayPayload = Uint8List.fromList(<int>[
        0x83,
        0x01,
        0x02,
        0x03,
      ]);

      await expectLater(
        parser.decode(arrayPayload),
        throwsA(isA<FormatException>()),
      );
    });

    test('encodes and decodes basic payload', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData result = await parser.decode(payload);

      expect(result.meta, isNotNull);
      expect(result.main, isNotNull);
      expect(result.main!.materialClass, MaterialClassEnum.FFF);
      expect(result.main!.materialType, MaterialTypeEnum.PLA);
    });
  });

  group('Encoding', () {
    test('encodes basic main data', () {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialName: 'PLA Premium',
          materialType: MaterialTypeEnum.PLA,
          minPrintTemperature: 215,
          minBedTemperature: 60,
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);

      expect(payload, isNotEmpty);
      expect(payload, isA<Uint8List>());
    });

    test('encodes data with meta and aux regions', () {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialName: 'PETG Premium',
          materialType: MaterialTypeEnum.PETG,
          minPrintTemperature: 230,
          minBedTemperature: 85,
        ),
        aux: OpenPrintTagAuxData(workgroup: 'ProdGrp', consumedWeight: 50.5),
      );

      final Uint8List payload = parser.encode(data, size: 320);

      expect(payload, isNotEmpty);
      expect(payload, isA<Uint8List>());
    });

    test('throws when no main data provided', () {
      const OpenPrintTagData data = OpenPrintTagData();

      expect(() => parser.encode(data, size: 320), throwsArgumentError);
    });

    test('preserves data during round-trip', () async {
      const OpenPrintTagData originalData = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialName: 'ABS Premium',
          materialType: MaterialTypeEnum.ABS,
          minPrintTemperature: 240,
          minBedTemperature: 100,
          density: 1.04,
        ),
      );

      final Uint8List payload = parser.encode(originalData, size: 320);
      final OpenPrintTagData decodedData = await parser.decode(payload);

      expect(decodedData.main, isNotNull);
      expect(decodedData.main!.materialClass, originalData.main!.materialClass);
      expect(decodedData.main!.materialName, originalData.main!.materialName);
      expect(decodedData.main!.materialType, originalData.main!.materialType);
      expect(
        decodedData.main!.minPrintTemperature,
        originalData.main!.minPrintTemperature,
      );
      expect(
        decodedData.main!.minBedTemperature,
        originalData.main!.minBedTemperature,
      );
      expect(decodedData.main!.density, originalData.main!.density);
      expect(decodedData.meta, isNotNull);
    });

    test('preserves all regions during round-trip', () async {
      const OpenPrintTagData originalData = OpenPrintTagData(
        meta: OpenPrintTagMetaData(),
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialName: 'TPU Flexible',
          materialType: MaterialTypeEnum.TPU,
          minPrintTemperature: 220,
          minBedTemperature: 50,
        ),
        aux: OpenPrintTagAuxData(workgroup: 'TestGrp', consumedWeight: 123.45),
      );

      final Uint8List payload = parser.encode(originalData, size: 320);
      final OpenPrintTagData decodedData = await parser.decode(payload);

      expect(decodedData.main, isNotNull);
      expect(decodedData.main!.materialClass, originalData.main!.materialClass);
      expect(decodedData.main!.materialName, originalData.main!.materialName);
      expect(decodedData.main!.materialType, originalData.main!.materialType);
      expect(decodedData.aux, isNotNull);
      expect(decodedData.aux!.workgroup, originalData.aux!.workgroup);
      expect(decodedData.aux!.consumedWeight, originalData.aux!.consumedWeight);
      expect(decodedData.meta, isNotNull);
    });

    test('throws when required field is missing', () {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialName: 'PLA Premium',
          materialType: MaterialTypeEnum.PLA,
          minPrintTemperature: 215,
          minBedTemperature: 60,
        ),
      );

      expect(
        () => parser.encode(data, size: 320),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            contains('Missing required field: material_class'),
          ),
        ),
      );
    });
  });

  group('Meta region', () {
    test('creates minimal META without aux', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          materialName: 'Test Material',
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.meta, isNotNull);
      expect(decoded.main, isNotNull);
    });

    test('creates META with aux region', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
        aux: OpenPrintTagAuxData(workgroup: 'TestGrp', consumedWeight: 100.5),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.meta, isNotNull);
      expect(decoded.main, isNotNull);
      expect(decoded.aux, isNotNull);
    });

    test('validates meta structure', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          materialName: 'Test Material',
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.meta, isNotNull);
      expect(decoded.main, isNotNull);
    });
  });

  group('Fixed size encoding', () {
    test('creates tag with fixed size and padding', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          materialName: 'Test Material',
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);

      expect(payload.length, 320);

      final OpenPrintTagData decoded = await parser.decode(payload);
      expect(decoded.main, isNotNull);
      expect(decoded.main!.materialClass, MaterialClassEnum.FFF);
      expect(decoded.meta, isNotNull);
    });

    test('throws when data exceeds totalSize', () {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          materialName: 'Very long material name that takes up lots of space',
        ),
      );

      expect(() => parser.encode(data, size: 10), throwsArgumentError);
    });
  });

  group('Update mode', () {
    test('preserves META sizes when updating', () async {
      const OpenPrintTagData initialData = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          minPrintTemperature: 200,
        ),
      );

      final Uint8List initialPayload = parser.encode(initialData, size: 320);
      final OpenPrintTagData decoded = await parser.decode(initialPayload);

      expect(decoded.main, isNotNull);

      const OpenPrintTagData updatedData = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          minPrintTemperature: 220,
        ),
      );

      final Uint8List updatedPayload = parser.encode(updatedData, size: 320);
      final OpenPrintTagData decodedUpdated = await parser.decode(
        updatedPayload,
      );

      expect(decodedUpdated.main!.minPrintTemperature, 220);
    });

    test('throws when updated data exceeds fixed size', () async {
      const OpenPrintTagData initialData = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
      );

      final Uint8List payload = parser.encode(initialData, size: 100);
      final OpenPrintTagData decoded = await parser.decode(payload);

      final OpenPrintTagData tooLarge = OpenPrintTagData(
        meta: decoded.meta,
        main: const OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          materialName: 'Very long name that will not fit',
        ),
      );

      expect(() => parser.encode(tooLarge, size: 10), throwsArgumentError);
    });
  });
}
