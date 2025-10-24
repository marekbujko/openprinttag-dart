import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:open_print_tag/constants.dart';
import 'package:uuid/uuid.dart';

class OpenPrintTagUuidGenerator {
  static const Uuid _uuid = Uuid();

  static String _uuidV5FromBytes(String namespace, List<int> data) {
    final List<int> combined = <int>[
      ...Uuid.parseAsByteList(namespace),
      ...data,
    ];
    final List<int> hashBytes = sha1.convert(combined).bytes.toList();
    hashBytes[6] = (hashBytes[6] & 0x0F) | 0x50;
    hashBytes[8] = (hashBytes[8] & 0x3F) | 0x80;
    return Uuid.unparse(hashBytes.sublist(0, 16));
  }

  static String buildBrandUuid(String brandName) =>
      _uuid.v5(OpenPrintTagConstants.uuidNamespaceBrand.toString(), brandName);

  static String buildMaterialUuid(String brandUuid, String materialName) =>
      _uuidV5FromBytes(
        OpenPrintTagConstants.uuidNamespaceMaterial.toString(),
        <int>[...Uuid.parseAsByteList(brandUuid), ...utf8.encode(materialName)],
      );

  static String buildPackageUuid(String brandUuid, Object gtin) =>
      _uuidV5FromBytes(
        OpenPrintTagConstants.uuidNamespacePackage.toString(),
        <int>[
          ...Uuid.parseAsByteList(brandUuid),
          ...utf8.encode(gtin.toString()),
        ],
      );

  static String buildInstanceUuid(String brandUuid, List<int> nfcUidBytes) =>
      _uuidV5FromBytes(
        OpenPrintTagConstants.uuidNamespaceInstance.toString(),
        <int>[...Uuid.parseAsByteList(brandUuid), ...nfcUidBytes],
      );
}
