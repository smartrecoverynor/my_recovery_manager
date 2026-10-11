import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/primary_button.dart';
import '../../core/widgets/primary_text_form_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opprett konto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opprett konto',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Opprett en konto for å komme i gang.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),

                const SizedBox(height: 32),

                PrimaryTextFormField(
                  controller: _usernameController,
                  label: 'Brukernavn',
                  hint: 'Velg et brukernavn',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Skriv inn et brukernavn';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                PrimaryTextFormField(
                  controller: _emailController,
                  label: 'E-post',
                  hint: 'Skriv inn e-post',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Skriv inn e-post';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                PrimaryTextFormField(
                  controller: _passwordController,
                  label: 'Passord',
                  hint: 'Skriv inn passord',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Passordet må være minst 8 tegn';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                PrimaryTextFormField(
                  controller: _confirmPasswordController,
                  label: 'Bekreft passord',
                  hint: 'Skriv inn passord på nytt',
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passordene er ikke like';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Opprett konto',
                  onPressed: () {
                    context.go('/profile-setup');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
