import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:organiza_ae/app_widget.dart';
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final container = ProviderContainer();

  await container.read(gestaoRepositoryProvider).init();

  // Roda o nosso aplicativo, passando o container
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AppWidget(),
    ),
  );
}
