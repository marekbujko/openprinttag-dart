import 'dart:typed_data';
import 'package:cbor/cbor.dart';

class CborUtils {
  static Future<CborMap?> decodeCborMap(Uint8List data) async {
    try {
      final Stream<List<int>> stream = Stream<List<int>>.value(data);
      final CborValue decoded = await stream.transform(cbor.decoder).first;
      return decoded is CborMap ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static void removeNullValues(Map<String, dynamic> map) {
    map.removeWhere((String key, dynamic value) => value == null);
  }
}
