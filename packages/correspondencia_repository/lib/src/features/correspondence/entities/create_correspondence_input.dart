class CreateCorrespondenceInput {
  const CreateCorrespondenceInput({
    required this.correspondenceType,
    required this.documentTypeId,
    required this.subject,
    required this.priority,
    this.reference,
    this.senderName,
    this.senderDocument,
    this.senderContact,
    this.originDescription,
    required this.initialToUnitId,
    this.initialToUserId,
    this.initialInstruction,
  });

  final String correspondenceType;
  final String documentTypeId;
  final String subject;
  final String priority;
  final String? reference;
  final String? senderName;
  final String? senderDocument;
  final String? senderContact;
  final String? originDescription;
  final String initialToUnitId;
  final String? initialToUserId;
  final String? initialInstruction;
}

class DeriveCorrespondenceInput {
  const DeriveCorrespondenceInput({
    required this.toUnitId,
    this.toUserId,
    this.instruction,
    this.observation,
  });

  final String toUnitId;
  final String? toUserId;
  final String? instruction;
  final String? observation;
}
