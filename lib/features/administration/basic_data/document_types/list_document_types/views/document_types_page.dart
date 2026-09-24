import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/views/document_types_view.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentTypesPage extends StatelessWidget {
  const DocumentTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DocumentTypesCubit>(),
      child: const DocumentTypesView(),
    );
  }
}
