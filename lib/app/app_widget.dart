import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import '../presentation/shared/introduction/app_introduction_wrapper.dart';
import 'core/toast/global_toast_host.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precifica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AppIntroductionWrapper(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return GlobalToastHost(child: child);
      },
    );
  }
}
