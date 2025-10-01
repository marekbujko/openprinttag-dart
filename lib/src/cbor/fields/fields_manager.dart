import 'package:cbor/cbor.dart';
import 'package:open_print_tag/src/cbor/fields/field_types.dart';

typedef AssetLoader = Future<String> Function(String assetPath);

class FieldsManager {
  final Map<int, Field> fieldsByKey = <int, Field>{};
  final Map<String, Field> fieldsByName = <String, Field>{};

  /// Creates a FieldsManager from generated data constants
  static FieldsManager fromData(
    List<Map<String, Object?>> fieldsData, {
    required Map<String, List<Map<String, Object?>>> enumsData,
  }) {
    final FieldsManager manager = FieldsManager();

    for (final Map<String, Object?> item in fieldsData) {
      if (item['deprecated'] == true) {
        continue;
      }

      final Field field = _createFieldFromData(item, enumsData);
      manager._addField(field);
    }

    return manager;
  }

  static Field _createFieldFromData(
    Map<String, Object?> config,
    Map<String, List<Map<String, Object?>>> enumsData,
  ) {
    final int key = config['key'] as int;
    final String name = config['name'] as String;
    final String type = config['type'] as String;
    final bool required = _parseRequired(config['required']);

    final FieldType fieldType = FieldType.fromString(type);

    return switch (fieldType) {
      FieldType.bool => BoolField(key: key, name: name, required: required),

      FieldType.int ||
      FieldType.timestamp => IntField(key: key, name: name, required: required),

      FieldType.number => NumberField(key: key, name: name, required: required),

      FieldType.string => StringField(
        key: key,
        name: name,
        maxLength: config['max_length'] as int,
        required: required,
      ),

      FieldType.enumeration => () {
        final String itemsFile = config['items_file'] as String;
        final String indexField = config['index_field'] as String? ?? 'key';
        final String nameField = config['name_field'] as String? ?? 'name';
        final Map<int, String> itemsByKey = _extractEnumItems(
          enumsData[itemsFile]!,
          indexField,
          nameField,
        );
        return EnumField(
          key: key,
          name: name,
          itemsByKey: itemsByKey,
          required: required,
        );
      }(),

      FieldType.enumArray => () {
        final String itemsFile = config['items_file'] as String;
        final String indexField = config['index_field'] as String? ?? 'key';
        final String nameField = config['name_field'] as String? ?? 'name';
        final Map<int, String> itemsByKey = _extractEnumItems(
          enumsData[itemsFile]!,
          indexField,
          nameField,
        );
        return EnumArrayField(
          key: key,
          name: name,
          itemsByKey: itemsByKey,
          required: required,
        );
      }(),

      FieldType.bytes => BytesField(
        key: key,
        name: name,
        maxLength: config['max_length'] as int?,
        required: required,
      ),

      FieldType.uuid => UuidField(key: key, name: name, required: required),
    };
  }

  static Map<int, String> _extractEnumItems(
    List<Map<String, Object?>> enumData,
    String indexField,
    String nameField,
  ) {
    final Map<int, String> items = <int, String>{};

    for (final Map<String, Object?> item in enumData) {
      final int key = item[indexField] as int;
      final String name = item[nameField] as String;

      if (items.containsKey(key)) {
        throw ArgumentError('Duplicate key $key in enum data');
      }

      items[key] = name;
    }

    return items;
  }

  static bool _parseRequired(dynamic value) {
    if (value == true) {
      return true;
    }
    if (value == 'recommended') {
      return false;
    }
    return false;
  }

  Map<String, dynamic> decode(Map<CborSmallInt, CborValue> data) {
    final Map<String, dynamic> result = <String, dynamic>{};

    for (final MapEntry<CborSmallInt, CborValue> entry in data.entries) {
      final int key = entry.key.value;
      final Field? field = fieldsByKey[key];

      if (field == null) {
        throw ArgumentError('Unknown field key: $key');
      }

      try {
        result[field.name] = field.decode(entry.value);
      } catch (e) {
        throw ArgumentError(
          'Error decoding field ${field.name} (key $key): $e',
        );
      }
    }

    return result;
  }

  void validate(Map<String, dynamic> data) {
    for (final Field field in fieldsByName.values) {
      if (!data.containsKey(field.name) || data[field.name] == null) {
        if (field.required) {
          throw ArgumentError('Missing required field: ${field.name}');
        }
      }
    }
  }

  Map<int, CborValue> encode(Map<String, dynamic> data) {
    validate(data);

    final Map<int, CborValue> result = <int, CborValue>{};

    for (final MapEntry<String, dynamic> entry in data.entries) {
      if (entry.value == null) {
        continue;
      }

      final Field? field = fieldsByName[entry.key];

      if (field == null) {
        throw ArgumentError('Unknown field name: ${entry.key}');
      }

      try {
        result[field.key] = field.encode(entry.value);
      } catch (e) {
        throw ArgumentError('Error encoding field ${entry.key}: $e');
      }
    }

    return result;
  }

  void _addField(Field field) {
    if (fieldsByKey.containsKey(field.key)) {
      throw ArgumentError('Duplicate field key: ${field.key}');
    }
    if (fieldsByName.containsKey(field.name)) {
      throw ArgumentError('Duplicate field name: ${field.name}');
    }
    fieldsByKey[field.key] = field;
    fieldsByName[field.name] = field;
  }
}
