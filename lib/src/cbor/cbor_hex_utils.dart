import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart' as hex_convert;

class CborHexUtils {
  CborHexUtils._();

  static String bytesToHex(List<int> bytes) {
    return hex_convert.hex.encode(bytes);
  }

  static Uint8List hexToBytes(String hex) {
    final String cleaned = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    return Uint8List.fromList(hex_convert.hex.decode(cleaned));
  }

  static String intToHex(int value) {
    final List<int> bytes = cbor.encode(CborSmallInt(value));
    return bytesToHex(bytes);
  }

  static String cborValueToHex(CborValue value) {
    final List<int> bytes = cbor.encode(value);
    return bytesToHex(bytes);
  }

  static int hexToInt(String hex) {
    final Uint8List bytes = hexToBytes(hex);
    final CborValue value = cbor.decode(bytes);
    return (value as CborSmallInt).value;
  }

  static CborValue hexToCborValue(String hex) {
    final Uint8List bytes = hexToBytes(hex);
    return cbor.decode(bytes);
  }

  static Map<int, CborValue> hexMapToCborMap(Map<String, String> hexMap) {
    return hexMap.map(
      (String key, String value) =>
          MapEntry<int, CborValue>(hexToInt(key), hexToCborValue(value)),
    );
  }
}
