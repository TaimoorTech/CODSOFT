import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quote_app/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quote App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: homePage(),
    );
  }
}

