import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:precifica/app/app_widget.dart';
import 'package:precifica/presentation/gestao_produtos/gestao_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final container = ProviderContainer();

  await container.read(gestaoRepositoryProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AppWidget(),
    ),
  );
}
