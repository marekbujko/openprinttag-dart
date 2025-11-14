// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: data-submodule/data/material_class_enum.yaml
enum MaterialClassEnum {
  FFF(key: 0),
  SLA(key: 1);

  final int key;

  const MaterialClassEnum({required this.key});

  static MaterialClassEnum byKey(int key) =>
      values.firstWhere((e) => e.key == key);
}
