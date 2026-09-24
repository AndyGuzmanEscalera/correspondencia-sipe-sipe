import 'package:equatable/equatable.dart';

class PendingAttachment extends Equatable {
  const PendingAttachment({
    required this.filename,
    required this.bytes,
    this.mimeType,
  });

  final String filename;
  final List<int> bytes;
  final String? mimeType;

  @override
  List<Object?> get props => [filename, bytes, mimeType];
}
