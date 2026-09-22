class CreateCorrespondenceRequest {
  const CreateCorrespondenceRequest({
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

  Map<String, dynamic> toJson() => {
        'correspondence_type': correspondenceType,
        'document_type_id': documentTypeId,
        'subject': subject,
        'priority': priority,
        if (reference != null) 'reference': reference,
        if (senderName != null) 'sender_name': senderName,
        if (senderDocument != null) 'sender_document': senderDocument,
        if (senderContact != null) 'sender_contact': senderContact,
        if (originDescription != null) 'origin_description': originDescription,
        'initial_to_unit_id': initialToUnitId,
        if (initialToUserId != null) 'initial_to_user_id': initialToUserId,
        if (initialInstruction != null) 'initial_instruction': initialInstruction,
      };
}
