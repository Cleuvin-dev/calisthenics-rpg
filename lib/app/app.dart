import 'package:flutter/material.dart';

class CalisthenicsRpgApp extends StatelessWidget {
  const CalisthenicsRpgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calisthenics RPG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const _ScaffoldPlaceholder(),
    );
  }
}

/// Placeholder até a primeira história vertical (cadastro, triagem,
/// agenda/equipamento e colocação conservadora) ser implementada.
class _ScaffoldPlaceholder extends StatelessWidget {
  const _ScaffoldPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Calisthenics RPG\nScaffold do projeto — próximo passo: '
            'onboarding, triagem e colocação conservadora.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
