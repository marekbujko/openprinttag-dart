import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:yaml/yaml.dart';

const Set<String> _excludedKeys = <String>{'description'};

Builder yamlDataBuilder([BuilderOptions? _]) => _YamlDataBuilder();

class _YamlDataBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    r'^data-submodule/data/{{}}.yaml': <String>[
      r'lib/src/data/{{}}.data.g.dart',
    ],
    r'^data-submodule/data/{{}}.yml': <String>[
      r'lib/src/data/{{}}.data.g.dart',
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final AssetId inputId = buildStep.inputId;
    if (!inputId.path.startsWith('data-submodule/data/')) {
      return;
    }

    final String content = await buildStep.readAsString(inputId);
    final dynamic data = _flattenYaml(loadYaml(content));

    final String basename = inputId.path
        .split('/')
        .last
        .replaceFirst(RegExp(r'\.(yaml|yml)$'), '');
    final AssetId outputId = AssetId(
      inputId.package,
      'lib/src/data/$basename.data.g.dart',
    );

    final String source = _generateSource(inputId.path, basename, data);
    await buildStep.writeAsString(outputId, _formatSource(source));
  }

  String _generateSource(String sourcePath, String basename, dynamic data) {
    final String identifier = _toIdentifier(basename);
    final Reference type = _inferType(data);
    final Expression literal = _toLiteral(data);
    final DartEmitter emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    return <String>[
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
      '// Source: $sourcePath',
      '',
      'const ${type.accept(emitter)} $identifier = ${literal.accept(emitter)};',
    ].join('\n');
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

String _toIdentifier(String name) {
  final List<String> parts = name
      .split(RegExp(r'[_\-\s]+'))
      .where((String s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'data';
  }

  return parts.first.toLowerCase() +
      parts
          .skip(1)
          .map((String s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
          .join();
}

dynamic _flattenYaml(dynamic node) {
  if (node is YamlMap) {
    final List<MapEntry<String, dynamic>> entries =
        <MapEntry<String, dynamic>>[];
    for (final MapEntry<dynamic, dynamic> entry in node.entries) {
      final String key = entry.key.toString();
      if (!_excludedKeys.contains(key)) {
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

Reference _inferType(dynamic value) {
  if (value is List) {
    if (value.isEmpty) {
      return TypeReference(
        (TypeReferenceBuilder builder) => builder
          ..symbol = 'List'
          ..types.add(refer('Object?')),
      );
    }
    return TypeReference(
      (TypeReferenceBuilder builder) => builder
        ..symbol = 'List'
        ..types.add(_inferType(value.first)),
    );
  }
  if (value is Map) {
    return TypeReference(
      (TypeReferenceBuilder builder) => builder
        ..symbol = 'Map'
        ..types.addAll(<Reference>[refer('String'), refer('Object?')]),
    );
  }
  if (value is int) {
    return refer('int');
  }
  if (value is double) {
    return refer('double');
  }
  if (value is bool) {
    return refer('bool');
  }
  if (value is String) {
    return refer('String');
  }
  return refer('Object?');
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
