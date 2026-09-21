import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/authentication/sign_in/cubit/sign_in_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/authentication/sign_in/helpers/sign_in_form_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/get_it.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/auth_split_layout.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignInCubit>(),
      child: SignInFormInherited(
        child: Builder(
          builder: (context) {
            final inherited = SignInFormInherited.of(context);
            return FullWidgetGeneric(
              onDispose: inherited.dispose,
              child: const SignInView(),
            );
          },
        ),
      ),
    );
  }
}

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final appSession = context.read<AppSessionCubit>();
    return MultiBlocListener(
      listeners: [
        ListenerPro<SignInCubit, SignInState>().listen(),
        ListenerPro<SignInCubit, SignInState>().event(
          onSuccess: (state) {
            final user = state.userSession;
            if (user != null) {
              appSession.onSignedIn(user);
              context.read<SideMenuCubit>().init();
              context.go(Routes.home);
            }
          },
        ),
      ],
      child: const SignInBody(),
    );
  }
}

class SignInBody extends StatelessWidget {
  const SignInBody({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = SignInFormInherited.of(context);
    final signInCubit = context.read<SignInCubit>();

    return AuthSplitLayout(
      heroTitle: 'Gestión institucional\nmoderna y trazable',
      heroSubtitle:
          'Panel administrativo para registrar, derivar y dar seguimiento a la correspondencia municipal.',
      heroBullets: const [
        'Bandejas operativas por funcionario',
        'Historial completo de hoja de ruta',
        'Reportes y control institucional',
      ],
      form: AuthFormCard(
        title: 'Iniciar sesión',
        subtitle: 'Acceso reservado para funcionarios autorizados.',
        child: Form(
          key: inherited.formKey,
          child: Column(
            children: [
              AppTextField(
                controller: inherited.username,
                label: 'Usuario',
                icon: Icons.person_outline_rounded,
                autofillHints: const [AutofillHints.username],
                validators: [RequiredValid(error: 'Campo requerido')],
              ),
              AppTextPassword(
                controller: inherited.password,
                label: 'Contraseña',
                autofillHints: const [AutofillHints.password],
                validators: [RequiredValid(error: 'Campo requerido')],
                onSubmitted: (_) => _submit(context, inherited, signInCubit),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submit(context, inherited, signInCubit),
                  child: const Text('Entrar al panel'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(Routes.publicConsult),
                child: const Text('Volver a consulta pública'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(
    BuildContext context,
    SignInFormInherited inherited,
    SignInCubit signInCubit,
  ) {
    if (!inherited.formKey.validateForm()) return;

    signInCubit.signIn(
      username: inherited.username.getValue(),
      password: inherited.password.getValue(),
    );
  }
}
