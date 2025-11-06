import 'package:open_print_tag/models/models.dart';
import 'package:open_print_tag/src/uuid_generator.dart';
import 'package:test/test.dart';

void main() {
  group('UUID auto-generation', () {
    test('auto-generates UUIDs when missing', () {
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

      final String? expectedBrandUuid =
          OpenPrintTagUuidGenerator.buildBrandUuid('TestBrand');
      final String? expectedMaterialUuid =
          OpenPrintTagUuidGenerator.buildMaterialUuid(expectedBrandUuid, 'PLA');
      final String? expectedPackageUuid =
          OpenPrintTagUuidGenerator.buildPackageUuid(
            expectedBrandUuid,
            1234567890123,
          );

      expect(data.brandUuid, equals(expectedBrandUuid));
      expect(data.materialUuid, equals(expectedMaterialUuid));
      expect(data.packageUuid, equals(expectedPackageUuid));
    });

    test('does not generate UUIDs on serialization without fromJson', () {
      const OpenPrintTagMainData data = OpenPrintTagMainData(
        brandName: 'TestBrand',
        materialName: 'PLA',
        gtin: 1234567890123,
        materialClass: 'FFF',
      );

      final Map<String, dynamic> json = data.toJson();

      // UUIDs are not generated in toJson(), only in fromJson()
      expect(json['brand_uuid'], isNull);
      expect(json['material_uuid'], isNull);
      expect(json['package_uuid'], isNull);
    });

    test('keeps existing UUIDs when present', () {
      const String customBrandUuid = '12345678-1234-1234-1234-123456789abc';
      final Map<String, dynamic> json = <String, dynamic>{
        'brand_uuid': customBrandUuid,
        'brand_name': 'TestBrand',
        'material_class': 'FFF',
      };

      final OpenPrintTagMainData data = OpenPrintTagMainData.fromJson(json);

      expect(data.brandUuid, equals(customBrandUuid));
    });

    test('removes UUIDs from JSON when brandName is present', () {
      const String customBrandUuid = '12345678-1234-1234-1234-123456789abc';
      const OpenPrintTagMainData data = OpenPrintTagMainData(
        brandUuid: customBrandUuid,
        brandName: 'TestBrand',
        materialClass: 'FFF',
      );

      final Map<String, dynamic> json = data.toJson();

      // UUID is removed because it can be regenerated from brandName
      expect(json['brand_uuid'], isNull);
    });

    test('generates same UUID for same input', () {
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

    test('UUIDs survive round-trip through fromJson', () {
      const OpenPrintTagMainData data1 = OpenPrintTagMainData(
        brandName: 'TestBrand',
        materialName: 'PLA',
        gtin: 1234567890123,
        materialClass: 'FFF',
      );

      final Map<String, dynamic> json = data1.toJson();
      final OpenPrintTagMainData data2 = OpenPrintTagMainData.fromJson(json);
      final Map<String, dynamic> json2 = data2.toJson();

      // Both should be null because UUIDs are removed when names are present
      expect(json['brand_uuid'], isNull);
      expect(json['material_uuid'], isNull);
      expect(json['package_uuid'], isNull);
      expect(json2['brand_uuid'], isNull);
      expect(json2['material_uuid'], isNull);
      expect(json2['package_uuid'], isNull);

      // But the data objects should have UUIDs generated from fromJson
      expect(data2.brandUuid, isNotNull);
      expect(data2.materialUuid, isNotNull);
      expect(data2.packageUuid, isNotNull);
    });

    test('generates correct UUIDs for real data', () {
      const String brandName = 'Prusament';
      const String materialName = 'PLA Prusa Galaxy Black';
      const num gtin = 1234;
      final List<int> nfcUidBytes = <int>[
        0xE0,
        0x04,
        0x01,
        0x08,
        0x66,
        0x2F,
        0x6F,
        0xBC,
      ];

      const String expectedBrandUuid = 'ae5ff34e-298e-50c9-8f77-92a97fb30b09';
      const String expectedMaterialUuid =
          '1aaca54a-431f-5601-adf5-85dd018f487f';
      const String expectedPackageUuid = '7ed3ce83-764d-56de-bdcd-dc5226a0efd1';
      const String expectedInstanceUuid =
          'daeec88a-be54-5138-adb2-e88bde443821';

      final String? brandUuid = OpenPrintTagUuidGenerator.buildBrandUuid(
        brandName,
      );
      final String? materialUuid = OpenPrintTagUuidGenerator.buildMaterialUuid(
        brandUuid,
        materialName,
      );
      final String? packageUuid = OpenPrintTagUuidGenerator.buildPackageUuid(
        brandUuid,
        gtin,
      );
      final String? instanceUuid = OpenPrintTagUuidGenerator.buildInstanceUuid(
        brandUuid,
        nfcUidBytes,
      );

      expect(brandUuid, equals(expectedBrandUuid));
      expect(materialUuid, equals(expectedMaterialUuid));
      expect(packageUuid, equals(expectedPackageUuid));
      expect(instanceUuid, equals(expectedInstanceUuid));
    });
  });
}
