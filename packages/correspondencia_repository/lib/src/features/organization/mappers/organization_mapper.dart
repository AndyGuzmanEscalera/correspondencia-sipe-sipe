import 'package:correspondencia_api/correspondencia_api.dart';

import '../entities/organizational_unit.dart';

extension OrganizationalUnitResponseMapper on OrganizationalUnitResponse {
  OrganizationalUnit toEntity() =>
      OrganizationalUnit(id: id, code: code, name: name);
}

extension UnitUserResponseMapper on UnitUserResponse {
  UnitUser toEntity() =>
      UnitUser(id: id, username: username, displayName: displayName);
}
