import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/authentication/sign_in/cubit/sign_in_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/auth_split_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignInCubit(),
      child: const SignInView(),
    );
  }
}

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<SignInCubit, SignInState>().listen(),
        ListenerPro<SignInCubit, SignInState>().event(
          onSuccess: (state) {
            context.read<AppSessionCubit>().onSignedIn(userName: state.username);
            context.read<SideMenuCubit>().init();
          },
        ),
      ],
      child: const SignInBody(),
    );
  }
}

class SignInBody extends StatefulWidget {
  const SignInBody({super.key});

  @override
  State<SignInBody> createState() => _SignInBodyState();
}

class _SignInBodyState extends State<SignInBody> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin');

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _usernameController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit
                    ? () => context.read<SignInCubit>().signIn(
                          username: _usernameController.text,
                          password: _passwordController.text,
                        )
                    : null,
                child: const Text('Entrar al panel'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<AppSessionCubit>().showPublicConsult(),
              child: const Text('Volver a consulta pública'),
            ),
          ],
        ),
      ),
    );
  }
}
