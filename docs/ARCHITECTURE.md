# Arquitetura

**Última atualização:** 2026-07-27

Este documento descreve navegação, gerenciamento de estado, persistência
e o serviço de reinício de progresso como existem hoje no código. Para o
histórico narrativo de como se chegou aqui, ver `PROJECT_STATUS.md`. Para
o que falta, ver `IMPLEMENTATION_BACKLOG.md`.

## Stack

- **UI:** Flutter, Material 3 (`useMaterial3: true`).
- **Estado:** Riverpod (`flutter_riverpod`) — único padrão de
  gerenciamento de estado no projeto (ADR-0001). `Provider`/
  `FutureProvider`/`FutureProvider.family`/`NotifierProvider` são os
  tipos usados; nenhum `StateNotifier`/`Bloc`/`GetX` foi introduzido.
- **Persistência:** Drift (SQLite local) para progresso/dados relacionais
  (ADR-0002); um arquivo JSON separado (`calisthenics_rpg_settings.json`,
  via `SettingsRepository`) para preferências pessoais que não fazem
  sentido versionadas/relacionais (nome, acessibilidade, som/voz/
  vibração).
- **Navegação:** `Navigator`/`MaterialPageRoute` para rotas internas +
  `IndexedStack` para as quatro abas persistentes do shell raiz. Nenhum
  pacote de rotas (`go_router`, `auto_route` etc.) foi introduzido.
- **Backend:** nenhum. MVP 100% local (ADR-0006); `OutboxEvents`/
  `core/sync/` existem como reserva de schema para uma sincronização
  futura, mas não são usados.

## Fluxo de entrada (`AppFlowGate`)

`lib/app/app_flow_gate.dart` decide reativamente qual etapa mostrar,
observando o banco local em cascata — cada etapa só aparece se a
anterior já foi concluída:

```
AppFlowGate
 └─ triagem de segurança ainda não feita? → SafetyScreeningScreen
 └─ triagem bloqueia o usuário?            → SafetyBlockedScreen
 └─ preferências de treino ainda não existem? → OnboardingPreferencesScreen
 └─ colocação de push_horizontal ainda não existe? → AssessmentSkipTestScreen
 └─ plano semanal ainda não existe?        → GenerateTrainingPlanScreen
 └─ tudo existe                            → MainShell (shell de 4 abas)
```

Cada tela, ao salvar, invalida o provider correspondente e o gate
reconstrói para a próxima etapa — não há uma máquina de estados
separada, só providers em cascata.

`appResetEpochProvider` (`lib/app/app_reset.dart`) é observado no topo do
`AppFlowGate`: um `NotifierProvider<int>` que o reset de progresso
incrementa (`bump()`) para forçar o gate inteiro a reavaliar do zero —
depois de reiniciar, o usuário volta a passar pela avaliação/plano
porque os providers que o `AppFlowGate` observa (colocação, plano) agora
retornam `null`.

## Shell principal (`MainShell`)

`lib/app/main_shell.dart`: `Scaffold` com `IndexedStack` de 4 telas +
`NavigationBar` (Material 3) fixo embaixo. As quatro abas são construídas
uma única vez e mantidas vivas o tempo todo (`IndexedStack` preserva
árvore/estado/posição de rolagem ao alternar, em vez de reconstruir a
tela cada vez):

| Índice | Aba | Tela raiz | Módulo |
|---|---|---|---|
| 0 | Treino | `JourneyScreen` | `features/journey` |
| 1 | Descobrir | `DiscoverScreen` | `features/discover` |
| 2 | Relatório | `ReportScreen` | `features/report` |
| 3 | Definição | `SettingsScreen` | `features/settings` |

Navegação para telas de detalhe (plano da semana, player de sessão,
detalhe de treino/exercício, Evolução) continua usando
`Navigator.push`/`MaterialPageRoute` a partir de qualquer uma das quatro
abas — a barra de navegação não aparece nessas rotas empilhadas
(comportamento padrão do `Scaffold`/`Navigator`, sem configuração
especial).

## Módulos (`lib/features/*`)

Cada módulo segue a mesma separação em três camadas:

- `domain/` — modelos e regras puras, sem I/O (ex.:
  `weekly_plan_generator.dart`, `mastery_evaluator.dart`, `xp_rules.dart`).
  Testáveis sem banco nem widget.
- `data/` — tabelas Drift (quando existem), repositórios (I/O real) e
  providers Riverpod que os expõem.
- `presentation/` — telas e widgets, `ConsumerWidget`/`ConsumerStatefulWidget`.

Módulos existentes: `safety`, `onboarding`, `assessment`, `training_plan`,
`workout_session`, `progression`, `rpg`, `missions`, `journey`,
`discover`, `report`, `settings`, `evolution`.

`journey`, `discover`, `report` e `settings` são as quatro raízes do
`MainShell`. `evolution` é uma tela de detalhe (colocações + recordes +
histórico), acessível pelo ícone no `AppBar` da Jornada — não é uma das
quatro abas.

## Persistência

### Banco Drift (`lib/core/database/app_database.dart`)

`schemaVersion = 7`. Migração sempre aditiva depois da v1 (nunca recria
tabela com dados reais sem necessidade) — cada etapa documentada e
testada individualmente em `test/core/database/migration_v*_test.dart`:

