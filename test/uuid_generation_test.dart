import 'package:open_print_tag/models/models.dart';
import 'package:open_print_tag/src/uuid_generator.dart';
import 'package:test/test.dart';

void main() {
  group('UUID auto-generation', () {
    test('fromJson generates missing UUIDs', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'brand_name': 'TestBrand',
        'material_name': 'PLA',
        'gtin': 1234567890123,
        'material_class': 'FFF',
      };

      final OpenPrintTagMainData data = OpenPrintTagMainData.fromJson(json);

      expect(data.brandUuid, isNotNull);
      expect(data.materialUuid, isNotNull);
      expect(data.packageUuid, isNotNull);

      final String expectedBrandUuid = OpenPrintTagUuidGenerator.buildBrandUuid(
        'TestBrand',
      );
      final String expectedMaterialUuid =
          OpenPrintTagUuidGenerator.buildMaterialUuid(expectedBrandUuid, 'PLA');
      final String expectedPackageUuid =
          OpenPrintTagUuidGenerator.buildPackageUuid(
            expectedBrandUuid,
            1234567890123,
          );

      expect(data.brandUuid, equals(expectedBrandUuid));
      expect(data.materialUuid, equals(expectedMaterialUuid));
      expect(data.packageUuid, equals(expectedPackageUuid));
    });

    test('toJson generates missing UUIDs', () {
      const OpenPrintTagMainData data = OpenPrintTagMainData(
        brandName: 'TestBrand',
        materialName: 'PLA',
        gtin: 1234567890123,
        materialClass: 'FFF',
      );

      final Map<String, dynamic> json = data.toJson();

      expect(json['brand_uuid'], isNotNull);
      expect(json['material_uuid'], isNotNull);
      expect(json['package_uuid'], isNotNull);

      final String expectedBrandUuid = OpenPrintTagUuidGenerator.buildBrandUuid(
        'TestBrand',
      );
      final String expectedMaterialUuid =
          OpenPrintTagUuidGenerator.buildMaterialUuid(expectedBrandUuid, 'PLA');
      final String expectedPackageUuid =
          OpenPrintTagUuidGenerator.buildPackageUuid(
            expectedBrandUuid,
            1234567890123,
          );

      expect(json['brand_uuid'], equals(expectedBrandUuid));
      expect(json['material_uuid'], equals(expectedMaterialUuid));
      expect(json['package_uuid'], equals(expectedPackageUuid));
    });

    test('fromJson preserves existing UUIDs', () {
      const String customBrandUuid = '12345678-1234-1234-1234-123456789abc';
      final Map<String, dynamic> json = <String, dynamic>{
        'brand_uuid': customBrandUuid,
        'brand_name': 'TestBrand',
        'material_class': 'FFF',
      };

      final OpenPrintTagMainData data = OpenPrintTagMainData.fromJson(json);

      expect(data.brandUuid, equals(customBrandUuid));
    });

    test('toJson preserves existing UUIDs', () {
      const String customBrandUuid = '12345678-1234-1234-1234-123456789abc';
      const OpenPrintTagMainData data = OpenPrintTagMainData(
        brandUuid: customBrandUuid,
        brandName: 'TestBrand',
        materialClass: 'FFF',
      );

      final Map<String, dynamic> json = data.toJson();

      expect(json['brand_uuid'], equals(customBrandUuid));
    });

    test('UUID generation is deterministic', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'brand_name': 'TestBrand',
        'material_name': 'PLA',
        'gtin': 1234567890123,
        'material_class': 'FFF',
      };

      final OpenPrintTagMainData data1 = OpenPrintTagMainData.fromJson(json);
      final OpenPrintTagMainData data2 = OpenPrintTagMainData.fromJson(json);

      expect(data1.brandUuid, equals(data2.brandUuid));
      expect(data1.materialUuid, equals(data2.materialUuid));
      expect(data1.packageUuid, equals(data2.packageUuid));
    });

    test('round-trip preserves generated UUIDs', () {
      const OpenPrintTagMainData data1 = OpenPrintTagMainData(
        brandName: 'TestBrand',
        materialName: 'PLA',
        gtin: 1234567890123,
        materialClass: 'FFF',
      );

      final Map<String, dynamic> json = data1.toJson();
      final OpenPrintTagMainData data2 = OpenPrintTagMainData.fromJson(json);
      final Map<String, dynamic> json2 = data2.toJson();

      expect(json2['brand_uuid'], equals(json['brand_uuid']));
      expect(json2['material_uuid'], equals(json['material_uuid']));
      expect(json2['package_uuid'], equals(json['package_uuid']));
    });
  });
}
