import 'package:flutter/material.dart';
import 'package:swan_frog/pages/stream_page.dart';
import 'package:swan_frog/pages/intro_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const IntroPage(),
      routes: {
        '/intro': (context) => const IntroPage(),
        '/stream': (context) => const SendMetadata(),
      },
    );
  }
}
