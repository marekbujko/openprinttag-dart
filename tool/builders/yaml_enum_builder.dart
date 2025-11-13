import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:yaml/yaml.dart';

const Set<String> _enumBasenames = <String>{
  'tags_enum',
  'tag_categories_enum',
  'write_protection_enum',
  'material_type_enum',
  'material_class_enum',
};

Builder yamlEnumBuilder([BuilderOptions? _]) => _YamlEnumBuilder();

class _YamlEnumBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    'data-submodule/data/material_class_enum.yaml': <String>[
      'lib/src/enums/material_class_enum.enum.g.dart',
    ],
    'data-submodule/data/material_type_enum.yaml': <String>[
      'lib/src/enums/material_type_enum.enum.g.dart',
    ],
    'data-submodule/data/tag_categories_enum.yaml': <String>[
      'lib/src/enums/tag_categories_enum.enum.g.dart',
    ],
    'data-submodule/data/tags_enum.yaml': <String>[
      'lib/src/enums/tags_enum.enum.g.dart',
    ],
    'data-submodule/data/write_protection_enum.yaml': <String>[
      'lib/src/enums/write_protection_enum.enum.g.dart',
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final AssetId inputId = buildStep.inputId;
    if (!inputId.path.startsWith('data-submodule/data/')) {
      return;
    }

    final String basename = inputId.path
        .split('/')
        .last
        .replaceFirst(RegExp(r'\.(yaml|yml)$'), '');
    if (!_enumBasenames.contains(basename)) {
      // Not one of the targeted enum YAMLs; skip.
      return;
    }

    final String content = await buildStep.readAsString(inputId);
    final dynamic raw = loadYaml(content);
    if (raw is! YamlList) {
      return;
    }

    final List<Map<String, Object?>> items = raw
        .map((dynamic e) => _flattenYaml(e))
        .whereType<Map<String, Object?>>()
        .toList();

    final AssetId outputId = AssetId(
      inputId.package,
      'lib/src/enums/$basename.enum.g.dart',
    );

    final String source = _generateEnumSource(inputId.path, basename, items);
    await buildStep.writeAsString(outputId, _formatSource(source));
  }

  String _generateEnumSource(
    String sourcePath,
    String basename,
    List<Map<String, Object?>> items,
  ) {
    final DartEmitter emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final String enumName = _toTypeName(basename);

    // Collect necessary imports
    final Set<String> imports = <String>{};

    if (items.isEmpty) {
      final StringBuffer emptyOut = StringBuffer();
      emptyOut.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
      emptyOut.writeln('// Source: $sourcePath');
      emptyOut.writeln('');
      emptyOut.writeln('enum $enumName { }');
      return emptyOut.toString();
    }

    final StringBuffer out = StringBuffer();

    // Determine union of keys across items
    final Set<String> yamlKeys = <String>{};
    for (final Map<String, Object?> it in items) {
      yamlKeys.addAll(it.keys.cast<String>());
    }

    // We never generate fields for 'deprecated'
    yamlKeys.remove('deprecated');

    // Collect field infos
    final List<_FieldInfo> fields = <_FieldInfo>[];

    final bool hasKey = yamlKeys.contains('key');
    if (hasKey) {
      fields.add(
        _FieldInfo(
          yamlKey: 'key',
          fieldName: 'key',
          type: 'int',
          isNullable: false,
          isPositional: false, // Changed to named parameter
        ),
      );
      yamlKeys.remove('key');
    }

    // Check if we need 'name' field from YAML 'name' - only if any item's name differs from sanitized identifier
    bool needsNameField = false;
    for (final Map<String, Object?> it in items) {
      final String? nameValue = it['name'] as String?;
      if (nameValue == null) {
        continue;
      }

      final String? abbreviation = it['abbreviation'] as String?;
      final String valueIdent = abbreviation ?? _sanitizeIdentifier(nameValue);

      if (valueIdent != nameValue) {
        needsNameField = true;
        break;
      }
    }

    if (needsNameField) {
      fields.add(
        _FieldInfo(
          yamlKey: 'name',
          fieldName: 'name',
          type: 'String',
          isNullable: false,
          isPositional: false,
        ),
      );
    }
    yamlKeys.remove('name');

    // Infer other fields, use nullable if missing in any item
    for (final String key in yamlKeys) {
      // Infer type based on first non-null occurrence
      dynamic sample;
      bool seenNonNull = false;
      bool hasNullOrMissing = false;
      for (final Map<String, Object?> it in items) {
        if (!it.containsKey(key) || it[key] == null) {
          hasNullOrMissing = true;
          continue;
        }
        if (!seenNonNull) {
          seenNonNull = true;
          sample = it[key];
        }
      }
      String fieldName = _mapYamlKeyToFieldName(key);

      // Rename 'display_name' to 'name' for better API
      if (key == 'display_name') {
        fieldName = 'name';
      }

      // Special handling for enum references
      String typeStr;
      bool isEnumRef = false;
      String? refEnumType;

      if (key == 'implies' || key == 'hints') {
        // Self-referencing list (e.g., TagsEnum.implies -> List<TagsEnum>)
        typeStr = 'List<$enumName>';
        isEnumRef = true;
      } else {
        // Check if field should reference another enum
        final _EnumFieldConfig? enumRef = _getEnumReference(basename, key);
        if (enumRef != null) {
          typeStr = enumRef.enumType;
          isEnumRef = true;
          refEnumType = enumRef.enumType;
          imports.add(enumRef.importPath);
        } else {
          typeStr = seenNonNull ? _typeStringForValue(sample) : 'Object?';
        }
      }

      fields.add(
        _FieldInfo(
          yamlKey: key,
          fieldName: fieldName,
          type: hasNullOrMissing ? '$typeStr?' : typeStr,
          isNullable: hasNullOrMissing,
          isPositional: false,
          isEnumReference: isEnumRef,
          referencedEnumType: refEnumType,
        ),
      );
    }

    // Write imports at the beginning (after the header comment)
    final StringBuffer finalOut = StringBuffer();
    finalOut.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    finalOut.writeln('// Source: $sourcePath');
    finalOut.writeln('');
    for (final String import in imports) {
      finalOut.writeln("import '$import';");
    }
    if (imports.isNotEmpty) {
      finalOut.writeln('');
    }

    out.writeln('enum $enumName {');

    // Emit enum values
    for (final Map<String, Object?> it in items) {
      // Skip items without a name (e.g., some deprecated entries)
      final String? nameValue = it['name'] as String?;
      if (nameValue == null) {
        continue;
      }

      if (it['deprecated'] == true) {
        out.writeln('  @Deprecated(\'deprecated\')');
      }

      // Use 'abbreviation' as identifier if available, otherwise sanitize 'name'
      final String? abbreviation = it['abbreviation'] as String?;
      final String valueIdent = abbreviation ?? _sanitizeIdentifier(nameValue);

      final List<String> namedArgs = <String>[];
      for (final _FieldInfo f in fields) {
        final dynamic value = it[f.yamlKey];
        String argValue;

        if (f.isEnumReference && value != null) {
          if (value is List) {
            // Convert list of strings to list of enum references
            final List<String> enumRefs = <String>[];
            for (final dynamic item in value) {
              if (item is String) {
                enumRefs.add('$enumName.$item');
              }
            }
            argValue = 'const [${enumRefs.join(', ')}]';
          } else if (value is String && f.referencedEnumType != null) {
            // Single enum reference (e.g., category: MaterialClassEnum.FFF)
            argValue = '${f.referencedEnumType}.$value';
          } else {
            final Expression expr = _toLiteral(value);
            argValue = '${expr.accept(emitter)}';
          }
        } else {
          final Expression expr = _toLiteral(value);
          argValue = '${expr.accept(emitter)}';
        }

        namedArgs.add('${f.fieldName}: $argValue');
      }
      out.writeln('  $valueIdent(${namedArgs.join(', ')}),');
    }

    out.writeln(';');
    out.writeln('');

    // Emit fields
    for (final _FieldInfo f in fields) {
      out.writeln('  final ${f.type} ${f.fieldName};');
    }
    out.writeln('');

    // Emit constructor - all fields as named parameters for enhanced enum
    final String namedParams = fields
        .map(
          (_FieldInfo f) =>
              '${f.isNullable ? '' : 'required '}this.${f.fieldName}',
        )
        .join(', ');
    out.writeln('  const $enumName({$namedParams});');
    out.writeln('');

    // Lookup helpers
    if (hasKey) {
      out.writeln(
        '  static $enumName byKey(int key) => values.firstWhere((e) => e.key == key);',
      );
    }

    out.writeln('}');

    finalOut.write(out.toString());
    return finalOut.toString();
  }

  String _formatSource(String source) {
    try {
      return DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(source);
    } catch (_) {
      return source;
    }
  }
}

