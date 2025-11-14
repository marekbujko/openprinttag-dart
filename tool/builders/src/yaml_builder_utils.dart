import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:yaml/yaml.dart';

/// Shared utilities for YAML code generation.
class YamlBuilderUtils {
  YamlBuilderUtils._();

  static final DartFormatter _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  static final DartEmitter _emitter = DartEmitter.scoped(
    orderDirectives: true,
    useNullSafetySyntax: true,
  );

  static final RegExp _identifierBoundary = RegExp(r'[_\-\s]+');

  /// Formats Dart source, returns original if formatting fails.
  static String formatSource(String source) {
    try {
      return _formatter.format(source);
    } catch (_) {
      return source;
    }
  }

  /// Flattens YAML nodes to native Dart types, optionally filters out keys.
  static dynamic flattenYaml(
    dynamic node, {
    Set<String> excludedKeys = const <String>{},
  }) {
    if (node is YamlMap) {
      return <String, dynamic>{
        for (final MapEntry<dynamic, dynamic> entry in node.entries)
          if (!excludedKeys.contains(entry.key.toString()))
            entry.key.toString(): flattenYaml(
              entry.value,
              excludedKeys: excludedKeys,
            ),
      };
    }
    if (node is YamlList) {
      return node
          .map(
            (dynamic value) => flattenYaml(value, excludedKeys: excludedKeys),
          )
          .toList();
    }
    if (node is YamlScalar) {
      return node.value;
    }
    return node;
  }

  /// Converts value to code_builder Expression for const generation.
  static Expression toLiteral(dynamic value) => switch (value) {
    null => literalNull,
    final bool boolValue => literalBool(boolValue),
    final num numValue => literalNum(numValue),
    final String stringValue => literalString(stringValue),
    final List<dynamic> listValue => literalConstList(
      listValue.map(toLiteral).toList(),
    ),
    final Map<dynamic, dynamic> mapValue =>
      literalConstMap(<Expression, Expression>{
        for (final MapEntry<dynamic, dynamic> entry in mapValue.entries)
          literalString(entry.key.toString()): toLiteral(entry.value),
      }),
    _ => literalNull,
  };

  /// Infers Dart type from value. Mixed-type collections become Object?.
  static Reference inferTypeReference(dynamic value) {
    if (value is List<dynamic>) {
      return _inferListType(value);
    }
    if (value is Map<dynamic, dynamic>) {
      return _inferMapType(value);
    }
    if (value is int) {
      return _type(symbol: 'int');
    }
    if (value is double) {
      return _type(symbol: 'double');
    }
    if (value is bool) {
      return _type(symbol: 'bool');
    }
    if (value is String) {
      return _type(symbol: 'String');
    }
    return _nullableObject;
  }

  /// Infers type and returns as string.
  static String inferTypeCode(dynamic value) {
    return referenceToCode(inferTypeReference(value));
  }

  /// Converts spec to Dart code string using shared emitter.
  static String referenceToCode(Spec spec) {
    final StringBuffer buffer = StringBuffer();
    spec.accept(_emitter, buffer);
    return buffer.toString();
  }

  /// Makes a type reference nullable.
  static Reference makeNullable(Reference reference) {
    if (reference is TypeReference) {
      final TypeReferenceBuilder builder = reference.toBuilder();
      builder.isNullable = true;
      return builder.build();
    }
    return _type(
      symbol: reference.symbol ?? 'Object',
      url: reference.url,
      isNullable: true,
      bound: reference is TypeReference ? reference.bound : null,
      types: reference is TypeReference ? reference.types : null,
    );
  }

  /// Deep comparison of type references (symbol, nullability, type args).
  static bool referencesEqual(Reference a, Reference b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    if (a.symbol != b.symbol || a.url != b.url) {
      return false;
    }
    if (a is TypeReference && b is TypeReference) {
      if (a.isNullable != b.isNullable ||
          a.types.length != b.types.length ||
          (a.bound != null) != (b.bound != null)) {
        return false;
      }
      if (a.bound != null && b.bound != null) {
        if (!referencesEqual(a.bound!, b.bound!)) {
          return false;
        }
      }
      for (int i = 0; i < a.types.length; i++) {
        if (!referencesEqual(a.types[i], b.types[i])) {
          return false;
        }
      }
    }
    return true;
  }

