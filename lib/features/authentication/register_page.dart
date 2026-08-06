import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opprett konto'),
      ),
      body: const Center(
        child: Text(
          'RegisterPage',
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}