import 'package:equatable/equatable.dart';

class DialogMessage extends Equatable {
  const DialogMessage({
    required this.message,
    this.title,
    this.showSuccess = true,
    this.showError = true,
    this.showLoading = true,
    this.pop = true,
  });

  const DialogMessage.empty()
      : message = '',
        title = null,
        showSuccess = true,
        showError = true,
        showLoading = true,
        pop = true;

  final String? title;
  final String message;
  final bool showSuccess;
  final bool showError;
  final bool showLoading;
  final bool pop;

  @override
  List<Object?> get props =>
      [message, title, showSuccess, showError, showLoading, pop];
}
