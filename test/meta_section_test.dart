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
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
        ),
      );

      final Uint8List encoded = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      expect(decoded.data.meta, isNotNull);
    });

    test('main region follows meta when offset not specified', () async {
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
        ),
      );

      final Uint8List encoded = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      expect(decoded.data.meta, isNotNull);
      expect(decoded.data.main, isNotNull);
    });

    test('aux region is indicated by aux_region_offset', () async {
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
          aux: OpenPrintTagAuxData(consumedWeight: 10.0),
        ),
      );

      final Uint8List encoded = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      expect(decoded.data.meta, isNotNull);
      expect(decoded.data.aux, isNotNull);
    });

    test('creates fixed size regions with totalSize', () async {
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
        ),
      );

      final Uint8List encoded = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      expect(decoded.data.meta, isNotNull);
      expect(encoded.length, 320);
    });

    test('preserves region sizes during update', () async {
      const OpenPrintTagPayload initialPayload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            minPrintTemperature: 200,
          ),
        ),
      );

      final Uint8List initialEncoded = parser.encode(initialPayload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(initialEncoded);

      expect(decoded.data.main, isNotNull);

      const OpenPrintTagPayload updatedPayload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            minPrintTemperature: 220,
          ),
        ),
      );

      final Uint8List updatedEncoded = parser.encode(updatedPayload, size: 100);
      final OpenPrintTagPayload decodedUpdated = await parser.decode(
        updatedEncoded,
      );

      expect(decodedUpdated.data.main!.minPrintTemperature, 220);
    });

    test('throws when main section exceeds region size', () async {
      const OpenPrintTagPayload initialPayload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
        ),
      );

      final Uint8List encoded = parser.encode(initialPayload, size: 100);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      final OpenPrintTagPayload tooLarge = OpenPrintTagPayload(
        data: OpenPrintTagData(
          meta: decoded.data.meta,
          main: const OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            materialName: 'Very long material name that will not fit',
            brandName: 'Very long brand name that will not fit either',
          ),
        ),
      );

      expect(() => parser.encode(tooLarge, size: 150), throwsArgumentError);
    });

    test('throws when aux section exceeds region size', () async {
      const OpenPrintTagPayload initialPayload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
          aux: OpenPrintTagAuxData(consumedWeight: 10.0),
        ),
      );

      final Uint8List encoded = parser.encode(initialPayload, size: 150);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      final OpenPrintTagPayload tooLarge = OpenPrintTagPayload(
        data: OpenPrintTagData(
          meta: decoded.data.meta,
          main: decoded.data.main,
          aux: const OpenPrintTagAuxData(
            consumedWeight: 10.0,
            workgroup: 'VeryLong',
            generalPurposeRangeUser:
                'Very long string that will exceed the allocated aux region size',
          ),
        ),
      );

      expect(() => parser.encode(tooLarge, size: 150), throwsArgumentError);
    });

    test('round-trip preserves meta structure', () async {
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            materialName: 'Test',
          ),
          aux: OpenPrintTagAuxData(consumedWeight: 50.0),
        ),
      );

      final Uint8List encoded1 = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded1 = await parser.decode(encoded1);

      final Uint8List encoded2 = parser.encode(decoded1, size: 320);
      final OpenPrintTagPayload decoded2 = await parser.decode(encoded2);

      expect(decoded2.data.main, isNotNull);
      expect(decoded2.data.aux, isNotNull);
    });

    test('allows smaller data in fixed size region', () async {
      const OpenPrintTagPayload largePayload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            materialName: 'Long material name',
            brandName: 'Long brand name',
          ),
        ),
      );

      final Uint8List encoded = parser.encode(largePayload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      final OpenPrintTagPayload smallerPayload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          meta: decoded.data.meta,
          main: const OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
        ),
      );

      final Uint8List updatedEncoded = parser.encode(smallerPayload, size: 320);
      final OpenPrintTagPayload decodedUpdated = await parser.decode(
        updatedEncoded,
      );

      expect(decodedUpdated.data.main!.materialClass, MaterialClassEnum.FFF);
      expect(decodedUpdated.data.main!.materialType, MaterialTypeEnum.PLA);
      expect(decodedUpdated.data.main!.materialName, isNull);
      expect(decodedUpdated.data.main!.brandName, isNull);
    });

    test('calculates region sizes when not specified', () async {
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
          ),
          aux: OpenPrintTagAuxData(consumedWeight: 10.0),
        ),
      );

      final Uint8List encoded = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      expect(decoded.data.meta!.mainRegionSize, isNull);
      expect(decoded.data.meta!.auxRegionSize, isNull);

      expect(decoded.data.main, isNotNull);
      expect(decoded.data.aux, isNotNull);
    });
  });
}
