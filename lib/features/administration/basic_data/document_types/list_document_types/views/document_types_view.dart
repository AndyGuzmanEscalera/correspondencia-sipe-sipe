import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/views/document_types_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentTypesView extends StatelessWidget {
  const DocumentTypesView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<DocumentTypesCubit, DocumentTypesState>().listen(),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<DocumentTypesCubit>().get();
        },
        child: const DocumentTypesBody(),
      ),
    );
  }
}
