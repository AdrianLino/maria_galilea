import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/constants/environment.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'config/utils/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar entorno y variables
  await Environment.initEnvironment();

  // Inicializar Hive (para base de datos local)
  await initHiveBoxes();

  runApp(
    const ProviderScope(child: MainApp()),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'IqonicBot - Gemini AI',
      routerConfig: appRouter,
      theme: AppTheme().getTheme(),
      debugShowCheckedModeBanner: false,
    );
  }
}