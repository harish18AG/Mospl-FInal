import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/router/app_router.dart';
import 'firebase_options.dart';
import 'src/state/app_state.dart';
import 'src/theme/app_theme.dart';

import 'package:flutter/semantics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Keep the shopping catalog available if Firebase initialization is
    // temporarily unavailable in a local development environment.
  }

  final appState = AppState();
  await appState.restoreSession();
  await appState.loadCatalogFromBackend();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MosplApp(),
    ),
  );
}

class MosplApp extends StatelessWidget {
  const MosplApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp.router(
      title: 'MOSPL',
      debugShowCheckedModeBanner: false,
      themeMode: appState.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: AppRouter.router,
    );
  }
}
