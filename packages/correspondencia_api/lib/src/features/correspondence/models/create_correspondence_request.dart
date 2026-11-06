class CreateCorrespondenceRequest {
  const CreateCorrespondenceRequest({
    required this.correspondenceType,
    required this.documentTypeId,
    this.subject,
    required this.priority,
    this.reference,
    this.description,
    this.emissionDate,
    this.emissionTime,
    this.pageCount,
    this.originEmployeeId,
    this.senderName,
    this.senderDocument,
    this.enablePublicTracking = false,
    this.senderContact,
    this.originDescription,
    this.firstRecipientEmployeeId,
    required this.initialToUnitId,
    this.initialToUserId,
    this.initialInstruction,
  });

  final String correspondenceType;
  final String documentTypeId;
  final String? subject;
  final String priority;
  final String? reference;
  final String? description;
  final String? emissionDate;
  final String? emissionTime;
  final int? pageCount;
  final String? originEmployeeId;
  final String? senderName;
  final String? senderDocument;
  final bool enablePublicTracking;
  final String? senderContact;
  final String? originDescription;
  final String? firstRecipientEmployeeId;
  final String initialToUnitId;
  final String? initialToUserId;
  final String? initialInstruction;

  Map<String, dynamic> toJson() => {
        'correspondence_type': correspondenceType,
        'document_type_id': documentTypeId,
        if (subject != null) 'subject': subject,
        'priority': priority,
        if (reference != null) 'reference': reference,
        if (description != null) 'description': description,
        if (emissionDate != null) 'emission_date': emissionDate,
        if (emissionTime != null) 'emission_time': emissionTime,
        if (pageCount != null) 'page_count': pageCount,
        if (originEmployeeId != null) 'origin_employee_id': originEmployeeId,
        if (senderName != null) 'sender_name': senderName,
        if (senderDocument != null) 'sender_document': senderDocument,
        if (enablePublicTracking) 'enable_public_tracking': true,
        if (senderContact != null) 'sender_contact': senderContact,
        if (originDescription != null) 'origin_description': originDescription,
        if (firstRecipientEmployeeId != null)
          'first_recipient_employee_id': firstRecipientEmployeeId,
        'initial_to_unit_id': initialToUnitId,
        if (initialToUserId != null) 'initial_to_user_id': initialToUserId,
        if (initialInstruction != null)
          'initial_instruction': initialInstruction,
      };
}
