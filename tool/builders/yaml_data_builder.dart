// ignore_for_file: always_use_package_imports

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

import 'src/yaml_builder_utils.dart';

const Set<String> _excludedKeys = <String>{'description'};

/// Generates type-safe Dart constants from YAML field definitions.
Builder yamlDataBuilder([BuilderOptions? _]) => _YamlDataBuilder();

class _YamlDataBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    'data-submodule/data/aux_fields.yaml': <String>[
      'lib/src/data/aux_fields.data.g.dart',
    ],
    'data-submodule/data/main_fields.yaml': <String>[
      'lib/src/data/main_fields.data.g.dart',
    ],
    'data-submodule/data/meta_fields.yaml': <String>[
      'lib/src/data/meta_fields.data.g.dart',
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final AssetId inputId = buildStep.inputId;
    if (!inputId.path.startsWith('data-submodule/data/')) {
      return;
    }

    final String content = await buildStep.readAsString(inputId);
    final dynamic data = YamlBuilderUtils.flattenYaml(
      loadYaml(content),
      excludedKeys: _excludedKeys,
    );

    final String basename = inputId.path
        .split('/')
        .last
        .replaceFirst(RegExp(r'\.(yaml|yml)$'), '');
    final AssetId outputId = AssetId(
      inputId.package,
      'lib/src/data/$basename.data.g.dart',
    );

    final String source = _generateSource(inputId.path, basename, data);
    await buildStep.writeAsString(
      outputId,
      YamlBuilderUtils.formatSource(source),
    );
  }

  String _generateSource(String sourcePath, String basename, dynamic data) {
    final String identifier = YamlBuilderUtils.toLowerCamelCase(
      basename,
      fallback: 'data',
    );
    final String typeCode = YamlBuilderUtils.inferTypeCode(data);
    final String literalCode = YamlBuilderUtils.referenceToCode(
      YamlBuilderUtils.toLiteral(data),
    );

    return <String>[
      YamlBuilderUtils.generateHeader(sourcePath),
      'const $typeCode $identifier = $literalCode;',
    ].join('\n');
  }
}
