import 'dart:convert';
import 'package:open_print_tag/constants.dart';
import 'package:uuid/uuid.dart';

class OpenPrintTagUuidGenerator {
  static const Uuid _uuid = Uuid();

  static String buildBrandUuid(String brandName) =>
      _uuid.v5(OpenPrintTagConstants.uuidNamespaceBrand.toString(), brandName);

  static String buildMaterialUuid(String brandUuid, String materialName) =>
      _uuid.v5(
        OpenPrintTagConstants.uuidNamespaceMaterial.toString(),
        '$brandUuid$materialName',
      );

  static String buildPackageUuid(String brandUuid, Object gtin) => _uuid.v5(
    OpenPrintTagConstants.uuidNamespacePackage.toString(),
    '$brandUuid$gtin',
  );

  static String buildInstanceUuid(String brandUuid, List<int> nfcUidBytes) =>
      _uuid.v5(
        OpenPrintTagConstants.uuidNamespaceInstance.toString(),
        brandUuid + utf8.decode(nfcUidBytes, allowMalformed: true),
      );
}
