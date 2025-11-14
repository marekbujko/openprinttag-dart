/// Models for enum field configuration during code generation.

class FieldInfo {
  FieldInfo({
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

class EnumFieldConfig {
  const EnumFieldConfig({required this.enumType, required this.importPath});

  final String enumType;
  final String importPath;
}
