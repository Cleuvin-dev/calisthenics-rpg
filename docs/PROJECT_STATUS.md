# Project Status

**Data:** 2026-07-23
**Responsável:** Claude Code (sessão com Cleuvin)
**Branch/commit:** `feat/onboarding-triagem-colocacao`

## Objetivo da sessão

Implementar a primeira história vertical (versão local-only, sem login):
triagem de segurança → agenda/equipamento → colocação conservadora em
empurrar horizontal → resultado persistido. Instalar e validar no aparelho
físico do usuário.

## Implementado

- **Domínio (Dart puro, testado):**
  - `features/safety/domain`: `ScreeningAnswers`, `ScreeningResult` (4
    categorias) e `ScreeningClassifier` determinístico
    (SAFETY_AND_SCREENING.md §2-3).
  - `features/onboarding/domain`: `TrainingPreferences`, `TrainingLocation`,
    `Equipment`.
  - `features/assessment/domain`: `PushHorizontalAnchor` (âncoras
    parede/bancada/joelhos/chão, mapeadas aos nós de SKILL_TREES.md §2) e
    `ConservativePlacementCalculator`, com dois modos:
    - `calculate(anchor)`: regra "um nó abaixo" (SCORING_AND_PLACEMENT.md
      §7), confiança baixa;
    - `calculateSkippedEntirely()`: usuário não quer responder nada agora
      → nó mais conservador possível ("não avaliado", §4).
- **Dados:** tabelas Drift locais (`SafetyScreenings`,
  `TrainingPreferenceRecords`, `CapabilityEstimateRecords`, todas
  append-only/auditáveis) + repositórios + providers Riverpod
  (`latestX` como `FutureProvider`).
- **Apresentação:** `SafetyScreeningScreen`, `SafetyBlockedScreen` (com
  botão "Refazer triagem"), `OnboardingPreferencesScreen`,
  `AssessmentSkipTestScreen` (com opção "Não quero responder agora"),
  `PlacementResultScreen` (com botão "Refazer colocação" — corrige um
  problema relatado pelo usuário: a tela de resultado era um beco sem
  saída na primeira versão).
- **Fluxo do app:** `AppFlowGate` — widget reativo que decide qual tela
  mostrar com base no que existe no banco local (sem Navigator imperativo
  para o fluxo principal; cada tela invalida o provider correspondente ao
  salvar e o gate reconstrói).
- **Ícone do app:** `assets/images/icon.jpg` (na verdade WebP 260x280
  mal rotulado) normalizado para PNG quadrado via `tool/prepare_app_icon.dart`
  e aplicado com `flutter_launcher_icons`.
- **Instalado e validado no aparelho físico** (Android, `7549GMFUDA4DKZW8`)
  via `flutter build apk --release` + `adb install` — `flutter run` em modo
  debug travou repetidamente por processos concorrentes disputando o lock
  do Gradle; o caminho build+adb install se mostrou mais confiável neste
  ambiente.
- 20 testes automatizados (unitários de domínio + repositório com SQLite em
  memória + smoke test de widget), todos passando. `flutter analyze` sem
  problemas.

## Arquivos alterados

Commits nesta branch (alguns feitos diretamente pelo usuário via editor):
`d12f87a` (implementação da história vertical), `51f1d5c` (ícone +
primeiro release instalado), e o commit desta sessão (correção da tela de
resultado sem saída + opção de pular avaliação por completo +
`inputAnchor` nullable). Ver `git log` para a lista completa de arquivos.

## Banco/migrations

- Backend Supabase segue pausado (ADR-0006); `supabase/migrations/`
  continua vazio.
- Schema local Drift em `schemaVersion = 2`: `OutboxEvents` (ainda não
  usada), `SafetyScreenings`, `TrainingPreferenceRecords`,
  `CapabilityEstimateRecords`. Migração de `1→2` recria
  `CapabilityEstimateRecords` porque `inputAnchor` passou a ser opcional
  (suporta a colocação "não avaliado"); aceitável por não haver dados reais
  em produção ainda.

## Testes executados

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sem problemas |
| `flutter test` | 20 passed, 0 failed |
| `dart run build_runner build` | OK |
| `flutter build apk --release` | OK (54.3MB) |
| `adb install -r` + `am start` no aparelho físico | App abre e fica em foreground |

## Decisões e ADRs

- ADR-0001 a 0006 seguem válidas (ver sessão anterior).
- Decisão desta sessão (não formalizada em ADR por ser pequena e local):
  mapeamento de 4 âncoras autorrelatadas → níveis 0-7 da árvore de
  empurrar horizontal, com período de validade fixo de 30 dias — ambos
  pendentes de aprovação profissional (mesma ressalva já registrada em
  `conservative_placement.dart`).

## Pendências

- Textos de triagem/segurança são placeholders — pendente de revisão
  profissional (SAFETY_AND_SCREENING.md §10).
- Nada existe além da tela de resultado (sem dashboard, sem motor de
  treino, sem XP) — é o próximo passo combinado com o usuário: implementar
  o motor de treino determinístico (próximo prompt sugerido do
  `IMPLEMENTATION_PROMPT.md`).
- `flutter run` em modo debug não está confiável neste ambiente Windows
  (trava por contenção de lock do Gradle quando há processos residuais);
  usar `flutter build apk --release` + `adb install -r` como fluxo padrão
  até investigar a causa raiz.

## Riscos/bloqueios

- Nenhum bloqueio técnico. Supabase CLI/Docker seguem não instalados,
  irrelevante enquanto o backend estiver pausado.

## Próxima tarefa recomendada

Implementar o motor de treino determinístico (geração de uma semana de
2-4 dias a partir da colocação, com `reason_code` explicável), conforme
combinado com o usuário.

## Critério para retomar

Ler este arquivo e `docs/adr/0006-mvp-local-only.md`. O app instalado no
aparelho do usuário reflete o estado desta sessão; qualquer divergência
encontrada ao testar deve ser tratada como bug, não como escopo pendente,
a menos que list em "Pendências" acima.
