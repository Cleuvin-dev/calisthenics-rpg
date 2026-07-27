import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Epoch interno que força o gate raiz a reler o fluxo após operações que
/// alteram várias fontes de estado de uma só vez, como o reset de progresso.
final appResetEpochProvider = NotifierProvider<AppResetEpochNotifier, int>(
  AppResetEpochNotifier.new,
);

class AppResetEpochNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