| De → Para | Mudança |
|---|---|
| 1→2 | Recria `CapabilityEstimateRecords` (`inputAnchor` virou opcional) |
| 2→3 | Cria `training_plan_records` |
| 3→4 | Cria `workout_session_records` e `set_log_records` |
| 4→5 | Cria `xp_ledger_records` |
| 5→6 | Colunas aditivas em `set_log_records` (dose por tempo/idempotência) + cria `active_timed_set_records` |
| 6→7 | Coluna aditiva `preferred_weekdays_json` em `training_preference_records` (meta de dias de treino) |

Tabelas de progresso/histórico (apagadas pelo reset — ver
`DATA_RESET.md`): `workout_session_records`, `set_log_records`,
`xp_ledger_records`, `capability_estimate_records`,
`training_plan_records`, `active_timed_set_records`, `outbox_events`.

Tabelas preservadas pelo reset: `safety_screenings`,
`training_preference_records` (agenda, equipamento, local **e** meta de
dias da semana).

### Preferências pessoais (JSON, fora do banco)

`lib/features/settings/data/settings_repository.dart`:
`SettingsRepository` grava `UserSettings` (nome, som, voz, vibração,
início automático de descanso, contagem regressiva, descanso padrão,
alto contraste, escala de texto, reduzir animações, idioma) em
`calisthenics_rpg_settings.json`, em `getApplicationDocumentsDirectory()`
— fora do banco Drift de propósito, para nunca ser tocado pelo reset de
progresso. Escrita via arquivo temporário + `rename` (evita corromper o
arquivo se o app fechar no meio da gravação); se o `rename` falhar
(observado só em teoria, não reproduzido neste ambiente — ver nota em
`HANDOFF_CLAUDE.md`), cai para escrita direta no destino como
salvaguarda.

`userSettingsProvider` (`settings_providers.dart`) é o `FutureProvider`
que qualquer tela pode observar; `lib/app/app.dart` o usa para aplicar
`textScale`/`highContrast`/`reduceMotion` no `MaterialApp` raiz (via
`MediaQuery` no `builder` e `buildCalisthenicsRpgTheme(highContrast:)`).

## Reset de progresso

Ver `docs/DATA_RESET.md` para o comportamento completo (o que apaga, o
que preserva, fluxo de confirmação). Resumo arquitetural: um único
`ProgressResetService.reset()` (`features/settings/data/
progress_reset_service.dart`) roda tudo dentro de `_db.transaction()` —
se qualquer passo falhar, nada é apagado (testado explicitamente em
`progress_reset_service_test.dart`, incluindo rollback forçado). Depois
do sucesso, `SettingsScreen` invalida todos os providers de progresso
relevantes e incrementa `appResetEpochProvider`, forçando o `AppFlowGate`
a recomeçar do estágio de avaliação/plano.

## Providers cruzando módulos (pontos de atenção)

Alguns providers são lidos por mais de um módulo — não é acoplamento
acidental, é a "fonte única de verdade" (seção 9 do documento de
redesenho) para XP/nível/frequência/preferências:

- `userSettingsProvider`/`settingsRepositoryProvider`
  (`features/settings`) — lido por `app.dart` (tema/acessibilidade) e
  por `workout_session/presentation/workout_player_screen.dart`
  (contagem regressiva do `TimedSetPlayer`).
- `latestTrainingPreferencesProvider`
  (`features/onboarding/data/training_preferences_providers.dart`) —
  lido por `JourneyScreen` (meta de dias formalizada) e `SettingsScreen`
  (edição da meta).
- `latestActiveWorkoutSessionProvider`/`recentCompletedSessionsProvider`/
  `bestRepsByExerciseProvider` (`features/workout_session/data/
  workout_session_providers.dart`) — lidos por `JourneyScreen` (sessão
  pausada, sequência atual), `features/discover` (seção "Recentes") e
  `features/report` (recordes pessoais, histórico).

## Testes

`flutter test` roda toda a suíte em `test/`, espelhando a estrutura de
`lib/features/*`. Armadilhas de teste conhecidas (documentadas para não
serem redescobertas):

- **`testWidgets` roda dentro de uma zona `FakeAsync`.** Qualquer I/O
  real (arquivo, `NativeDatabase`, `Directory.createTemp`,
  `path_provider`) criado diretamente dentro do corpo do teste trava
  `pump`/`pumpAndSettle` para sempre, a menos que esteja dentro de
  `await tester.runAsync(() async { ... })`. Alternativa mais simples
  quando possível: sobrescrever o provider com uma implementação em
  memória (ex.: `_InMemorySettingsRepository` nos testes de
  `SettingsScreen`) em vez de usar um repositório real.
- **`pumpAndSettle()` trava para sempre** se qualquer widget na árvore
  tiver uma animação que se repete indefinidamente — por exemplo
  `PatternIllustration`/`ExerciseMediaPlaceholder`, usados sempre que um
  exercício não tem foto real associada. Nesses casos, usar
  `tester.pump(Duration(...))` fixo em vez de `pumpAndSettle()`.
- **Overflow (`RenderFlex`) é reportado mesmo em teste**, não só em
  execução manual — os testes em `test/app/responsive_visual_test.dart`
  pumpam o `MainShell` inteiro em tamanhos de tela e escalas de fonte
  diferentes (`tester.view.physicalSize`,
  `tester.platformDispatcher.textScaleFactorTestValue`) justamente para
  pegar esse tipo de bug automaticamente (foi assim que o bug real do
  `XpEvolutionChart` foi encontrado nesta sessão).
