import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/cubit/users_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/views/users_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<UsersCubit, UsersState>().listen(),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<UsersCubit>().get();
        },
        child: const UsersBody(),
      ),
    );
  }
}
