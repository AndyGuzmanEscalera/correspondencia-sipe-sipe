import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/inbox_entry_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/mock_inbox_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/sent_entry_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/inbox_entry_view.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/mock_inbox_body.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/sent_entry_view.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({required this.inboxType, super.key});

  final InboxType inboxType;

  String get _title {
    return switch (inboxType) {
      InboxType.inbox => 'Bandeja de entrada',
      InboxType.received => 'Recibidos',
      InboxType.sent => 'Enviados',
      InboxType.observed => 'Observados',
      InboxType.archived => 'Archivados',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (inboxType == InboxType.inbox) {
      return BlocProvider(
        create: (_) => getIt<InboxEntryCubit>(),
        child: const InboxEntryView(),
      );
    }

    if (inboxType == InboxType.sent) {
      return BlocProvider(
        create: (_) => getIt<SentEntryCubit>(),
        child: const SentEntryView(),
      );
    }

    return BlocProvider(
      create: (_) => MockInboxCubit(inboxType: inboxType)..init(),
      child: MockInboxView(title: _title),
    );
  }
}
