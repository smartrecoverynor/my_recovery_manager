import 'package:flutter/material.dart';

import 'app/router.dart';

void main() {
  runApp(const MyRecoveryManagerApp());
}

class MyRecoveryManagerApp extends StatelessWidget {
  const MyRecoveryManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My Recovery Manager',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}