import 'package:flutter/material.dart';
import 'pages/backlog_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// void main() {
//   runApp(const MyApp());
// }

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('pt', 'BR'), // define português do Brasil
      supportedLocales: const [
        Locale('en', ''), // inglês
        Locale('pt', 'BR'), // português
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      title: 'Gerencial',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),

      // home: const ClientesPage(),
      home: const BacklogScreen(),
    );
  }
}
