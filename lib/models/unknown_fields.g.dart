// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unknown_fields.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UnknownFieldsCWProxy {
  UnknownFields meta(UnknownFieldsRegion? meta);

  UnknownFields main(UnknownFieldsRegion? main);

  UnknownFields aux(UnknownFieldsRegion? aux);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `UnknownFields(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UnknownFields(...).copyWith(id: 12, name: "My name")
  /// ```
  UnknownFields call({
    UnknownFieldsRegion? meta,
    UnknownFieldsRegion? main,
    UnknownFieldsRegion? aux,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUnknownFields.copyWith(...)` or call `instanceOfUnknownFields.copyWith.fieldName(value)` for a single field.
class _$UnknownFieldsCWProxyImpl implements _$UnknownFieldsCWProxy {
  const _$UnknownFieldsCWProxyImpl(this._value);

  final UnknownFields _value;

  @override
  UnknownFields meta(UnknownFieldsRegion? meta) => call(meta: meta);

  @override
  UnknownFields main(UnknownFieldsRegion? main) => call(main: main);

  @override
  UnknownFields aux(UnknownFieldsRegion? aux) => call(aux: aux);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `UnknownFields(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UnknownFields(...).copyWith(id: 12, name: "My name")
  /// ```
  UnknownFields call({
    Object? meta = const $CopyWithPlaceholder(),
    Object? main = const $CopyWithPlaceholder(),
    Object? aux = const $CopyWithPlaceholder(),
  }) {
    return UnknownFields(
      meta: meta == const $CopyWithPlaceholder()
          ? _value.meta
          // ignore: cast_nullable_to_non_nullable
          : meta as UnknownFieldsRegion?,
      main: main == const $CopyWithPlaceholder()
          ? _value.main
          // ignore: cast_nullable_to_non_nullable
          : main as UnknownFieldsRegion?,
      aux: aux == const $CopyWithPlaceholder()
          ? _value.aux
          // ignore: cast_nullable_to_non_nullable
          : aux as UnknownFieldsRegion?,
    );
  }
}

extension $UnknownFieldsCopyWith on UnknownFields {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUnknownFields.copyWith(...)` or `instanceOfUnknownFields.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UnknownFieldsCWProxy get copyWith => _$UnknownFieldsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnknownFields _$UnknownFieldsFromJson(Map<String, dynamic> json) =>
    UnknownFields(
      meta: (json['meta'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      main: (json['main'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      aux: (json['aux'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$UnknownFieldsToJson(UnknownFields instance) =>
    <String, dynamic>{
      'meta': instance.meta,
      'main': instance.main,
      'aux': instance.aux,
    };
