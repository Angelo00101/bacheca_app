import 'package:material_ui/material_ui.dart';

import 'navigation.dart';
import 'screens/board_screen.dart';
import 'state/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await Session.load();
  runApp(BachecaApp(session: session));
}

class BachecaApp extends StatelessWidget {
  final Session session;

  const BachecaApp({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1E5AA8);
    return SessionScope(
      session: session,
      child: MaterialApp(
        title: 'Bacheca Lavoro',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [routeObserver],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const BoardScreen(),
      ),
    );
  }
}
