import 'package:open_print_tag/open_print_tag.dart';
import 'package:open_print_tag/src/data/main_fields.data.g.dart' as main_data;
import 'package:test/test.dart';

void main() {
  late FieldsManager mainFields;
  late JsonValidator validator;

  setUpAll(() {
    mainFields = FieldsManager.fromData(main_data.mainFields);
    validator = JsonValidator(fields: mainFields);
  });

  group('JsonValidator', () {
    test('validates valid data', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'material_name': 'Test PLA',
        'brand_name': 'TestBrand',
      };

      final ValidationResult result = validator.validate(data);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('detects missing required fields', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_name': 'Test PLA',
      };

      final ValidationResult result = validator.validate(data);

      final List<String> missingFields = result.requiredErrors
          .map((ValidationError e) => e.field)
          .toList();

      // material_class is required
      expect(missingFields, contains('material_class'));
    });

    test('validates enum values', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'INVALID_CLASS',
        'material_type': 'PLA',
      };

      final ValidationResult result = validator.validate(data);
      expect(result.isValid, isFalse);
      expect(result.valueErrors.length, 1);
      expect(result.valueErrors.first.field, 'material_class');
    });

    test('validates string max length', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'material_name': 'A' * 100, // Too long
      };

      final ValidationResult result = validator.validate(data);

      final bool hasMaterialNameError = result.errors.any(
        (ValidationError e) =>
            e.field == 'material_name' &&
            e.type == ValidationErrorType.maxLengthExceeded,
      );
      expect(hasMaterialNameError, isTrue);
    });

    test('validates number types', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'density': 'not_a_number',
      };

      final ValidationResult result = validator.validate(data);
      expect(result.isValid, isFalse);
      expect(result.typeErrors.first.field, 'density');
    });

    test('validates color format', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'primary_color': '#FF00', // Invalid - not 6 or 8 hex chars
      };

      final ValidationResult result = validator.validate(data);
      expect(result.isValid, isFalse);

      final bool hasColorError = result.errors.any(
        (ValidationError e) =>
            e.field == 'primary_color' &&
            e.type == ValidationErrorType.invalidValue,
      );
      expect(hasColorError, isTrue);
    });

    test('validates valid color formats', () {
      final Map<String, dynamic> dataRgb = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'primary_color': '#FF0000',
      };

      final Map<String, dynamic> dataRgba = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'primary_color': '#FF0000FF',
      };

      expect(validator.validate(dataRgb).isValid, isTrue);
      expect(validator.validate(dataRgba).isValid, isTrue);
    });

    test('validates enum array', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'tags': <String>['glitter', 'invalid_tag'],
      };

      final ValidationResult result = validator.validate(data);
      expect(result.isValid, isFalse);

      final bool hasTagsError = result.errors.any(
        (ValidationError e) => e.field == 'tags',
      );
      expect(hasTagsError, isTrue);
    });

    test('validates UUID format', () {
      final Map<String, dynamic> validData = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'instance_uuid': '550e8400-e29b-41d4-a716-446655440000',
      };

      final Map<String, dynamic> invalidData = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'instance_uuid': 'not-a-valid-uuid',
      };

      expect(validator.validate(validData).isValid, isTrue);
      expect(validator.validate(invalidData).isValid, isFalse);
    });

    test('allows unknown fields by default', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'unknown_future_field': 'some value',
      };

      final ValidationResult result = validator.validate(data);
      expect(result.isValid, isTrue);
    });

    test('can reject unknown fields', () {
      final JsonValidator strictValidator = JsonValidator(
        fields: mainFields,
        allowUnknownFields: false,
      );

      final Map<String, dynamic> data = <String, dynamic>{
        'material_class': 'FFF',
        'material_type': 'PLA',
        'unknown_future_field': 'some value',
      };

      final ValidationResult result = strictValidator.validate(data);
      expect(result.isValid, isFalse);
      expect(result.errors.first.type, ValidationErrorType.unknownField);
    });
  });
}