String _toTypeName(String name) {
  final List<String> parts = name
      .split(RegExp(r'[_\-\s]+'))
      .where((String s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'DataEnum';
  }
  final String pascal = parts
      .map((String s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
      .join();
  return pascal;
}

String _toCamel(String name) {
  final List<String> parts = name
      .split(RegExp(r'[_\-\s]+'))
      .where((String s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'value';
  }
  return parts.first.toLowerCase() +
      parts
          .skip(1)
          .map((String s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
          .join();
}

String _mapYamlKeyToFieldName(String yamlKey) {
  // Avoid conflict with Enum.name getter
  if (yamlKey == 'name') {
    return 'id';
  }
  return _toCamel(yamlKey);
}

String _sanitizeIdentifier(String name) {
  // Remove/replace characters that are not valid in Dart identifiers
  // Replace spaces, hyphens, and special chars with underscores
  String sanitized = name
      .replaceAll(RegExp(r'[^\w]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), ''); // trim leading/trailing underscores

  // If starts with a digit, prepend underscore
  if (sanitized.isNotEmpty && RegExp(r'^\d').hasMatch(sanitized)) {
    sanitized = '_$sanitized';
  }

  return sanitized.isEmpty ? 'value' : sanitized;
}

String _typeStringForValue(dynamic value) {
  if (value is int) {
    return 'int';
  }
  if (value is double) {
    return 'double';
  }
  if (value is bool) {
    return 'bool';
  }
  if (value is String) {
    return 'String';
  }
  if (value is List) {
    // Try to infer list element type from first non-null
    dynamic firstNonNull;
    for (final dynamic v in value) {
      if (v != null) {
        firstNonNull = v;
        break;
      }
    }
    final String inner = firstNonNull == null
        ? 'Object?'
        : _typeStringForValue(firstNonNull);
    return 'List<$inner>';
  }
  if (value is Map) {
    return 'Map<String, Object?>';
  }
  return 'Object?';
}

class _FieldInfo {
  _FieldInfo({
    required this.yamlKey,
    required this.fieldName,
    required this.type,
    required this.isNullable,
    required this.isPositional,
    this.isEnumReference = false,
    this.referencedEnumType,
  });

  final String yamlKey;
  final String fieldName;
  final String type;
  final bool isNullable;
  final bool isPositional;
  final bool isEnumReference;
  final String? referencedEnumType;
}

dynamic _flattenYaml(dynamic node) {
  if (node is YamlMap) {
    final List<MapEntry<String, dynamic>> entries =
        <MapEntry<String, dynamic>>[];
    for (final MapEntry<dynamic, dynamic> entry in node.entries) {
      final String key = entry.key.toString();
      if (key != 'description') {
        entries.add(MapEntry<String, dynamic>(key, _flattenYaml(entry.value)));
      }
    }
    return Map<String, dynamic>.fromEntries(entries);
  }
  if (node is YamlList) {
    return node.map(_flattenYaml).toList();
  }
  return node;
}

Expression _toLiteral(dynamic value) => switch (value) {
  null => literalNull,
  final bool boolValue => literalBool(boolValue),
  final num numValue => literalNum(numValue),
  final String stringValue => literalString(stringValue),
  final List<dynamic> listValue => literalConstList(
    listValue.map(_toLiteral).toList(),
  ),
  final Map<dynamic, dynamic> mapValue =>
    literalConstMap(<Expression, Expression>{
      for (final MapEntry<dynamic, dynamic> entry in mapValue.entries)
        literalString(entry.key.toString()): _toLiteral(entry.value),
    }),
  _ => literalNull,
};

/// Configuration for enum field references
class _EnumFieldConfig {
  const _EnumFieldConfig({required this.enumType, required this.importPath});

  final String enumType;
  final String importPath;
}

/// Maps enum basename and field name to their enum reference configuration
/// This centralizes all enum field reference logic in one place
const Map<String, Map<String, _EnumFieldConfig>> _enumFieldReferences =
    <String, Map<String, _EnumFieldConfig>>{
      'material_type_enum': <String, _EnumFieldConfig>{
        'category': _EnumFieldConfig(
          enumType: 'MaterialClassEnum',
          importPath: 'material_class_enum.enum.g.dart',
        ),
      },
      'tags_enum': <String, _EnumFieldConfig>{
        'category': _EnumFieldConfig(
          enumType: 'TagCategoriesEnum',
          importPath: 'tag_categories_enum.enum.g.dart',
        ),
      },
    };

/// Returns enum reference configuration for a specific field in a specific enum
_EnumFieldConfig? _getEnumReference(String basename, String fieldKey) {
  return _enumFieldReferences[basename]?[fieldKey];
}
