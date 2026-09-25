import 'package:equatable/equatable.dart';

class Correspondence extends Equatable {
  const Correspondence({
    required this.id,
    required this.routeNumber,
    required this.routeYear,
    required this.routeSequence,
    this.documentNumber,
    required this.correspondenceType,
    required this.documentTypeCode,
    required this.documentTypeName,
    required this.subject,
    required this.priority,
    required this.status,
    this.currentUnitName,
    this.currentUserName,
    this.currentUserIsActive,
    this.cite,
    required this.registeredAt,
    this.reference,
    this.description,
    this.senderName,
    this.senderDocument,
    this.senderContact,
    this.originDescription,
    this.originUnitId,
    this.originUnitName,
    this.originUserId,
    this.originUserName,
    this.originEmployeeId,
    this.originEmployeeName,
    this.currentUnitId,
    this.currentUserId,
    this.createdByUsername,
  });

  final String id;
  final String routeNumber;
  final int routeYear;
  final int routeSequence;
  final String? documentNumber;
  final String correspondenceType;
  final String documentTypeCode;
  final String documentTypeName;
  final String subject;
  final String priority;
  final String status;
  final String? currentUnitName;
  final String? currentUserName;
  final bool? currentUserIsActive;
  final String? cite;
  final DateTime registeredAt;
  final String? reference;
  final String? description;
  final String? senderName;
  final String? senderDocument;
  final String? senderContact;
  final String? originDescription;
  final String? originUnitId;
  final String? originUnitName;
  final String? originUserId;
  final String? originUserName;
  final String? originEmployeeId;
  final String? originEmployeeName;
  final String? currentUnitId;
  final String? currentUserId;
  final String? createdByUsername;

  String get displayCite => cite ?? routeNumber;

  @override
  List<Object?> get props => [
        id,
        routeNumber,
        routeYear,
        routeSequence,
        documentNumber,
        correspondenceType,
        documentTypeCode,
        documentTypeName,
        subject,
        priority,
        status,
        currentUnitName,
        currentUserName,
        currentUserIsActive,
        cite,
        registeredAt,
        reference,
        description,
        senderName,
        senderDocument,
        senderContact,
        originDescription,
        originUnitId,
        originUnitName,
        originUserId,
        originUserName,
        originEmployeeId,
        originEmployeeName,
        currentUnitId,
        currentUserId,
        createdByUsername,
      ];
}

class CorrespondencePage extends Equatable {
  const CorrespondencePage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<Correspondence> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  @override
  List<Object?> get props => [items, page, pageSize, total, totalPages];
}
