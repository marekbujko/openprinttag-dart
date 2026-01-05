import 'dart:typed_data';

import 'package:open_print_tag/open_print_tag.dart';
import 'package:test/test.dart';

void main() {
  late OpenPrintTagParser parser;

  setUpAll(() {
    parser = OpenPrintTagParser.create();
  });

  group('Color Encoding - RGB and RGBA', () {
    test('encodes and decodes RGB color (3 bytes)', () async {
      final OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            primaryColor: Uint8List.fromList(<int>[0xFF, 0x00, 0x00]),
          ),
        ),
      );

      final Uint8List encoded = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      expect(decoded.data.main!.primaryColor!.length, equals(3));
      expect(
        decoded.data.main!.primaryColor,
        equals(Uint8List.fromList(<int>[0xFF, 0x00, 0x00])),
      );
    });

    test(
      'encodes and decodes RGBA color with alpha channel (4 bytes)',
      () async {
        final OpenPrintTagPayload payload = OpenPrintTagPayload(
          data: OpenPrintTagData(
            main: OpenPrintTagMainData(
              materialClass: MaterialClassEnum.FFF,
              materialType: MaterialTypeEnum.PLA,
              primaryColor: Uint8List.fromList(<int>[0xFF, 0x00, 0x00, 0x7F]),
            ),
          ),
        );

        final Uint8List encoded = parser.encode(payload, size: 320);
        final OpenPrintTagPayload decoded = await parser.decode(encoded);

        expect(decoded.data.main!.primaryColor!.length, equals(4));
        expect(
          decoded.data.main!.primaryColor,
          equals(Uint8List.fromList(<int>[0xFF, 0x00, 0x00, 0x7F])),
        );
        expect(decoded.data.main!.primaryColor![3], equals(0x7F));
      },
    );

    test('round-trip preserves various RGB and RGBA colors', () async {
      final List<List<int>> testColors = <List<int>>[
        <int>[0xFF, 0x00, 0x00],
        <int>[0x00, 0xFF, 0x00],
        <int>[0x00, 0x00, 0xFF],
        <int>[0x3D, 0x3E, 0x3D],
        <int>[0xFF, 0x00, 0x00, 0xFF],
        <int>[0x00, 0xFF, 0x00, 0x00],
        <int>[0x00, 0x00, 0xFF, 0x80],
        <int>[0x24, 0x29, 0x2A, 0x7F],
      ];

      for (final List<int> color in testColors) {
        final OpenPrintTagPayload payload = OpenPrintTagPayload(
          data: OpenPrintTagData(
            main: OpenPrintTagMainData(
              materialClass: MaterialClassEnum.FFF,
              materialType: MaterialTypeEnum.PLA,
              primaryColor: Uint8List.fromList(color),
            ),
          ),
        );

        final Uint8List encoded = parser.encode(payload, size: 320);
        final OpenPrintTagPayload decoded = await parser.decode(encoded);

        expect(
          decoded.data.main!.primaryColor,
          equals(Uint8List.fromList(color)),
          reason: 'Color $color not preserved',
        );

        if (color.length == 4) {
          expect(
            decoded.data.main!.primaryColor![3],
            equals(color[3]),
            reason: 'Alpha ${color[3]} not preserved',
          );
        }
      }
    });

    test('handles secondary colors with RGBA', () async {
      final OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            primaryColor: Uint8List.fromList(<int>[0xFF, 0x00, 0x00, 0xFF]),
            secondaryColor0: Uint8List.fromList(<int>[0x00, 0xFF, 0x00, 0x80]),
            secondaryColor1: Uint8List.fromList(<int>[0x00, 0x00, 0xFF]),
          ),
        ),
      );

      final Uint8List encoded = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      expect(decoded.data.main!.primaryColor![3], equals(0xFF));
      expect(decoded.data.main!.secondaryColor0![3], equals(0x80));
      expect(decoded.data.main!.secondaryColor1!.length, equals(3));
    });

    test('serializes and deserializes colors from JSON hex format', () async {
      final OpenPrintTagMainData mainData = OpenPrintTagMainData.fromJson(
        <String, dynamic>{
          'material_class': 'FFF',
          'material_type': 'PLA',
          'primary_color': '#ff00007f',
        },
      );

      expect(mainData.primaryColor!.length, equals(4));
      expect(mainData.primaryColor![3], equals(0x7F));

      final Map<String, dynamic> json = mainData.toJson();
      expect(json['primary_color'], equals('#ff00007f'));
    });

    test('handles null color', () async {
      const OpenPrintTagPayload payload = OpenPrintTagPayload(
        data: OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: MaterialClassEnum.FFF,
            materialType: MaterialTypeEnum.PLA,
            primaryColor: null,
          ),
        ),
      );

      final Uint8List encoded = parser.encode(payload, size: 320);
      final OpenPrintTagPayload decoded = await parser.decode(encoded);

      expect(decoded.data.main!.primaryColor, isNull);
    });
  });
}
