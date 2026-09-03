import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/ponto/presentation/screens/home_ponto_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const ChronosPulseApp());
}

class ChronosPulseApp extends StatelessWidget {
  const ChronosPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronos Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePontoScreen(),
    );
  }
}
