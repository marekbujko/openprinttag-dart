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
      final OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: 'FFF',
          materialType: 'PLA',
          primaryColor: Uint8List.fromList(<int>[0xFF, 0x00, 0x00]),
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.main!.primaryColor!.length, equals(3));
      expect(
        decoded.main!.primaryColor,
        equals(Uint8List.fromList(<int>[0xFF, 0x00, 0x00])),
      );
    });

    test(
      'encodes and decodes RGBA color with alpha channel (4 bytes)',
      () async {
        final OpenPrintTagData data = OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: 'FFF',
            materialType: 'PLA',
            primaryColor: Uint8List.fromList(<int>[0xFF, 0x00, 0x00, 0x7F]),
          ),
        );

        final Uint8List payload = parser.encode(data, size: 320);
        final OpenPrintTagData decoded = await parser.decode(payload);

        expect(decoded.main!.primaryColor!.length, equals(4));
        expect(
          decoded.main!.primaryColor,
          equals(Uint8List.fromList(<int>[0xFF, 0x00, 0x00, 0x7F])),
        );
        // Verify alpha channel is preserved
        expect(decoded.main!.primaryColor![3], equals(0x7F));
      },
    );

    test('round-trip preserves various RGB and RGBA colors', () async {
      final List<List<int>> testColors = <List<int>>[
        // RGB colors (3 bytes)
        <int>[0xFF, 0x00, 0x00], // Red
        <int>[0x00, 0xFF, 0x00], // Green
        <int>[0x00, 0x00, 0xFF], // Blue
        <int>[0x3D, 0x3E, 0x3D], // Galaxy Black
        // RGBA colors (4 bytes) - test various alpha values
        <int>[0xFF, 0x00, 0x00, 0xFF], // Red, fully opaque
        <int>[0x00, 0xFF, 0x00, 0x00], // Green, fully transparent
        <int>[0x00, 0x00, 0xFF, 0x80], // Blue, semi-transparent
        <int>[0x24, 0x29, 0x2A, 0x7F], // Jet Black with alpha
      ];

      for (final List<int> color in testColors) {
        final OpenPrintTagData data = OpenPrintTagData(
          main: OpenPrintTagMainData(
            materialClass: 'FFF',
            materialType: 'PLA',
            primaryColor: Uint8List.fromList(color),
          ),
        );

        final Uint8List payload = parser.encode(data, size: 320);
        final OpenPrintTagData decoded = await parser.decode(payload);

        expect(
          decoded.main!.primaryColor,
          equals(Uint8List.fromList(color)),
          reason: 'Color $color not preserved',
        );

        // Verify alpha channel for RGBA colors
        if (color.length == 4) {
          expect(
            decoded.main!.primaryColor![3],
            equals(color[3]),
            reason: 'Alpha ${color[3]} not preserved',
          );
        }
      }
    });

    test('handles secondary colors with RGBA', () async {
      final OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: 'FFF',
          materialType: 'PLA',
          primaryColor: Uint8List.fromList(<int>[0xFF, 0x00, 0x00, 0xFF]),
          secondaryColor0: Uint8List.fromList(<int>[0x00, 0xFF, 0x00, 0x80]),
          secondaryColor1: Uint8List.fromList(<int>[0x00, 0x00, 0xFF]), // RGB
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.main!.primaryColor![3], equals(0xFF));
      expect(decoded.main!.secondaryColor0![3], equals(0x80));
      expect(decoded.main!.secondaryColor1!.length, equals(3));
    });

    test('serializes and deserializes colors from JSON hex format', () async {
      // Test RGBA from hex
      final OpenPrintTagMainData mainData = OpenPrintTagMainData.fromJson(
        <String, dynamic>{
          'material_class': 'FFF',
          'material_type': 'PLA',
          'primary_color': <String, String>{'hex': 'ff00007f'},
        },
      );

      expect(mainData.primaryColor!.length, equals(4));
      expect(mainData.primaryColor![3], equals(0x7F));

      // Test serialization back to hex
      final Map<String, dynamic> json = mainData.toJson();
      expect(json['primary_color']['hex'], equals('ff00007f'));
    });

    test('handles null color', () async {
      const OpenPrintTagData data = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: 'FFF',
          materialType: 'PLA',
          primaryColor: null,
        ),
      );

      final Uint8List payload = parser.encode(data, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.main!.primaryColor, isNull);
    });
  });
}
