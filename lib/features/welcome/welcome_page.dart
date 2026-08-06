import 'package:flutter/material.dart';

import '../../core/widgets/primary_button.dart';

import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bakgrunnsbilde
          SizedBox.expand(
            child: Image.asset(
              'assets/images/frontpagebackground.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Mørkt filter over bildet
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),

          // Innhold
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  const Text(
                    'My Recovery Manager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 80),

                  PrimaryButton(
                    text: 'Logg inn',
                    onPressed: () {
                      context.go('/login');
                      // Skal kobles til LoginPage senere
                    },
                  ),

                  const SizedBox(height: 16),

                  PrimaryButton(
                    text: 'Opprett konto',
                    onPressed: () {
                      context.go('/register');
                      // Skal kobles til RegisterPage senere
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}