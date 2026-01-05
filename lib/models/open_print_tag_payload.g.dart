// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_print_tag_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OpenPrintTagPayloadCWProxy {
  OpenPrintTagPayload data(OpenPrintTagData data);

  OpenPrintTagPayload unknownFields(UnknownFields? unknownFields);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `OpenPrintTagPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OpenPrintTagPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  OpenPrintTagPayload call({
    OpenPrintTagData data,
    UnknownFields? unknownFields,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOpenPrintTagPayload.copyWith(...)` or call `instanceOfOpenPrintTagPayload.copyWith.fieldName(value)` for a single field.
class _$OpenPrintTagPayloadCWProxyImpl implements _$OpenPrintTagPayloadCWProxy {
  const _$OpenPrintTagPayloadCWProxyImpl(this._value);

  final OpenPrintTagPayload _value;

  @override
  OpenPrintTagPayload data(OpenPrintTagData data) => call(data: data);

  @override
  OpenPrintTagPayload unknownFields(UnknownFields? unknownFields) =>
      call(unknownFields: unknownFields);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `OpenPrintTagPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OpenPrintTagPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  OpenPrintTagPayload call({
    Object? data = const $CopyWithPlaceholder(),
    Object? unknownFields = const $CopyWithPlaceholder(),
  }) {
    return OpenPrintTagPayload(
      data: data == const $CopyWithPlaceholder() || data == null
          ? _value.data
          // ignore: cast_nullable_to_non_nullable
          : data as OpenPrintTagData,
      unknownFields: unknownFields == const $CopyWithPlaceholder()
          ? _value.unknownFields
          // ignore: cast_nullable_to_non_nullable
          : unknownFields as UnknownFields?,
    );
  }
}

extension $OpenPrintTagPayloadCopyWith on OpenPrintTagPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOpenPrintTagPayload.copyWith(...)` or `instanceOfOpenPrintTagPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OpenPrintTagPayloadCWProxy get copyWith =>
      _$OpenPrintTagPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenPrintTagPayload _$OpenPrintTagPayloadFromJson(Map<String, dynamic> json) =>
    OpenPrintTagPayload(
      data: OpenPrintTagData.fromJson(json['data'] as Map<String, dynamic>),
      unknownFields: json['unknown_fields'] == null
          ? null
          : UnknownFields.fromJson(
              json['unknown_fields'] as Map<String, dynamic>?,
            ),
    );

Map<String, dynamic> _$OpenPrintTagPayloadToJson(
  OpenPrintTagPayload instance,
) => <String, dynamic>{
  'data': instance.data.toJson(),
  'unknown_fields': instance.unknownFields?.toJson(),
};
