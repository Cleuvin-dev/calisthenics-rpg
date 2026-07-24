import 'package:flutter/material.dart';

import 'app_flow_gate.dart';
import 'theme.dart';

class CalisthenicsRpgApp extends StatelessWidget {
  const CalisthenicsRpgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calisthenics RPG',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: buildCalisthenicsRpgTheme(),
      theme: buildCalisthenicsRpgTheme(),
      home: const AppFlowGate(),
    );
  }
}