  /// Sanitizes string to valid Dart identifier.
  static String sanitizeIdentifier(String name, {String fallback = 'value'}) {
    String sanitized = name
        .replaceAll(RegExp(r'[^\w]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (sanitized.isEmpty) {
      sanitized = fallback;
    }
    if (RegExp(r'^\d').hasMatch(sanitized)) {
      sanitized = '_$sanitized';
    }
    return sanitized;
  }

  /// Converts to lowerCamelCase (e.g. 'field_name' → 'fieldName').
  static String toLowerCamelCase(String value, {String fallback = 'value'}) {
    final List<String> segments = _splitIntoSegments(value);
    if (segments.isEmpty) {
      return fallback;
    }

    final String first = segments.first.toLowerCase();
    final Iterable<String> rest = segments
        .skip(1)
        .map(
          (String segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        );

    return sanitizeIdentifier('$first${rest.join()}', fallback: fallback);
  }

  /// Converts to UpperCamelCase (e.g. 'tags_enum' → 'TagsEnum').
  static String toUpperCamelCase(String value, {String fallback = 'Value'}) {
    final List<String> segments = _splitIntoSegments(value);
    if (segments.isEmpty) {
      return fallback;
    }

    final String joined = segments
        .map(
          (String segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join();

    return sanitizeIdentifier(joined, fallback: fallback);
  }

  static List<String> _splitIntoSegments(String value) {
    final String normalized = value
        .replaceAll(RegExp(r'[^\w\s-]+'), ' ')
        .trim();
    return normalized
        .split(_identifierBoundary)
        .where((String segment) => segment.isNotEmpty)
        .toList();
  }

  static final Reference _nullableObject = _type(
    symbol: 'Object',
    isNullable: true,
  );

  static Reference _inferListType(List<dynamic> value) {
    if (value.isEmpty) {
      return _listOf(_nullableObject);
    }

    final List<dynamic> nonNullItems = value.where((dynamic element) {
      return element != null;
    }).toList();

    if (nonNullItems.isEmpty) {
      return _listOf(_nullableObject);
    }

    final Reference candidate = inferTypeReference(nonNullItems.first);
    final bool hasMixedTypes = nonNullItems
        .skip(1)
        .map(inferTypeReference)
        .any((Reference ref) => !referencesEqual(candidate, ref));

    if (hasMixedTypes) {
      return _listOf(_nullableObject);
    }

    final bool hasNulls = nonNullItems.length != value.length;
    final Reference elementType = hasNulls
        ? makeNullable(candidate)
        : candidate;

    return _listOf(elementType);
  }

  static Reference _inferMapType(Map<dynamic, dynamic> value) {
    if (value.isEmpty) {
      return _mapOf(
        keyType: _type(symbol: 'String'),
        valueType: _nullableObject,
      );
    }

    final bool allStringKeys = value.keys.every((dynamic key) {
      return key is String;
    });

    final Iterable<dynamic> values = value.values;
    final List<dynamic> nonNullValues = values.where((dynamic element) {
      return element != null;
    }).toList();

    if (nonNullValues.isEmpty) {
      return _mapOf(
        keyType: allStringKeys ? _type(symbol: 'String') : _nullableObject,
        valueType: _nullableObject,
      );
    }

    final Reference candidate = inferTypeReference(nonNullValues.first);
    final bool hasMixedTypes = nonNullValues
        .skip(1)
        .map(inferTypeReference)
        .any((Reference ref) => !referencesEqual(candidate, ref));

    final bool hasNulls = nonNullValues.length != values.length;
    final Reference valueType;
    if (hasMixedTypes) {
      valueType = _nullableObject;
    } else if (hasNulls) {
      valueType = makeNullable(candidate);
    } else {
      valueType = candidate;
    }

    return _mapOf(
      keyType: allStringKeys ? _type(symbol: 'String') : _nullableObject,
      valueType: valueType,
    );
  }

  static TypeReference _listOf(Reference elementType) {
    return TypeReference(
      (TypeReferenceBuilder builder) => builder
        ..symbol = 'List'
        ..types.add(elementType),
    );
  }

  static TypeReference _mapOf({
    required Reference keyType,
    required Reference valueType,
  }) {
    return TypeReference(
      (TypeReferenceBuilder builder) => builder
        ..symbol = 'Map'
        ..types.addAll(<Reference>[keyType, valueType]),
    );
  }

  static TypeReference _type({
    required String symbol,
    String? url,
    bool isNullable = false,
    Reference? bound,
    Iterable<Reference>? types,
  }) {
    return TypeReference((TypeReferenceBuilder builder) {
      builder
        ..symbol = symbol
        ..isNullable = isNullable;
      if (url != null) {
        builder.url = url;
      }
      if (bound != null) {
        builder.bound = bound;
      }
      if (types != null) {
        builder.types.addAll(types);
      }
    });
  }

  /// Generates header comment for generated files.
  static String generateHeader(String sourcePath) {
    return <String>[
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
      '// Source: $sourcePath',
      '',
    ].join('\n');
  }

  /// Generates import statements.
  static String generateImports(Iterable<String> imports) {
    if (imports.isEmpty) {
      return '';
    }
    return imports.map((String import) => "import '$import';").join('\n') +
        '\n';
  }
}
