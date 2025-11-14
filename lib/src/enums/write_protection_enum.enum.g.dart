// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: data-submodule/data/write_protection_enum.yaml
enum WriteProtectionEnum {
  no(key: 0),
  irreversible(key: 1),
  protect_page_unlockable(key: 2);

  final int key;

  const WriteProtectionEnum({required this.key});

  static WriteProtectionEnum byKey(int key) =>
      values.firstWhere((e) => e.key == key);
}
