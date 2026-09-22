import 'package:equatable/equatable.dart';

class AdminPage<T> extends Equatable {
  const AdminPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  @override
  List<Object?> get props => [items, page, pageSize, total, totalPages];
}
