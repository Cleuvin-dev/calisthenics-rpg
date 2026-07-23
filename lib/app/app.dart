import 'package:flutter/material.dart';

import 'app_flow_gate.dart';

class CalisthenicsRpgApp extends StatelessWidget {
  const CalisthenicsRpgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calisthenics RPG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const AppFlowGate(),
    );
  }
}
