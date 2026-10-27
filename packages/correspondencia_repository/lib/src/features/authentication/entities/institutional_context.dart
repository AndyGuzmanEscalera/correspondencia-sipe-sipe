import 'package:equatable/equatable.dart';

/// Institutional identity linked to the authenticated user (from /auth/me).
class InstitutionalContext extends Equatable {
  const InstitutionalContext({
    required this.employeeId,
    required this.employeeName,
    this.documentNumber,
    this.positionId,
    this.positionName,
    this.unitId,
    this.unitName,
    this.hierarchyId,
    this.hierarchyCode,
    this.hierarchyName,
    this.hierarchyRank,
    this.hierarchyIsActive,
  });

  final String employeeId;
  final String employeeName;
  final String? documentNumber;
  final String? positionId;
  final String? positionName;
  final String? unitId;
  final String? unitName;
  final String? hierarchyId;
  final String? hierarchyCode;
  final String? hierarchyName;
  final int? hierarchyRank;
  final bool? hierarchyIsActive;

  String? get desktopSubtitle {
    final parts = <String>[
      if (positionName != null && positionName!.trim().isNotEmpty)
        positionName!.trim(),
      if (unitName != null && unitName!.trim().isNotEmpty) unitName!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String? get mobileSubtitle {
    if (unitName != null && unitName!.trim().isNotEmpty) {
      return unitName!.trim();
    }
    return desktopSubtitle;
  }

  @override
  List<Object?> get props => [
        employeeId,
        employeeName,
        documentNumber,
        positionId,
        positionName,
        unitId,
        unitName,
        hierarchyId,
        hierarchyCode,
        hierarchyName,
        hierarchyRank,
        hierarchyIsActive,
      ];
}
