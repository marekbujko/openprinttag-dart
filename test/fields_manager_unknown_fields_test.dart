import 'package:cbor/cbor.dart';
import 'package:open_print_tag/open_print_tag.dart';
import 'package:open_print_tag/src/data/aux_fields.data.g.dart' as aux_data;
import 'package:open_print_tag/src/data/main_fields.data.g.dart' as main_data;
import 'package:test/test.dart';

void main() {
  late FieldsManager mainFields;
  late FieldsManager auxFields;

  setUpAll(() {
    mainFields = FieldsManager.fromData(main_data.mainFields);
    auxFields = FieldsManager.fromData(aux_data.auxFields);
  });

  group('FieldsManager unknown fields', () {
    test('decode returns unknown CBOR keys separately', () {
      final Map<CborSmallInt, CborValue> input = <CborSmallInt, CborValue>{
        const CborSmallInt(999): const CborSmallInt(42),
        const CborSmallInt(998): CborString('future'),
      };

      final ({Map<String, dynamic> data, Map<int, CborValue>? unknownFields})
      result = mainFields.decode(input);

      expect(result.data.containsKey('unknown_fields'), false);
      expect(result.unknownFields, isNotNull);
      expect(result.unknownFields!.length, 2);
      expect(result.unknownFields![999], isA<CborSmallInt>());
      expect((result.unknownFields![999] as CborSmallInt).value, 42);
      expect(result.unknownFields![998], isA<CborString>());
      expect((result.unknownFields![998] as CborString).toString(), 'future');
    });

    test('encode merges unknown_fields into CBOR map (MAIN)', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
      };

      final Map<int, CborValue> unknownFields = <int, CborValue>{
        777: const CborSmallInt(7),
        778: CborString('x'),
      };

      final Map<int, CborValue> encoded = mainFields.encode(
        data,
        unknownFields: unknownFields,
      );

      expect(encoded[777], isA<CborSmallInt>());
      expect((encoded[777] as CborSmallInt).value, 7);
      expect(encoded[778], isA<CborString>());
      expect((encoded[778] as CborString).toString(), 'x');
    });

    test('encode merges unknown_fields into CBOR map (AUX)', () {
      final Map<String, dynamic> data = <String, dynamic>{};

      final Map<int, CborValue> unknownFields = <int, CborValue>{
        701: const CborSmallInt(123),
      };

      final Map<int, CborValue> encoded = auxFields.encode(
        data,
        unknownFields: unknownFields,
      );

      expect(encoded[701], isA<CborSmallInt>());
      expect((encoded[701] as CborSmallInt).value, 123);
    });
  });
}
