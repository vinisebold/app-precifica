import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:organiza_ae/app_widget.dart';
import 'package:organiza_ae/data/local_storage_service.dart';

Future<void> main() async {
  // Garante que os bindings do Flutter foram inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Hive no diretório padrão do app
  await Hive.initFlutter();

  // Cria uma instância do nosso serviço e chama o métod init
  await LocalStorageService().init();

  // Roda o nosso aplicativo
  runApp(const AppWidget());
}
