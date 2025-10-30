import 'dart:typed_data';

import 'package:open_print_tag/open_print_tag.dart';
import 'package:test/test.dart';

void main() {
  late OpenPrintTagParser parser;

  setUp(() {
    parser = OpenPrintTagParser.create();
  });

  group('updateAux', () {
    test('updates AUX section in existing payload', () async {
      const OpenPrintTagData initialData = OpenPrintTagData(
        main: OpenPrintTagMainData(materialClass: 'FFF', materialType: 'PLA'),
        aux: OpenPrintTagAuxData(consumedWeight: 100.0, workgroup: 'Initial'),
      );

      final Uint8List payload = parser.encode(initialData, size: 320);
      final OpenPrintTagData decoded = await parser.decode(payload);

      expect(decoded.aux!.consumedWeight, 100.0);
      expect(decoded.aux!.workgroup, 'Initial');

      const OpenPrintTagAuxData updatedAux = OpenPrintTagAuxData(
        consumedWeight: 250.5,
        workgroup: 'Updated',
      );

      final Uint8List updatedPayload = await parser.updateAux(
        payload,
        updatedAux,
      );

      final OpenPrintTagData decodedUpdated = await parser.decode(
        updatedPayload,
      );

      expect(decodedUpdated.main!.materialClass, 'FFF');
      expect(decodedUpdated.aux!.consumedWeight, 250.5);
      expect(decodedUpdated.aux!.workgroup, 'Updated');
    });

    test('throws when AUX data exceeds allocated size', () async {
      const OpenPrintTagData initialData = OpenPrintTagData(
        main: OpenPrintTagMainData(materialClass: 'FFF', materialType: 'PLA'),
      );

      final Uint8List payload = parser.encode(initialData, size: 100);

      final OpenPrintTagAuxData tooLarge = OpenPrintTagAuxData(
        consumedWeight: 1.0,
        workgroup: 'A' * 500,
        generalPurposeRangeUser: 'B' * 500,
      );

      expect(() => parser.updateAux(payload, tooLarge), throwsArgumentError);
    });

    test('updates only AUX without changing MAIN', () async {
      const OpenPrintTagData initialData = OpenPrintTagData(
        main: OpenPrintTagMainData(
          materialClass: 'FFF',
          materialType: 'PLA',
          minPrintTemperature: 210,
        ),
        aux: OpenPrintTagAuxData(consumedWeight: 0.0),
      );

      final Uint8List payload = parser.encode(initialData, size: 320);

      const OpenPrintTagAuxData updatedAux = OpenPrintTagAuxData(
        consumedWeight: 500.0,
      );

      final Uint8List updatedPayload = await parser.updateAux(
        payload,
        updatedAux,
      );

      final OpenPrintTagData decodedUpdated = await parser.decode(
        updatedPayload,
      );

      expect(decodedUpdated.main!.materialClass, 'FFF');
      expect(decodedUpdated.main!.materialType, 'PLA');
      expect(decodedUpdated.main!.minPrintTemperature, 210);
      expect(decodedUpdated.aux!.consumedWeight, 500.0);
      expect(updatedPayload.length, payload.length);
    });
  });
}
