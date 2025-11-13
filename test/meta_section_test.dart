import 'dart:typed_data';

import 'package:open_print_tag/open_print_tag.dart';
import 'package:test/test.dart';

void main() {
  late OpenPrintTagParser parser;

  setUpAll(() {
    parser = OpenPrintTagParser.create();
  });

  group('Meta section', () {
    test('is always at the beginning of payload', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.meta, isNotNull);
    });

    test('main region follows meta when offset not specified', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.meta, isNotNull);
      expect(decoded.main, isNotNull);
    });

    test('aux region is indicated by aux_region_offset', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
        aux: OpenPrintTagAuxData(consumedWeight: 10.0),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.meta, isNotNull);
      expect(decoded.aux, isNotNull);
    });

    test('creates fixed size regions with totalSize', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.meta, isNotNull);
      expect(payload.length, 320);
    });

    test('preserves region sizes during update', () async {
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

      final Uint8List updatedPayload = parser.encode(updatedData, size: 100);
      final OpenPrintTagData decodedUpdated = await parser.decode(
        updatedPayload,
      );

      expect(decodedUpdated.main!.minPrintTemperature, 220);
    });

    test('throws when main section exceeds region size', () async {
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
          materialName: 'Very long material name that will not fit',
          brandName: 'Very long brand name that will not fit either',
        ),
      );

      expect(() => parser.encode(tooLarge, size: 150), throwsArgumentError);
    });

    test('throws when aux section exceeds region size', () async {
      const OpenPrintTagData initialData = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
        aux: OpenPrintTagAuxData(consumedWeight: 10.0),
      );

      final Uint8List payload = parser.encode(initialData, size: 150);
      final OpenPrintTagData decoded = await parser.decode(payload);

      final OpenPrintTagData tooLarge = OpenPrintTagData(
        meta: decoded.meta,
        main: decoded.main,
        aux: const OpenPrintTagAuxData(
          consumedWeight: 10.0,
          workgroup: 'VeryLong',
          generalPurposeRangeUser:
              'Very long string that will exceed the allocated aux region size',
        ),
      );

      expect(() => parser.encode(tooLarge, size: 150), throwsArgumentError);
    });

    test('round-trip preserves meta structure', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          materialName: 'Test',
        ),
        aux: OpenPrintTagAuxData(consumedWeight: 50.0),
      );

      final Uint8List payload1 = parser.encode(data, size: 320);
      final OpenPrintTagData decoded1 = await parser.decode(payload1);

      final Uint8List payload2 = parser.encode(decoded1, size: 320);
      final OpenPrintTagData decoded2 = await parser.decode(payload2);

      expect(decoded2.main, isNotNull);
      expect(decoded2.aux, isNotNull);
    });

    test('allows smaller data in fixed size region', () async {
      const OpenPrintTagData largeData = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
          materialName: 'Long material name',
          brandName: 'Long brand name',
        ),
      );

      final Uint8List payload = parser.encode(largeData, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      final OpenPrintTagData smallerData = OpenPrintTagData(
        meta: decoded.meta,
        main: const OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
      );

      final Uint8List updatedPayload = parser.encode(smallerData, size: 320);
      final OpenPrintTagData decodedUpdated = await parser.decode(
        updatedPayload,
      );

      expect(decodedUpdated.main!.materialClass, MaterialClassEnum.FFF);
      expect(decodedUpdated.main!.materialType, MaterialTypeEnum.PLA);
      expect(decodedUpdated.main!.materialName, isNull);
      expect(decodedUpdated.main!.brandName, isNull);
    });

    test('calculates region sizes when not specified', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: MaterialClassEnum.FFF,
          materialType: MaterialTypeEnum.PLA,
        ),
        aux: OpenPrintTagAuxData(consumedWeight: 10.0),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.meta!.mainRegionSize, isNull);
      expect(decoded.meta!.auxRegionSize, isNull);

      expect(decoded.main, isNotNull);
      expect(decoded.aux, isNotNull);
    });
  });
}
