# Project Status

**Data:** 2026-07-24 (última atualização 2026-07-26)
**Responsável:** Claude Code (sessão com Cleuvin)
**Branch/commit:** `main` (working tree com alterações não commitadas — usuário commita manualmente)

Histórico narrativo de sessão ("o que foi feito e por quê"). Para a
lista priorizada e acionável do que falta ("o que fazer a seguir"), ver
`docs/IMPLEMENTATION_BACKLOG.md`.

## Objetivo da sessão

Dar andamento ao MVP depois da primeira história vertical (triagem →
onboarding → colocação): implementar, em sequência, o **motor de treino
determinístico**, o **player de sessão offline**, a **confirmação de
domínio/progressão**, o **épico de RPG/XP**, **missões diárias/semanais**
e a **tela de dashboard "Jornada"**, seguindo a cadeia de dependências de
`10_DELIVERY/ROADMAP.md` §7 (avaliação → motor de treino → sessão
offline → progressão/domínio → RPG). Na segunda metade da sessão: testar
tudo isso no aparelho físico do usuário e, a pedido dele, dar um
**redesign visual completo** — tema escuro, identidade de "game",
gráfico de evolução, animações e ilustrações animadas de exercício.
Por fim, o usuário autorizou trabalho autônomo pela lista de
pendências: corrigir os dois bugs encontrados no teste do aparelho,
estender avaliação real para mais padrões e criar a tela "Evolução".

Nesta continuação (mesma sessão, retomada após compactação de contexto):
o usuário trouxe uma versão v1.2 da documentação
(`10_DELIVERY/CHANGELOG_v1.2.md`), com dois documentos novos —
`07_UX/VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md` e
`07_UX/SETTINGS_AND_TIMED_EXERCISES.md` — e pediu explicitamente a
história vertical do §28 do primeiro: dashboard com missão do dia,
detalhe de treino nomeado, player por repetições com alvo estruturado,
player por duração com 3-2-1/pausa/retomada/recuperação, descanso entre
exercícios, recuperação após fechar o app, mídia local com placeholder,
botão "Senti dor" sempre acessível e persistência transacional/
idempotente — 100% offline, sem Supabase/Firebase/login/API/câmera/IA.

## Implementado

### Motor de treino (`features/training_plan`)

- **Domínio:** `exercise_catalog.dart` — catálogo mínimo (não editorial)
  cobrindo os padrões fundamentais de TRAINING_ENGINE.md §3, com uma
  variação conservadora por padrão/faixa de capacidade e equipamento.
  `weekly_plan_generator.dart` — `WeeklyPlanGenerator` determinístico:
  templates por frequência (2 a 6 dias, seguindo WEEKLY_TEMPLATES.md),
  orçamento de exercícios por duração da sessão, downgrade automático de
  6→5 dias (WEEKLY_TEMPLATES.md §6 — sem histórico suficiente ainda),
  seleção por nível de `push_horizontal` (única capacidade avaliada hoje;
  demais padrões usam a variação mais conservadora, mesma filosofia de
  `calculateSkippedEntirely`), substituição por equipamento com
  `reason_code` (`FOUNDATION_GAP`, `WEEKLY_BALANCE`,
  `EQUIPMENT_SUBSTITUTION`).
- **Dados:** tabela `training_plan_records` (plano serializado em JSON —
  recomputável, não precisa de tabelas relacionais ainda), repositório e
  providers Riverpod.
- **Apresentação:** `GenerateTrainingPlanScreen` (ação explícita de
  gerar) e `TrainingPlanScreen` (semana com motivo de cada exercício,
  link para colocação, botão de regerar, botão "Iniciar sessão" por dia).

### Player de sessão (`features/workout_session`)

- **Domínio:** `WorkoutSessionStatus` (iniciada/pausada/abandonada/
  concluída — FR-026), `PerceivedEffort` (muito fácil/adequado/difícil
  concluí/não completei/dor — FR-022, substitui RPE/RIR numérico por
  categorias mais rápidas de registrar em campo), `WorkoutSessionItem`
  (cópia congelada do item do plano no início da sessão — regenerar o
  plano depois não altera sessão já iniciada).
- **Dados:** tabelas `workout_session_records` (itens congelados em JSON)
  e `set_log_records` (uma linha por série, append-only, para permitir
  consulta futura por exercício/histórico). Repositório com
  `startSession`/`logSet`/`pause`/`resume`/`abandon`/`complete`/
  `latestActive`.
- **Apresentação:** `WorkoutPlayerScreen` (nome/padrão/alvo do exercício
  atual, séries já registradas, registrar série via `LogSetSheet`, botão
  de dor sempre visível — nunca em menu —, pausar/abandonar/concluir) e
  `WorkoutSummaryScreen` (contagem de séries, alerta se houve dor, e — a
  partir desta sessão — o resultado da avaliação de domínio).
- **Wiring:** `TrainingPlanScreen` ganhou banner de sessão ativa/pausada
  para retomar (evita sessões órfãs duplicadas). `AppFlowGate` ganhou o
  estágio `_AfterPlacementGate` (mostra `GenerateTrainingPlanScreen` ou
  `TrainingPlanScreen` conforme exista plano salvo).
- Texto desatualizado em `PlacementResultScreen` corrigido (dizia que
  motor de treino/sessões "ainda não existem").

### Progressão/domínio (`features/progression`)

- **Domínio:** `mastery_rules.dart` — uma `MasteryRule` por variação da
  escada de `push_horizontal` (reps mínimas por série, séries
  qualificadas por sessão, confirmações necessárias, intervalo mínimo
  entre confirmações — PROGRESSION_RULES.md §2, números placeholder de
  MVP). `mastery_evaluator.dart` — `MasteryEvaluator` determinístico:
  percorre sessões concluídas em ordem cronológica, desqualifica sessão
  inteira se houver série com dor (DATA_MODEL.md §4), conta confirmações
  respeitando o intervalo mínimo entre elas.
- **Dados:** `ProgressionRepository.evaluateAndPromotePushHorizontal` —
  busca sessões concluídas + `set_logs` do exercício correspondente ao
  nível atual desde a última colocação, roda o avaliador e, se promovido,
  grava uma nova linha em `capability_estimate_records` via
  `CapabilityEstimateRepository.saveEstimate` (método novo, generalizado
  a partir do `save(ConservativePlacementResult)` existente — mesma
  tabela, `reason_code: masteryConfirmed`, `confidence: medium`). Sem
  tabela própria: reaproveita o que já existia.
- **Wiring:** `WorkoutPlayerScreen` recebe a colocação atual de
  `push_horizontal` e roda a avaliação ao concluir a sessão;
  `WorkoutSummaryScreen` mostra confirmação parcial ("você atingiu o alvo
  em X de Y sessões") ou domínio confirmado, com aviso para gerar um novo
  plano manualmente (nada muda de plano "em silêncio").

### RPG/XP (`features/rpg`)

- **Domínio:** `xp_rules.dart` — valores base de RPG_SYSTEM.md §2 (sessão
  concluída: 40, todas as séries registradas: 10, domínio confirmado:
  80) e `awardsForCompletedSession(...)`, função pura que decide os
  créditos de uma sessão a partir de fatos (itens da sessão, exercícios
  logados, se houve promoção de domínio) — nenhuma dependência de banco.
  `level_curve.dart` — fórmula de nível de RPG_SYSTEM.md §3
  (`100 + 25 × nível^1.35`) e `LevelCalculator.levelFor(totalXp)`.
- **Dados:** tabela `xp_ledger_records` (ledger imutável, saldo é sempre
  a soma — nunca um campo mutável). `XpLedgerRepository.grant`/
  `grantRepeatable`/`grantAwards`: idempotência por `idempotencyKey`
  (repetir uma chamada não duplica crédito, ECONOMY_AND_ANTI_ABUSE.md
  §2) e teto diário de XP repetível (`dailyRepeatableXpCap = 200`, §3) —
  domínio confirmado não entra no teto porque só acontece uma vez por
  nó, por natureza da própria chave de idempotência.
- **Wiring:** `WorkoutPlayerScreen` concede XP ao concluir a sessão
  (sessão + bônus de registro completo + domínio, se houve promoção
  nesta mesma conclusão); `WorkoutSummaryScreen` mostra "+XX XP" e, se
  subiu de nível, a mensagem de SCREENS_AND_FLOWS.md §6 ("Você alcançou
  o nível N! A próxima habilidade será liberada quando os requisitos
  físicos forem confirmados."). `XpLevelBadge` novo (nível + barra de
  progresso) embutido no topo de `TrainingPlanScreen` — ainda não há
  dashboard/"Jornada" dedicada.
- FR-040 pede "conceder XP apenas no backend"; como o MVP é local-only
  single-device (ADR-0006), sem outros jogadores/ranking, não há
  superfície de fraude a proteger ainda — mesma ressalva já aplicada ao
  motor de treino e à triagem (regra determinística roda no cliente por
  ora, migra para o backend quando ele voltar).

### Missões (`features/missions`)

- **Domínio:** `mission.dart` — definições diárias (concluir aquecimento,
  registrar ao menos uma série, concluir uma sessão — 10 XP cada) e
  semanais (cumprir a frequência do plano, treinar todos os padrões
  previstos, confirmar domínio de uma habilidade — 75 XP cada),
  RPG_SYSTEM.md §8. Deliberadamente **não** inclui todas as 10 missões
  listadas no documento — só as que dão para avaliar honestamente com os
  dados que já existem (sem check-in, sem "sessão de recuperação
  prescrita" distinta, sem tela de "revisar progresso" ainda).
  `mission_evaluator.dart` — puro, recebe fatos (`DailyMissionFacts`/
  `WeeklyMissionFacts`) já coletados e devolve completude + rótulo de
  progresso (ex.: "2/3 sessões").
- **Dados:** `MissionRepository` compõe `WorkoutSessionRepository`
  (sessões/séries no dia ou semana — dois métodos novos,
  `completedBetween`/`setLogsBetween`), `TrainingPlanRepository` (padrões
  previstos na semana) e `CapabilityEstimateRepository` (domínio
  confirmado na semana — novo método `confirmedBetween`). Separação
  deliberada entre `evaluateDaily`/`evaluateWeekly` (leitura pura,
  reativa, sem gravar nada) e `grantCompletedDaily`/`grantCompletedWeekly`
  (ação explícita que credita XP via `XpLedgerRepository.grant`,
  idempotente por dia/semana).
- `core/time/date_period.dart` novo: limites de dia/semana (semana
  começa segunda) — utilitário puro, sem estado.

### Jornada (`features/journey`)

- Tela de dashboard única (`JourneyScreen`), primeiro dos cinco destinos
  de SCREENS_AND_FLOWS.md §1 — os outros quatro (Treino como tela
  separada, Habilidades, Evolução, Perfil) não existem como navegação
  por abas ainda. Segue a hierarquia do §3: missão principal (próxima
  sessão da semana ainda não concluída, com CTA para o plano), próxima
  habilidade (colocação atual de push_horizontal), nível/XP
  (`XpLevelBadge`, que saiu de `TrainingPlanScreen` e voltou a viver
  aqui), missões do dia/semana, histórico curto (últimos 5 lançamentos
  do ledger de XP).
- Ao entrar na tela, concede XP de missões já cumpridas (ação explícita
  em `initState`, não um efeito colateral escondido num provider de
  leitura) e invalida os providers relevantes para refletir na hora.
- **Wiring:** `AppFlowGate` agora mostra `JourneyScreen` (não mais
  `TrainingPlanScreen` diretamente) como estágio terminal quando existe
  plano salvo; `TrainingPlanScreen` continua existindo, acessível a
  partir da Jornada ("Ver plano da semana completo" ou tocando a missão
  principal).

### Geral

- 83 testes automatizados (era 20 no início da sessão), todos passando —
  cobrem o gerador de plano, o repositório de sessão, o avaliador/
  repositório de domínio, a curva de nível, as regras/ledger de XP e,
  agora, o avaliador de missões (cada tipo isoladamente) e o repositório
  de missões (concessão idempotente por dia/semana, missão semanal sem
  plano salvo, cobertura de padrões parcial vs. completa).
  `flutter analyze` sem problemas.
### Teste no aparelho físico

- `flutter build apk --release` + `adb install -r` no aparelho do usuário
  (`7549GMFUDA4DKZW8`) — segue sendo o caminho confiável neste Windows
  (ver Pendências).
- Testado via `adb shell input tap`/`swipe` + screenshots (sem framework
  de automação de UI dedicado): app abre com os dados reais já
  persistidos de sessões anteriores, `JourneyScreen` renderiza com
  valores computados corretamente, navegação Jornada → Plano → Player
  funciona, registrar série persiste de verdade (série sobreviveu a
  reabrir o app depois do redesign visual), retomar sessão em andamento
  funciona.
- **Bug real encontrado:** o botão de voltar do sistema (hardware/gesto)
  sai do `WorkoutPlayerScreen` sem chamar `_pauseAndExit`, deixando a
  sessão com `status = inProgress` em vez de `paused`. Não perde dados
  (o banner "sessão em andamento" continua aparecendo e permite
  retomar), mas o status fica tecnicamente errado. Não corrigido nesta
  sessão — precisa de um `PopScope` no `WorkoutPlayerScreen`.
- Achado de ambiente, não do app: neste aparelho específico, rodar
  `adb shell uiautomator dump` logo após um `adb shell input tap`
  ocasionalmente abriu sozinho o assistente de configuração de
  "Acesso por interruptor" do Android (acessibilidade do sistema, nada
  a ver com o app). Contornado evitando `uiautomator dump` e usando só
  screenshots com coordenadas calculadas a partir da resolução real do
  aparelho (`adb shell wm size`).

### Redesign visual — tema escuro/"game" (a pedido do usuário)

- `lib/app/theme.dart` novo: `ColorScheme.fromSeed` escuro (violeta
  `#7C4DFF`) com `tertiary` dourado (`#FFC947`) reservado para XP/
  recompensas — progressão física usa a cor primária, XP usa dourado,
  em toda a UI. Cards arredondados (raio 20), botões arredondados
  (raio 16), tipografia mais pesada nos títulos. `MaterialApp` passou a
  usar `themeMode: ThemeMode.dark` sempre (não há alternância clara/
  escuro ainda — o pedido foi para escuro por padrão).
  Sem pacotes novos (`ThemeData`/`ColorScheme` puros do Flutter).
- `features/rpg/presentation/xp_evolution_chart.dart` novo: gráfico de
  barras dos últimos 7 dias de XP, construído à mão com
  `TweenAnimationBuilder` (sem `fl_chart` nem outro pacote de gráficos —
  mesma filosofia de poucas dependências já seguida no projeto).
  `XpLedgerRepository.dailyTotals(days, now)` novo, agrupando em Dart
  (dataset pequeno, sem necessidade de `GROUP BY` no SQL).
  `JourneyScreen` ganhou também um cartão de "status" (frequência da
  semana) acima do gráfico.
- `XpLevelBadge` redesenhado: avatar de nível com anel dourado, fundo em
  gradiente, barra de progresso animada (dourada).
- `lib/shared/presentation/`:
  - `fade_slide_in.dart` — entrada animada (fade + leve deslize) dos
    cards da Jornada, escalonada por índice.
  - `level_up_celebration.dart` — explosão de partículas +
    escala elástica (`CustomPainter` + `AnimationController`) exibida
    em `WorkoutSummaryScreen` quando `leveledUp` é verdadeiro. Não
    verificado visualmente no aparelho nesta sessão (precisaria
    acumular XP suficiente para subir de nível de verdade); passou por
    `flutter analyze` e é usado com dados reais na tela de resumo.
  - `pattern_illustration.dart` — bonequinho de traços animado por
    **família de movimento** (`MovementFamily`: empurrar/puxar
    horizontal, agachar/hinge, core, vertical/suporte/equilíbrio,
    mobilidade), não por exercício individual — decisão da pergunta que
    fiz ao usuário sobre mídia de exercício: sem gerar vídeo/gif nem
    baixar mídia de terceiros, ilustração 100% Flutter. Usado grande
    (140px) no `WorkoutPlayerScreen` e pequeno (44px) como miniatura em
    cada linha de exercício no `TrainingPlanScreen`. Confirmado
    visualmente no aparelho — poses distintas por família, animação
    rodando em loop.
- 84 testes automatizados (mais um: `dailyTotals` agrupa por dia
  corretamente), `flutter analyze` sem problemas, build+install+teste
  visual no aparelho confirmados.

### Correções e extensões autônomas (autorizadas pelo usuário)

- **Bug corrigido:** `WorkoutPlayerScreen` agora usa `PopScope` para
  interceptar o botão/gesto de voltar do sistema e chamar a mesma
  lógica de `_pauseAndExit` do botão de pausar — antes, voltar deixava
  a sessão presa em `status = inProgress` em vez de `paused`.
- **Bug corrigido:** `TrainingPlanScreen` passou a observar
  `latestTrainingPlanProvider` reativamente (com `widget.record` como
  fallback enquanto carrega/erro) em vez de depender só do que recebeu
  por construtor — agora "Gerar novamente" atualiza a tela na hora,
  mesmo estando aberta a partir da Jornada.
- **Avaliação real estendida a mais 4 padrões** (`features/assessment`):
  `pull_horizontal`, `squat`, `hinge_posterior_chain`,
  `core_anti_extension` ganharam escadas de autorrelato próprias
  (`fundamental_pattern_anchors.dart`), usando nomes reais de
  `SKILL_TREES.md` §4/7/8/9 (mesmo recorte 0-7 de push_horizontal). A
  bateria "Puxar" de INITIAL_ASSESSMENT.md §4 termina em "barra
  assistida", que é puxada vertical (§5 da árvore) — fora do escopo de
  `pull_horizontal`, então os degraus ficaram só na escada horizontal.
  `ConservativePlacementCalculator` ganhou `calculateForPattern`/
  `calculateSkippedEntirelyForPattern` genéricos (reaproveitando
  `ConservativePlacementResult`, cujo `inputAnchor` virou `String?` em
  vez de `PushHorizontalAnchor?` — mudança que não quebrou nenhum teste
  existente, conferido antes de aplicar). Nova tela opcional
  `OtherPatternsAssessmentScreen` — **não bloqueia** o fluxo principal
  (só push_horizontal continua obrigatório antes do primeiro plano);
  cada padrão deixado em branco continua "não avaliado" indefinidamente.
  Isso ainda não muda o que o motor de treino prescreve (o catálogo
  continua com uma variação só por padrão, sem níveis) — só melhora os
  dados mostrados e prepara terreno para quando o catálogo crescer.
- **Tela "Evolução" nova** (`features/evolution`): colocação atual dos
  5 padrões (com atalho para avaliar os pendentes), recordes informais
  por exercício (maior número de reps já registrado, ignorando séries
  com dor/não concluídas — `WorkoutSessionRepository.bestRepsByExercise`
  novo) e histórico das últimas sessões concluídas
  (`completedSessions` novo). Acessível pelo ícone no AppBar da
  Jornada. Ainda não inclui atributos narrativos nem gráfico por
  exercício ao longo do tempo (RPG_SYSTEM.md §4) — ficou para depois.
- 91 testes automatizados (mais 7 desta parte: 5 sobre as novas escadas
  de colocação, 2 sobre `completedSessions`/`bestRepsByExercise`).
  `flutter analyze` sem problemas. Build de release gerado com sucesso
  (`flutter build apk --release`), mas **não instalado/testado no
  aparelho** — o celular desconectou do `adb` no meio do processo
  (provavelmente ao computador ser bloqueado) e não reconectou; sem
  acesso físico para replugar. Fica pendente confirmar visualmente esta
  leva na próxima sessão.

### Player de treino offline: reps + duração (história vertical v1.2)

- **Dose estruturada no catálogo** (`features/training_plan/domain/
  exercise_catalog.dart`): `DoseType` (`reps`/`duration`/
  `repsOrDuration`), `targetSets`/`targetReps`/`targetSeconds`/
  `minSeconds`/`maxSeconds`/`safetyCapSeconds`/`restSeconds` em
  `CatalogExercise` — alvo vs. realizado agora são campos sempre
  separados (DATA_MODEL.md §4), preenchidos para as 13 entradas
  existentes mais a nova `forearm_plank_full` ("Prancha completa",
  `core_anti_extension`, 3×30s). `PlannedExerciseItem` e
  `WorkoutSessionItem` ganharam os mesmos campos (com `fromJson`
  tolerante — plano/sessão salvos antes desta mudança continuam
  carregando, com `doseType: reps` como fallback).
- **Catálogo de treinos novo e aditivo** (`workout_catalog.dart`):
  `Workout`/`workoutCatalog`, hoje só "Treino A · Fundação" (flexão
  inclinada, agachamento, prancha) — não altera em nada o
  `WeeklyPlanGenerator` existente (decisão confirmada com o usuário via
  pergunta explícita). Telas novas `WorkoutCatalogScreen` e
  `WorkoutDetailScreen`; `JourneyScreen` ganhou um card adicional
  "Treino em destaque" apontando para o catálogo.
- **`ActiveTimer` monotônico** (`workout_session/domain/active_timer.dart`):
  start/pause/resume/elapsed sobre `Stopwatch` (fonte de tempo
  injetável para teste), autoridade do tempo ativo — `Timer.periodic`
  só repinta a UI e decide quando persistir
  (SETTINGS_AND_TIMED_EXERCISES.md §13: "não usar apenas decremento por
  Timer.periodic").
- **Player por repetições** (`log_set_sheet.dart` redesenhado): mostra
  "Série X de Y", alvo sempre visível, contador de repetições realmente
  concluídas começa igual ao alvo (ajuste com `+`/`-`), nada é salvo
  antes de "Concluir série".
- **Player por duração** (`timed_set_player.dart`, novo): máquina de
  estados Ready → Preparing (3-2-1) → Running → Paused ⇄ Running →
  Completed/Stopped; progresso persistido a cada segundo enquanto roda
  e ao ir para segundo plano (`WidgetsBindingObserver`); "Senti dor"
  sempre visível em toda fase, pausa o timer antes de abrir o fluxo de
  segurança.
- **Descanso** (`rest_screen.dart`, novo): contagem regressiva entre
  exercícios, "+15 s", "Pular descanso", "Senti dor", sem persistência
  entre reaberturas do app (risco baixo se o app fechar durante o
  descanso — decisão de escopo registrada no plano desta entrega).
- **Recuperação após fechar o app** (`timed_set_recovery_dialog.dart` +
  wiring em `WorkoutPlayerScreen._checkForActiveTimedSet`): ao reabrir
  com uma série por tempo pendente, pergunta explicitamente Continuar /
  Registrar como interrompida / Descartar — nunca decide sozinho
  (SETTINGS_AND_TIMED_EXERCISES.md §13.3).
- **Mídia local + placeholder** (`shared/presentation/exercise_media.dart`,
  novo): resolve `assets/images/exercises/<slug>/v1/start.png`, cai
  para a ilustração animada (`PatternIllustration`, já existente) via
  `errorBuilder` quando o arquivo não existe — sem manifesto manual.
  Imagens reais adicionadas para os 3 exercícios da história vertical
  (flexão inclinada, agachamento, prancha), copiadas de
  `App_RPG_Calistenia_Documentacao/assets/exercises/starter/` e
  declaradas explicitamente no `pubspec.yaml` (confirmado via
  `flutter build bundle` que os 3 arquivos aparecem no bundle final —
  a entrada `assets/images/` sozinha não garante inclusão recursiva de
  subpastas).
- **Idempotência/persistência transacional**
  (`workout_session_repository.dart`): `clientEventId` determinístico
  (`'$workoutSessionId:$exerciseSlug:$setNumber'`), mesmo padrão de
  `XpLedgerRepository.grant` — `logSet`/`finalizeTimedSet` fazem
  check-before-insert e retornam `bool` (se gravaram ou não), cobrindo
  toque duplo em "Concluir" mesmo em caso de processo morto e reaberto
  antes da primeira gravação terminar. `finalizeTimedSet` roda dentro
  de `_db.transaction()` (insere o log e remove o estado ativo
  atomicamente). Guard em memória (`_submitting`) complementa em
  `WorkoutPlayerScreen`/`TimedSetPlayer` para a UX imediata.
- **Tema atualizado para os tokens v1.2**
  (`VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md` §4.2, confirmado com o
  usuário): substitui a paleta violeta/dourado construída antes por
  `surface.canvas #080A0B`, `surface.card #141819`,
  `surface.elevated #1B2021`, `brand.primary #35E6A1` (verde-menta,
  ações principais), `brand.primaryPressed #20C987`, `rpg.xp #8B5CF6`
  (violeta, reservado só para XP/recompensas — mesmo papel que o
  dourado tinha antes), `text.primary #F7F9F8`, `text.secondary
  #A7B0AD`, `state.warning #F4B740`, `state.danger #F45B69` (mapeado
  para `colorScheme.error`), `divider #2A302F`.
- **Botão "Senti dor" padronizado**: encontrado e corrigido um texto
  inconsistente ("Dor" em vez de "Senti dor" em `timed_set_player.dart`
  e `workout_player_screen.dart`) — o documento exige o rótulo exato
  `Senti dor` em toda tela do player (§8, §12, §28).

### Testes desta história vertical

- `active_timer_test.dart` (6 testes): pausa não conta, retomar soma
  corretamente, `restore` recupera tempo acumulado após fechar o app.
- `workout_session_repository_test.dart` (+9 testes): idempotência de
  `logSet` em toque duplo; ciclo completo de timer ativo persistido
  (`startTimedSet`/`updateTimedSetProgress`/`finalizeTimedSet`/
  `discardActiveTimedSet`), incluindo `finalizeTimedSet` chamado duas
  vezes não duplicar o log.
- `migration_v6_test.dart` (novo): monta um banco no formato real da
  versão 5 (SQL cru, mesma convenção de nomes que o Drift gera),
  insere uma linha de usuário, reabre com o `AppDatabase` atual
  (schemaVersion 6) e confirma que a migração aditiva preserva a linha
  e cria a tabela nova sem erro.
- `exercise_media_test.dart` (novo): cai para `PatternIllustration`
  quando não há imagem local; rótulo semântico presente.
- `workout_player_screen_test.dart` (novo): botão "Senti dor" sempre
  visível; toque duplo em "Registrar série" não abre duas folhas nem
  grava duas séries; formulário de repetições começa igual ao alvo.
- `timed_set_player_flow_test.dart` (novo): fluxo completo 3-2-1 →
  rodando → pausar/retomar → concluir, terminando com um único log e
  sem estado ativo residual. Precisou de `tester.runAsync` com espera
  de parede real (não só o relógio falso do teste) porque o
  `ActiveTimer` usa `Stopwatch` real de propósito (mesma garantia
  contra "trocar o relógio não aumenta o tempo ativo" que vale em
  produção).
- Total: **110 testes automatizados** (eram 91 antes desta parte),
  todos passando. `flutter analyze`: sem problemas.

### Integração do pacote de 195 imagens reais (`App_RPG_Exercise_Images/`)

Continuação direta da pendência registrada acima: o usuário confirmou a
integração completa, seguindo `App_RPG_Exercise_Images/CLAUDE_CODE_PROMPT.md`
à risca.

**Antes de editar**, o pacote foi inspecionado e comparado ao código
existente: `exercise_media_catalog.json` usa uma taxonomia de slugs em
português (`flexao_inclinada_media`, `agachamento_livre`, ...) totalmente
diferente dos slugs já usados pelo motor de treino
(`push_up_incline`, `sit_to_stand_squat`, ...) — os dois namespaces
**não foram unificados** (isso exigiria renomear conteúdo já em produção
sem necessidade, indo contra a instrução explícita do prompt). Em vez
disso, foi construída uma associação explícita, um campo por exercício
(`CatalogExercise.mediaSlug`), com cada valor justificado por uma de duas
evidências, nunca por comparação frágil de nome:

1. **Referência cruzada por `starter_file`**: 4 dos 195 registros do
   catálogo citam no campo `starter_file` o nome exato de um arquivo já
   usado nesta mesma sessão, numa entrega anterior, para um slug
   conhecido (`push_up_incline_start.png` → `push_up_incline`,
   `bodyweight_squat_bottom.png` → `sit_to_stand_squat`,
   `forearm_plank_hold.png` → `forearm_plank_full`,
   `australian_row_top.png`, usado só para confirmar a correspondência
   de categoria `puxar_horizontal_escapula` ↔ `pull_horizontal`, sem
   exercício prescrito equivalente ainda). É a evidência mais forte
   possível: o próprio dado aponta para o slug certo.
2. **Nome de nó idêntico ao rótulo já usado em `SKILL_TREES.md`**: os
   quatro padrões de avaliação (`fundamental_pattern_anchors.dart`,
   `push_horizontal_anchor.dart`) já citam os nomes exatos dos nós de
   `SKILL_TREES.md` nos seus mapas de nível 0-7 — comparando esses
   mapas com as 8 primeiras entradas de cada categoria correspondente
   no catálogo de imagens, os nomes batem palavra por palavra em quase
   todos os níveis (confirmado, não presumido, lendo os dois lados).
   Isso deu confiança para associar `category_slug` de imagem ↔
   `pattern` do app: `empurrar_horizontal`↔`push_horizontal`,
   `puxar_horizontal_escapula`↔`pull_horizontal`,
   `agachamento_unilateral`↔`squat` (a árvore cobre agachamento
   bilateral nos níveis 0-6 antes de virar unilateral — não é um
   descompasso de eixo de movimento, é a mesma árvore contínua),
   `cadeia_posterior`↔`hinge_posterior_chain`,
   `core_anterior_compressao`↔`core_anti_extension`.

Com essas 5 correspondências de categoria confirmadas, 9 dos 13
exercícios prescritos ganharam `mediaSlug` com alta confiança. Mais 2
(`pike_push_up`, `wall_assisted_handstand`) ganharam associação de
confiança **média** (nome do nó não é idêntico, é uma aproximação
razoável — documentado em comentário no próprio código). 2 ficaram
**sem associação** por falta de correspondência segura
(`warmup_joint_mobility` — aquecimento não é nó de nenhuma árvore;
`parallel_bar_support_hold` — nenhum nó de `dips_suporte` corresponde
com segurança a suporte estático não assistido) e continuam mostrando o
placeholder animado, o que é seguro e esperado.

**O que foi feito:**

- `assets/images/exercises/<category_slug>/<slug>.png` — as 195 imagens
  mescladas na pasta já existente (`push_up_incline/`,
  `sit_to_stand_squat/`, `forearm_plank_full/` preservadas, sem
  colisão: convenção de pasta diferente). Total 198 arquivos.
- `assets/data/exercise_media_catalog.json` — o catálogo JSON completo,
  copiado como asset de dados (não transcrito à mão em Dart, para não
  arriscar erro de digitação em 195 entradas).
- `pubspec.yaml`: os 14 novos subdiretórios de categoria + o JSON
  registrados explicitamente (não só `assets/images/exercises/` — ver
  nota técnica abaixo). Verificado via `flutter build bundle` que os
  198 arquivos e o JSON entram no bundle final.
- `lib/shared/domain/exercise_media_catalog.dart` (novo):
  `MediaCatalogEntry` (com `fromJson`) e `MediaCatalogIndex` (índice por
  `slug` e por `categorySlug:level`, este último reaproveitável pelas
  escadas de avaliação existentes, ainda não usado por nenhuma tela).
- `lib/shared/data/exercise_media_catalog_provider.dart` (novo):
  `FutureProvider<MediaCatalogIndex>` que lê o JSON via `rootBundle`
  uma única vez (Riverpod cacheia o resultado).
- `lib/shared/presentation/exercise_media_placeholder.dart` (novo):
  `ExerciseMediaPlaceholder`, nome pedido explicitamente pelo prompt —
  por baixo, reaproveita `PatternIllustration` (já existente) em vez de
  criar uma silhueta nova.
- `lib/shared/presentation/exercise_media.dart` (reescrito):
  `ExerciseMedia` virou `ConsumerWidget`. Ordem de resolução: (1)
  `mediaSlug` explícito, se existir no catálogo de 195 imagens; (2)
  convenção antiga `assets/images/exercises/<slug>/v1/start.png` (os 3
  exercícios da entrega anterior); (3) `ExerciseMediaPlaceholder`, via
  `errorBuilder` — cobre asset ausente e erro de decodificação sem
  travar a sessão, e cobre também o caso do catálogo ainda estar
  carregando (não bloqueia a primeira renderização).
- `CatalogExercise.mediaSlug` (nullable) em `exercise_catalog.dart`,
  propagado por todo o caminho de congelamento de dados já existente
  (mesmo padrão dos campos de dose): `PlannedExerciseItem.mediaSlug` →
  `WeeklyPlanGenerator._toItem` → `WorkoutSessionItem.mediaSlug` →
  `WorkoutDetailScreen._toSessionItem`. `exerciseCatalogVersion` subiu
  para `minimal-catalog-v3`.
- `WorkoutCatalogScreen`/`WorkoutDetailScreen`/`WorkoutPlayerScreen`/
  `RestScreen`: todo `ExerciseMedia(...)` já existente passou a receber
  `mediaSlug: item.mediaSlug`.
- Pré-carregamento (`_precacheAdjacentMedia` em `WorkoutPlayerScreen`):
  só a imagem do exercício atual e a seguinte, nunca a sessão inteira
  (item 11 do prompt) — usa `precacheImage(..., onError: (_, __) {})`;
  o parâmetro `onError` é necessário porque o pipeline de imagem do
  Flutter reporta erro de asset ausente via `FlutterError.onError` de
  forma síncrona, independente de `.catchError` na `Future` retornada
  (achado ao rodar os testes — sem isso, uma imagem ausente derrubava a
  tela mesmo com o erro "capturado").
- **Nenhuma migration Drift nova**: o catálogo de exercícios/mídia é
  dado estático em Dart/JSON, não uma tabela — nunca existiu no banco
  (mesma decisão já registrada para o catálogo de exercícios original,
  "recomputável, não precisa de tabela"). O prompt pede migration "se
  houver banco Drift já criado" para o que muda — aqui nada mudou no
  schema, então nenhuma migration foi necessária ou criada.

**Nota técnica sobre o pubspec**: o prompt pede registrar
`assets/images/exercises/` uma única vez. Optou-se por listar os 14
subdiretórios de categoria explicitamente em vez de só o diretório pai,
porque a entrega anterior desta sessão já havia constatado, testando
com `flutter build bundle`, que uma entrada de pasta no `pubspec.yaml`
não inclui de forma confiável subpastas aninhadas sem cada uma ser
listada. É mais verboso, mas testado e confirmado a funcionar para as
195 imagens (nenhuma ficou de fora do bundle).

**Testes novos** (110 → **119 testes automatizados**, todos passando;
`flutter analyze` e `dart format .` sem problemas):

- `test/shared/domain/exercise_media_catalog_test.dart` (novo, dados
  puros, sem widget): catálogo carrega 195 entradas; todo slug é único;
  todo `asset_path` existe no disco; nenhum caminho absoluto/URL;
  nenhuma imagem duplicada fisicamente (as duas ocorrências
  compartilhadas entre árvores citadas no README do pacote — "Wall walk
  parcial", "Handstand livre consistente" — têm só uma entrada cada no
  JSON, não duas); índice por categoria+nível encontra os nós já
  citados pelas escadas de avaliação existentes; **todo `mediaSlug` já
  associado em `exercise_catalog.dart` existe de fato no catálogo de
  195 imagens** (pega erro de digitação na associação antes de virar
  bug silencioso em produção).
- `test/shared/presentation/exercise_media_test.dart` (+1 teste): usa a
  imagem do catálogo novo quando `mediaSlug` é fornecido e existe
  (com override do provider — carregar o JSON de verdade via
  `rootBundle` trava para sempre dentro de `testWidgets` sem tempo de
  parede real, achado desta sessão); `BoxFit.contain` confirmado;
  fallback para `ExerciseMediaPlaceholder` confirmado por tipo, não só
  por `PatternIllustration` (que fica por baixo).
- `test/features/workout_session/timed_set_player_flow_test.dart`
  (+1 teste): "timer continua funcionando mesmo quando a mídia do
  exercício falha" — sessão com `exerciseSlug`/`mediaSlug` que não
  resolvem imagem nenhuma, ainda assim passa por 3-2-1 → rodando
  normalmente.

**Exercícios/imagens ainda sem associação segura** (mostram placeholder
animado, não a foto real):

- `warmup_joint_mobility` (aquecimento — não é nó de nenhuma árvore).
- `parallel_bar_support_hold` (suporte estático em paralelas — nenhum
  nó de `dips_suporte` corresponde com segurança).
- As 190+ imagens do catálogo que não correspondem a nenhum dos 13
  exercícios hoje prescritos pelo motor de treino (níveis avançados de
  todas as 14 árvores, incluindo front lever, back lever, handstand
  livre, muscle-up etc.) — carregadas e disponíveis por `slug`/
  `categorySlug:level` no índice, mas **nenhuma tela ainda as exibe**;
  ficou fora do escopo desta entrega ligar as escadas de avaliação
  (`fundamental_pattern_anchors.dart`, telas de avaliação/Evolução) à
  mídia nova, para não expandir o raio de alteração além do que o
  prompt pediu ("catálogo, detalhes do treino e player"). É a extensão
  natural mais óbvia para uma próxima sessão — o `MediaCatalogIndex.
  byCategoryLevel` já existe pronto para isso.
- **Nenhuma revisão biomecânica profissional foi feita nem marcada como
  concluída** — todas as 195 imagens permanecem com
  `visual_review_status = requires_professional_review` (ou o que veio
  no JSON original); a associação feita aqui é só de dado (slug ↔
  slug), não uma validação de que a imagem está correta ou seguramente
  prescritível.

**Impacto no tamanho do app**: as 195 imagens somam ~44 MB (PNG
1024×1024, fundo transparente). Ainda não medido o impacto no APK final
(`flutter build apk --release` desta leva não foi gerado nesta sessão —
ver Riscos/bloqueios, aparelho segue desconectado).

### Correções dos bugs reportados (2026-07-26)

Continuação da sessão anterior: os 2 bugs de mídia/contraste
diagnosticados em `IMPLEMENTATION_BACKLOG.md` (achados pelo usuário
usando o app de verdade, 2026-07-24) foram corrigidos.

- **`TrainingPlanScreen` não mostrava as imagens reais**: `_ExerciseRow`
  (`lib/features/training_plan/presentation/training_plan_screen.dart`)
  chamava `PatternIllustration` direto em vez de `ExerciseMedia`. Trocado
  pela chamada correta, passando `mediaSlug: item.mediaSlug` — mesmo
  widget já usado em `WorkoutCatalogScreen`/`WorkoutDetailScreen`/
  `WorkoutPlayerScreen`/`RestScreen`. A tela do plano semanal agora
  também mostra foto real para os 9 exercícios com `mediaSlug`
  associado, com fallback automático para a ilustração animada nos
  demais (mesma lógica de `ExerciseMedia`, nada novo).
- **Contraste no card de destaque da Jornada**: `_NextSessionCard`
  (`lib/features/journey/presentation/journey_screen.dart`) definia
  `Card(color: colorScheme.primaryContainer)` mas o `title`/`subtitle`/
  `trailing` do `ListTile` não tinham cor própria, herdando o texto
  claro pensado para o fundo escuro padrão do app. Corrigido definindo
  `TextStyle(color: colorScheme.onPrimaryContainer)` explicitamente nos
  três. Conferidos os demais `Card` da mesma tela (`_StatusCard`,
  "Treino em destaque", histórico de XP) — nenhum outro define `color:`
  explícito no `Card`, então nenhum tinha o mesmo problema.
- `flutter analyze`: sem problemas. `flutter test`: **119 passed, 0
  failed** (nenhum teste novo — mudança visual/estrutural sem lógica
  nova para cobrir; os testes existentes de widget continuam
  encontrando os textos/imagens pelo mesmo `find.text`/`find.byType`).
- Não testado no aparelho físico nesta sessão (sem acesso ao `adb`
  agora) — fica para a próxima verificação manual.

### Catálogo em camadas para os 4 padrões novos (2026-07-26)

Continuação da mesma sessão: `pull_horizontal`, `squat`,
`hinge_posterior_chain` e `core_anti_extension` ganharam o mesmo
tratamento em camadas que `push_horizontal` já tinha (catálogo com
múltiplas variações por nível de capacidade + `MasteryRule`/promoção
automática de domínio). Antes, esses 4 padrões tinham só **uma**
variação conservadora no catálogo, prescrita não importa o nível — o
mesmo bug já corrigido para `push_horizontal` ("Flexão na parede" para
quem já fazia flexão completa") continuava latente para os outros 4.

**Descoberta que expandiu o escopo:** `core_anti_extension` tem
variações por duração (prancha), não só por reps, e o
`MasteryEvaluator` só sabia avaliar por `repsCompleted` — séries por
tempo sempre gravam `repsCompleted: 0`
(`workout_session_repository.dart`, `finalizeTimedSet`). Sem estender
isso, a metade "por duração" desse padrão nunca confirmaria domínio.
`MasteryRule` ganhou `minSecondsPerSet` (opcional, junto com
`minRepsPerSet` que também virou opcional) e `SetLog` ganhou
`activeDurationMs` (espelhando a coluna já existente em
`set_log_records`); `MasteryEvaluator._meetsThreshold` decide qual
limiar usar por regra.

**Escada de exercícios por padrão** (cadência igual a
`push_horizontal`: bucket nomeado pelo nível mais alto do grupo, ladeira
aberta no topo; todos os `mediaSlug` conferidos linha a linha em
`exercise_media_catalog.json` antes de usar, e depois confirmados pelo
teste já existente que valida todo `mediaSlug` do catálogo contra as
195 imagens):

- `pull_horizontal` (0-7): `scapular_retraction_bodyweight`/`band_row`
  (existentes, 0-1, alternativas por equipamento) → novo
  `incline_australian_row` (2-3) → novo
  `horizontal_row_straight_legs` (4-5) → novo `assisted_archer_row`
  (6-100).
- `squat` (0-5): novo `medium_bench_sit_to_stand` (0-1) → novo
  `assisted_squat_comfortable_range` (2-3) → `sit_to_stand_squat`
  (existente, 4-100, `namePtBr` simplificado pra "Agachamento livre").
- `hinge_posterior_chain` (0-5): `glute_bridge` (existente, 0-1) → novo
  `good_morning_bodyweight` (2-3) → novo `unilateral_bridge` (4-100).
- `core_anti_extension` (0-7): `dead_bug_simplified` (existente, 0-2) →
  novo `incline_plank` (3-4, duração) → `forearm_plank_full`
  (existente, 5-6, duração, ganhou nível pela primeira vez) → novo
  `hollow_tuck_hold` (7-100, duração).

Todas as `MasteryRule` novas usam os mesmos placeholders de MVP de
`push_horizontal` (`minQualifyingSets: 2`, `confirmationsRequired: 2`,
`minHoursBetweenConfirmations: 48`) — mesma ressalva de números
pendentes de revisão profissional.

**Generalização de código** (`pattern` como parâmetro em vez de
hardcoded `push_horizontal` em todo lugar, reaproveitando a
infraestrutura genérica que já existia — `CapabilityEstimateRepository`,
`latestCapabilityEstimateProvider`,
`ConservativePlacementCalculator.calculateForPattern` não mudaram):

- `exercise_catalog.dart`: `pushHorizontalExerciseForLevel` virou
  `exerciseForPatternAndLevel(pattern, level)`.
  `exerciseCatalogVersion` subiu para `minimal-catalog-v4`.
- `weekly_plan_generator.dart`: `generate()` troca
  `pushHorizontalCapabilityLevel: int?` por
  `capabilityLevelsByPattern: Map<String, int?>` — cada padrão do
  template resolve seu próprio nível (`?? 0` se ausente do mapa), em
  vez de todos compartilharem o nível de push_horizontal.
- `mastery_rules.dart`: `pushHorizontalMasteryRules` virou
  `masteryRulesByPattern: Map<String, Map<String, MasteryRule>>`
  (padrão → slug → regra), com os 5 padrões.
- `progression_repository.dart`: `evaluateAndPromotePushHorizontal`
  virou `evaluateAndPromote({pattern, currentLevel,
  placementComputedAt, now})`. Nível máximo da escala passou a ser
  derivado de `levelNamesByPattern[pattern].keys.reduce(max)` (novo
  mapa, combina `pushHorizontalLevelNames` +
  `fundamentalPatternLadders`) em vez do `>= 7` fixo — cobre as escadas
  mais curtas (`squat`/`hinge_posterior_chain`, 0-5) corretamente.
- `xp_rules.dart`: `awardsForCompletedSession` troca
  `masteryPromoted`/`masteryPattern`/`masteryNewLevel` (um só) por
  `masteryPromotions: Map<String, int>` — permite mais de um padrão
  promovido na mesma sessão (ex.: full body day confirma push_horizontal
  e squat juntos), um `XpAward` de domínio por entrada.
- `workout_player_screen.dart`: `_completeSession` avalia progressão
  pra `push_horizontal` (colocação já vinha por construtor) **e** os 4
  padrões de `fundamentalPatternLadders`, buscando a colocação mais
  recente de cada um via `latestCapabilityEstimateProvider(pattern)`.
  **Decisão de escopo:** só avalia um padrão se já existe alguma
  colocação salva pra ele (`placement != null`) — sem isso não há
  `placementComputedAt` como marco de "que sessões contam como
  evidência". Quem nunca respondeu a autoavaliação opcional
  (`OtherPatternsAssessmentScreen`) continua recebendo a variação de
  nível 0 no plano (isso já funcionava), só não acumula confirmações de
  domínio pra esse padrão — resolver isso é o próximo item do backlog
  (teste físico periódico/reavaliação sob demanda), não regressão desta
  entrega.
- `workout_summary_screen.dart`: `masteryResult` (um só) virou
  `masteryResults: Map<String, MasteryEvaluationResult>` — um card por
  padrão promovido/com progresso parcial, com rótulo amigável
  (reaproveita `FundamentalPatternLadder.titlePtBr`).
- `generate_training_plan_screen.dart`/`training_plan_screen.dart`:
  novo `resolveCapabilityLevelsByPattern(ref, pushHorizontalLevel)` em
  `training_plan_providers.dart` (reaproveitado pelos dois lugares que
  chamam `generator.generate(...)`), monta o mapa lendo a colocação
  mais recente de cada um dos 4 padrões opcionais.
- `workout_catalog.dart`/`WorkoutDetailScreen` ("Treino A · Fundação")
  **não mudaram** — catálogo fixo, deliberadamente sem variação por
  nível, fora do escopo (o alvo era o motor de treino semanal).

**Testes** (119 → **140 testes automatizados**, todos passando;
`flutter analyze` e `dart format .` sem problemas): novo
`test/features/training_plan/exercise_catalog_test.dart` (cobertura
0..maxLevel sem buraco/sobreposição pros 5 padrões + variação de
elástico pro `pull_horizontal`); `mastery_evaluator_test.dart` ganhou um
grupo pra `minSecondsPerSet`; `progression_repository_test.dart` ganhou
teste de promoção de `squat` (não-push_horizontal) e dois de promoção
por duração (`core_anti_extension`, incluindo o caso de duração abaixo
do limiar); `xp_rules_test.dart` e `weekly_plan_generator_test.dart`
atualizados pras novas assinaturas, com um teste novo cada
(duas promoções simultâneas; nível de `squat` variando a prescrição).

**Não testado no aparelho físico nesta sessão** (sem `adb` disponível) —
fica pendente confirmar visualmente na próxima verificação manual.

### Mídia real nas telas de avaliação/Evolução (2026-07-26)

Continuação da mesma sessão: o índice `MediaCatalogIndex.byCategoryLevel`
já existia pronto desde a integração das 195 imagens, mas nenhuma tela
de avaliação/colocação o usava — todas mostravam só texto ou a
ilustração animada, mesmo quando havia foto real disponível para aquele
nó específico da escada.

**Novo widget compartilhado** (`lib/shared/presentation/
pattern_level_media.dart`): `PatternLevelMedia(pattern, level, namePtBr,
size)` resolve `mediaSlug` a partir de `pattern`+`level` via
`patternMediaCategorySlug` (mapa novo, traduz o namespace de padrão do
app — `push_horizontal`, `squat`, ... — para o `categorySlug` do JSON —
`empurrar_horizontal`, `agachamento_unilateral`, ... — os dois nunca
foram unificados, mesma decisão já registrada na integração das 195
imagens) e delega pro `ExerciseMedia` já existente (mesmo fallback pro
placeholder animado quando não há associação ou o catálogo ainda está
carregando).

**Detalhe que exigiu atenção:** o `level` usado difere conforme o
contexto. Nas telas de **autoavaliação** (uma imagem por opção de
autorrelato), o nível certo é `anchor.skillLevel` — o nó que a própria
opção descreve (`PushHorizontalAnchor.wall.skillLevel == 1` mostra a
imagem de "Flexão na parede", nível 1). Na **Evolução** (imagem da
colocação já salva), o nível certo é `estimate.level` diretamente — que
já é um nível **abaixo** do anchor reportado, porque
`ConservativePlacementCalculator` sempre coloca conservadoramente um
nível abaixo do que a pessoa disse conseguir
(`level = anchor.skillLevel - 1`). Usar `anchor.skillLevel` na Evolução
mostraria a imagem errada (um nível acima do que foi de fato salvo).
Confirmado node a node comparando os nomes de `pushHorizontalLevelNames`/
`fundamental_pattern_anchors.dart` com os rótulos dos anchors antes de
decidir — não presumido.

**Telas atualizadas:**

- `AssessmentSkipTestScreen` (colocação obrigatória de push_horizontal):
  cada `RadioListTile<PushHorizontalAnchor>` ganhou `secondary:
  PatternLevelMedia(...)` com o nível do próprio anchor.
- `OtherPatternsAssessmentScreen` (autoavaliação opcional dos 4 padrões
  novos): mesma coisa, um `PatternLevelMedia` por anchor de cada
  `FundamentalPatternLadder`.
- `EvolutionScreen._PatternPlacementTile`: `leading:
  PatternLevelMedia(...)` com `estimate.level`, só quando já existe uma
  colocação salva (`estimate != null`) — "não avaliado" continua sem
  imagem, não faz sentido mostrar uma sem nível pra buscar.
- `PlacementResultScreen`: imagem de destaque (120px) da variação que
  acabou de ser salva, acima do nome do nível.

**Testes** (140 → **142 testes automatizados**, todos passando;
`flutter analyze` e `dart format .` sem problemas): novo
`test/shared/presentation/pattern_level_media_test.dart` — resolve a
imagem certa via `categorySlug:level` (com override do provider, mesmo
padrão de `exercise_media_test.dart` — carregar o JSON real via
`rootBundle` trava sem tempo de parede real dentro de `testWidgets`) e
cai pro placeholder animado quando o nível não tem associação.

**Verificação manual no aparelho físico (`7549GMFUDA4DKZW8`, mesma
sessão, `adb` reconectado depois):** `flutter build apk --release` +
`adb install -r` sem apagar dados reais já salvos (nível 1, 70 XP,
histórico preservado). Confirmado por interação real:

- Regenerar o plano ("Gerar novamente") prescreveu as variações novas
  corretamente a partir da colocação real salva do usuário — ex.:
  "Remada australiana inclinada" (pull_horizontal, nível 2-3, novo
  nesta sessão) e "Agachamento livre" com o nome simplificado (squat,
  nível 4-100) — ambos com foto real, não mais placeholder.
- `EvolutionScreen`: as 5 colocações mostram a foto do nó exato do
  nível salvo (ex.: nível 0 → "Ponte de glúteos curta", nível 5 →
  "Prancha de joelhos"), batendo com o que o motor de treino prescreveu
  no mesmo plano.
- `OtherPatternsAssessmentScreen`: cada opção de autorrelato dos 4
  padrões mostra foto real distinta, sem repetição/troca entre opções.
- `adb logcat` do processo do app durante toda a navegação: nenhum
  crash, nenhuma exceção fatal.
- Não testado isoladamente: `PlacementResultScreen` (mesmo widget já
  validado em duas outras telas, risco baixo) e `AssessmentSkipTestScreen`
  (não reexercitada pois a colocação de push_horizontal já existia).

## Banco/migrations

- Backend Supabase segue pausado (ADR-0006); `supabase/migrations/`
  continua vazio. Sync (`OutboxEvents`) segue reservada e não usada
  (ADR-0005, `core/sync/README.md`).
- Schema local Drift em `schemaVersion = 6`:
  - `1→2`: recria `CapabilityEstimateRecords` (`inputAnchor` opcional).
  - `2→3`: cria `training_plan_records`.
  - `3→4`: cria `workout_session_records` e `set_log_records`.
  - `4→5`: cria `xp_ledger_records`.
  - `5→6` (**nova nesta parte**): adiciona colunas nullable em
    `set_log_records` (`targetReps`, `targetSeconds`,
    `activeDurationMs`, `completionReason`, `clientEventId`) via
    `m.addColumn` — **aditivo**, não recria a tabela, diferente das
    migrações anteriores, porque agora pode haver dados reais de
    usuário (o app já foi instalado e usado no aparelho físico em
    sessões anteriores). Cria `active_timed_set_records` (tabela nova,
    PK `workoutSessionId`, um timer ativo por sessão). Testada
    explicitamente em `migration_v6_test.dart` com um banco montado no
    formato real da v5.

## Testes executados

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sem problemas |
| `flutter test` | 91 passed, 0 failed (leva anterior) |
| `dart run build_runner build` | OK |
| `flutter build apk --release` | OK (55,7MB), gerado duas vezes na sessão |
| `adb install -r` no aparelho físico | OK na 1ª leva (tema escuro etc.), testado manualmente via `adb shell input`. **Não repetido na 2ª leva** (bugs/avaliação/Evolução) — aparelho desconectou do `adb` |
| `flutter analyze` (história vertical player reps+duração) | Sem problemas |
| `flutter test` (história vertical player reps+duração) | **110 passed, 0 failed** |
| `flutter build bundle` | OK — usado para confirmar que os 3 assets novos de exercício entram no bundle final |
| `adb devices` (história vertical player reps+duração) | Nenhum dispositivo listado — aparelho segue desconectado (ver Riscos/bloqueios) |
| `flutter analyze` (integração das 195 imagens) | Sem problemas |
| `dart format .` | 64 arquivos reformatados, nenhum erro |
| `flutter test` (integração das 195 imagens) | **119 passed, 0 failed** |
| `flutter build bundle` (integração das 195 imagens) | OK — confirmado que as 198 imagens (195 novas + 3 da entrega anterior) e `exercise_media_catalog.json` entram no bundle final |
| `adb devices` (integração das 195 imagens) | Nenhum dispositivo listado — aparelho segue desconectado |
| `adb devices` (verificação manual) | Aparelho `7549GMFUDA4DKZW8` reconectado |
| `flutter build apk --release` (verificação manual) | OK (100,6MB) |
| `adb install -r` no aparelho físico (verificação manual) | OK — testado manualmente via `adb shell input`/`uiautomator`: catálogo/detalhe/player/descanso com imagens reais, recuperação de série por tempo após reabrir o app, sem crashes no `logcat` |
| `flutter analyze` (catálogo em camadas, 2026-07-26) | Sem problemas |
| `flutter test` (catálogo em camadas, 2026-07-26) | **140 passed, 0 failed** |
| `dart format .` (catálogo em camadas, 2026-07-26) | 2 arquivos reformatados, nenhum erro |
| `adb devices` (catálogo em camadas, 2026-07-26) | Não executado — sem acesso ao aparelho físico nesta sessão |
| `flutter analyze` (mídia na avaliação/Evolução, 2026-07-26) | Sem problemas |
| `flutter test` (mídia na avaliação/Evolução, 2026-07-26) | **142 passed, 0 failed** |
| `dart format .` (mídia na avaliação/Evolução, 2026-07-26) | 1 arquivo reformatado, nenhum erro |

## Decisões e ADRs

- ADR-0001 a 0006 seguem válidas.
- Decisões desta sessão (não formalizadas em ADR por serem locais e
  pequenas):
  - Catálogo de exercícios do motor de treino é deliberadamente mínimo
    (1-2 variações por padrão) — não é o catálogo editorial completo de
    EXERCISE_SCHEMA.md §7 (15+ variações, mídia, revisão profissional).
    Cresce em sessão futura dedicada a conteúdo.
  - Plano semanal e sessão de treino são armazenados como JSON dentro de
    uma linha (não tabelas relacionais normalizadas por sessão/item),
    porque são recomputáveis a partir de preferências+capacidade e ainda
    não há necessidade de consulta relacional. `set_log_records` é a
    exceção: uma linha por série, pensando em histórico/progressão
    futuros que vão precisar consultar por exercício — decisão que já
    pagou o investimento nesta mesma sessão, ao alimentar a progressão.
  - `PerceivedEffort` (5 categorias de FR-022/TRAINING_ENGINE.md §8)
    substitui RPE/RIR numérico no registro de série — mais rápido de
    preencher em treino, e é literalmente o que as FRs pedem.
  - Progressão só cobre `push_horizontal` (único padrão com colocação
    real hoje) e só promove +1 nível por vez, nunca pula direto para a
    próxima variação da escada — "menor incremento possível"
    (PROGRESSION_RULES.md §3/§9). `CapabilityEstimateRepository` ganhou
    `saveEstimate(...)` genérico para não duplicar a lógica de insert
    entre colocação conservadora e confirmação de domínio.
  - XP roda client-side por enquanto (ver ressalva de FR-040 acima) —
    decisão consciente de fase, não descuido: seguindo o mesmo padrão já
    estabelecido para triagem/motor de treino/progressão neste projeto.
  - Teto diário de XP repetível existe (`dailyRepeatableXpCap`), mas os
    demais sinais de integridade de ECONOMY_AND_ANTI_ABUSE.md §4
    (sessões sobrepostas, duração impossível, relógio alterado etc.) não
    foram implementados — não fazem sentido sem múltiplos usuários/
    competição para proteger ainda.
  - Missões deliberadamente incompletas frente a RPG_SYSTEM.md §8: só
    entrou o que é honestamente derivável hoje. "Fazer check-in" e
    "descansar quando o plano indicar" ficaram de fora por não haver
    check-in nem conceito de dia de descanso prescrito distinto de dia
    de treino; "revisar progresso" ficou de fora por não haver uma tela
    de Evolução para gerar esse evento.
  - Mídia de exercício (perguntado ao usuário, ele escolheu): ilustração
    animada 100% Flutter por família de movimento, não vídeo/gif real.
    Motivo: não há como gerar vídeo, e baixar mídia de terceiros sem
    saber a licença/origem seria problemático. Cinco famílias cobrem os
    nove padrões do catálogo — se o catálogo editorial completo (com
    mídia real) chegar algum dia, essas ilustrações são o degrau
    intermediário, não o destino final (EXERCISE_SCHEMA.md §5 pede
    vídeo com ângulo, regressão e saída — isso continua pendente).
  - Tema escuro fixo (`ThemeMode.dark`), sem alternância clara/escuro —
    o usuário pediu tema escuro para "melhor visualização", não pediu
    opção configurável. Se um tema claro voltar a ser necessário,
    `buildCalisthenicsRpgTheme()` já está isolado em `app/theme.dart`
    para virar dois temas facilmente.
  - Gráfico de evolução e animações são só Flutter puro (`CustomPainter`,
    `TweenAnimationBuilder`, `AnimationController`) — nenhum pacote novo
    adicionado (`fl_chart`, `lottie`, `confetti` etc. foram considerados
    e descartados), mantendo a filosofia de poucas dependências já
    seguida no resto do projeto.
  - `JourneyScreen` concede XP de missões num `initState` +
    post-frame-callback, não dentro do `FutureProvider` de leitura —
    separação deliberada entre "avaliar" (puro, seguro para watch
    reativo) e "conceder" (efeito colateral, disparado uma vez por
    entrada na tela, mesmo padrão de ação explícita usado em toda a
    sessão).

## Pendências

Lista histórica e narrativa, com o contexto de cada item. Para a versão
priorizada e acionável ("o que fazer a seguir", sem prosa), ver
`docs/IMPLEMENTATION_BACKLOG.md` — mantenha os dois sincronizados: item
concluído sai daqui e do backlog; item novo entra nos dois.

- Textos de triagem/segurança seguem placeholders — pendente de revisão
  profissional (SAFETY_AND_SCREENING.md §10).
- Catálogo de exercícios mínimo — precisa crescer antes de qualquer
  conteúdo além dos padrões fundamentais.
- Progressão não cobre regressão temporária, platô, deload nem os demais
  padrões além de `push_horizontal` (PROGRESSION_RULES.md §4-6).
- Sem campanha/fases narrativas, atributos, Boss Test, classes nem
  ranking (RPG_SYSTEM.md §4-7, §10-11) — só "XP e nível" + missões
  diárias/semanais estão implementados.
- Missões diárias/semanais cobrem só 3+3 dos ~10 tipos de RPG_SYSTEM.md
  §8 (ver decisão acima); check-in/prontidão não existe como
  funcionalidade em lugar nenhum do app ainda.
- `JourneyScreen` e `EvolutionScreen` são as únicas telas novas de
  navegação — Habilidades e Perfil (2 dos 5 destinos de
  SCREENS_AND_FLOWS.md §1) não existem, nem navegação por abas (tudo é
  push de tela a partir da Jornada).
- Recordes da tela Evolução são só "maior número de reps por exercício"
  — não separam por variação/amplitude/assistência/contexto como
  PROGRESSION_RULES.md §7 pede; e "atributos narrativos"
  (força/resistência/controle/...) de RPG_SYSTEM.md §4 continuam sem
  implementação nenhuma.
- Sem timer/descanso, substituição de exercício em tela ou vídeo no
  player (SCREENS_AND_FLOWS.md §4 lista esses itens; ficaram fora do
  escopo da primeira versão do player).
- Promoção de domínio não regenera o plano automaticamente — usuário
  precisa tocar "Gerar novamente" (decisão deliberada, ver acima).
- ~~Bug: `TrainingPlanScreen` não atualiza sozinha após regenerar~~ —
  **corrigido** (agora observa `latestTrainingPlanProvider`).
- ~~Bug: voltar do sistema não pausa a sessão~~ — **corrigido** (
  `PopScope` no `WorkoutPlayerScreen` chama a mesma lógica do botão de
  pausar). Nenhum dos dois foi confirmado no aparelho físico ainda —
  fica para a próxima sessão (ver nota sobre o `adb` desconectado).
- ~~Avaliação real agora cobre 5 padrões, mas o motor de treino ainda
  não usa isso para variar o que prescreve nesses 4~~ — **corrigido em
  2026-07-26**: catálogo em camadas + `MasteryRule`/promoção automática
  para os 4 padrões novos, verificado no aparelho físico. Ver seção
  "Catálogo em camadas para os 4 padrões novos" acima.
- `LevelUpCelebration` não foi vista rodando de verdade no aparelho
  (precisaria acumular 125 XP para subir do nível 1) — só validada por
  `flutter analyze` e revisão de código. Vale conferir visualmente na
  próxima vez que alguém subir de nível de verdade.
- Ilustrações de exercício são só 5 poses estilizadas por família, não
  demonstração técnica real (sem critério de repetição válida, erro
  comum, regressão — EXERCISE_SCHEMA.md §5 continua pendente).
- `flutter run` em modo debug historicamente instável neste Windows
  (contenção de lock do Gradle) — usar `flutter build apk --release` +
  `adb install -r` quando for instalar no aparelho.
- `adb shell uiautomator dump` mostrou-se não confiável neste aparelho
  específico (abriu o assistente de acessibilidade do Android sozinho
  mais de uma vez) — preferir screenshots + coordenadas calculadas a
  partir de `adb shell wm size` em testes futuros neste dispositivo.
- **Novas pendências desta história vertical (player reps+duração)**,
  todas registradas como decisão de escopo deliberada no plano, não
  esquecimento:
  - Sem seletor de duração personalizável pré-sessão (chips
    20s/30s/45s de SETTINGS_AND_TIMED_EXERCISES.md §9.1/§12.3) — o
    player usa a duração recomendada do exercício como alvo fixo.
  - Sem página de Configurações, perfil físico/IMC ou reinício de
    jornada (documento próprio, prompt separado do que foi pedido
    aqui).
  - Catálogo de treinos tem só "Treino A · Fundação" — sem filtros por
    nível nem múltiplos treinos ainda.
  - Placeholder de mídia não inclui lista de erros comuns/checklist de
    equipamento (EXERCISE_MEDIA_GUIDE.md §12) — só nome, ilustração
    animada e dose.
  - Revisão profissional de conteúdo/mídia continua pendente (o próprio
    documento exige isso antes de publicação).
  - ~~Pacote de 195 imagens reais descoberto ao final da sessão~~ —
    **integrado** na continuação seguinte desta mesma sessão. Ver seção
    própria "Integração do pacote de 195 imagens reais" abaixo.
  - **Verificação manual não realizada nesta sessão**: modo avião,
    tela bloqueada e toque duplo físico no aparelho — ver Riscos/
    bloqueios, o `adb` seguiu sem enxergar nenhum dispositivo
    (`adb devices` retornou lista vazia). Critério objetivo cumprido
    via `flutter analyze` + 110 testes automatizados (incluindo um
    teste de widget dedicado a toque duplo e outro ao ciclo completo
    do timer 3-2-1/pausa/retomada/conclusão), mas nenhum dos dois é
    substituto de um teste manual real em dispositivo físico.

## Riscos/bloqueios

- Nenhum bloqueio técnico. Supabase CLI/Docker seguem não instalados,
  irrelevante enquanto o backend estiver pausado.
- Build de release da 2ª leva da sessão anterior (bugs corrigidos +
  avaliação estendida + Evolução) segue **não verificado visualmente no
  aparelho** — o `adb` perdeu o dispositivo antes que desse tempo. Não
  bloqueante (dados desse período sobreviveram à migração e apareceram
  corretos na verificação desta sessão — ver abaixo), mas ninguém
  conferiu essas telas especificamente ainda.
- ~~Verificação manual da história vertical do player por reps+duração
  pendente~~ e ~~verificação manual da integração das 195 imagens
  pendente~~ — **ambas concluídas nesta continuação**, aparelho
  reconectado (`7549GMFUDA4DKZW8`). Ver "Verificação manual no aparelho
  físico" abaixo para o relato completo.

### Verificação manual no aparelho físico (`7549GMFUDA4DKZW8`)

`flutter build apk --release` (100,6 MB — confirma o impacto real das
195 imagens: eram 55,7 MB antes) + `adb install -r`, sem erros.
Confirmado por interação real (`adb shell input tap`, calibrado com
`uiautomator dump` quando necessário) mais leitura de `logcat` completa
do processo do app:

- App abre, tema novo (verde-menta/violeta) renderiza correto, e os
  dados salvos de sessões anteriores sobreviveram à migração 5→6 em
  banco real (Nível 1, 70 XP, histórico de missões — não só em teste
  automatizado com banco em memória).
- Jornada → catálogo de treinos → detalhe do "Treino A": as **3
  imagens reais associadas** (flexão inclinada, agachamento livre,
  prancha completa) aparecem corretas nas miniaturas de 56px; o
  aquecimento (sem associação) cai no boneco animado, como esperado.
- Player de treino: a mesma imagem real aparece ampliada (140px) no
  exercício de repetições, `BoxFit.contain` sem distorção visível.
- Tela de descanso: mostra a imagem real do **próximo** exercício
  corretamente.
- Botão "Senti dor" com o rótulo certo em toda tela (reps, tempo,
  descanso) — confirmado visualmente, não só por `find.text` em teste.
- **Recuperação de série por tempo testada de verdade**: uma série por
  tempo ficou em andamento (44s de 240s) e o app foi reaberto — o
  diálogo "Sessão por tempo interrompida" apareceu com as três opções;
  "Continuar" retomou o cronômetro no ponto exato (03:16 restantes,
  arco de progresso violeta), "Interromper" registrou a série como
  interrompida e voltou ao fluxo normal, "Abandonar sessão" encerrou e
  limpou o estado. Este era um dos quatro testes manuais pendentes do
  pedido original.
- `adb logcat` do processo do app inteiro, do início ao fim da
  verificação: **nenhum crash, nenhuma exceção fatal**.
- **Não testado ainda nesta rodada**: modo avião explícito (o app já é
  100% local, então o risco é baixo, mas não foi exercitado com o
  rádio desligado de propósito), tela bloqueada via
  `KEYCODE_POWER` durante uma série por tempo, e toque duplo físico
  deliberado em "Concluir"/"Registrar série" (o double-tap guard foi
  validado por teste de widget dedicado, não fisicamente no aparelho).
  Ficam para uma próxima verificação, não são bloqueio.
- Achado de processo (não bug do app): `uiautomator dump` voltou a
  abrir sozinho o assistente de acessibilidade "Acesso por interruptor"
  neste aparelho, confirmando o quirk já registrado nesta sessão —
  contornado fechando o assistente e recalibrando toques por
  coordenadas já confirmadas.

### Feedback do usuário usando o app de verdade (2026-07-24)

Depois da verificação manual, o usuário usou o app no próprio fluxo
real (não guiado por mim) e relatou 5 pontos. Só li e registrei —
**nenhuma implementação feita ainda**, a pedido explícito do usuário
("anote para implementarmos futuramente"). Detalhe técnico completo de
cada item, incluindo diagnóstico de código já feito para os dois bugs,
está em `docs/IMPLEMENTATION_BACKLOG.md`:

1. Falta página de Configurações completa (reset de jornada, perfil
   físico para IMC, estimativa de gasto calórico) — enriquece o item
   que já existia no backlog em P2.
2. **Bug diagnosticado**: `TrainingPlanScreen` ("Ver plano da semana
   completo") ainda mostra só a ilustração animada, não as imagens
   reais — a tela nunca foi migrada para `ExerciseMedia`/`mediaSlug`
   quando as 195 imagens foram integradas (só as telas do catálogo de
   treinos novo foram). Ver backlog, seção "bugs reportados pelo uso
   real".
3. **Bug diagnosticado**: texto "Sua próxima missão de treino" sem
   contraste (cinza sobre verde) no card de destaque da Jornada —
   `_NextSessionCard` não define cor de texto própria para o fundo
   `primaryContainer`. Mesma seção do backlog.
4. Pedido de tela de teste físico periódico (a qualquer momento ou a
   cada 15/30 dias), escolhendo quais exercícios reavaliar, com
   recálculo automático das metas semanais — motivado por um caso real:
   o app prescreveu "Flexão na parede" para o usuário mesmo ele já
   conseguindo fazer flexão completa, e não havia como corrigir isso
   facilmente. Registrado em P1 no backlog, cruzado com o item já
   existente de avaliação/progressão dos 4 padrões novos.
5. Pedido para a tela de Treino mostrar a trilha completa de treinos
   (Treino A, B, C... até o avançado), mesmo os bloqueados, para dar
   visão de evolução e motivar o usuário — registrado em P1 no
   backlog, próximo conceitualmente da Tela de Habilidades que já
   estava pendente.

## Próxima tarefa recomendada

Lista completa e priorizada em `docs/IMPLEMENTATION_BACKLOG.md` (P0 →
P3). Resumo do topo da fila agora: (1) os três testes manuais que ainda
faltam no aparelho — modo avião explícito, tela bloqueada durante
série por tempo (`adb shell input keyevent KEYCODE_POWER`), toque
duplo físico deliberado (nenhum é bloqueio, só não foram exercitados
ainda); (2) teste físico periódico/reavaliação sob demanda (P1), que
também resolve o caso de um padrão nunca autoavaliado nunca acumular
confirmações de domínio; (3) trilha completa de treinos visível na tela
de Treino (P1, outro pedido do usuário); (4) revisão profissional de
conteúdo/mídia (bloqueia publicação comercial, precisa de alguém de
fora do projeto).

## Critério para retomar

Ler este arquivo, `docs/IMPLEMENTATION_BACKLOG.md` e
`docs/adr/0006-mvp-local-only.md`. **Todas** as levas desta sessão —
correção de bugs + avaliação estendida + Evolução; história vertical do
player por reps/duração; integração das 195 imagens; correção dos 2
bugs de mídia/contraste; catálogo em camadas para os 4 padrões novos;
mídia real nas telas de avaliação/Evolução — têm verificação
automatizada completa **e** verificação manual real no aparelho físico
(`7549GMFUDA4DKZW8`), incluindo os cenários mais sensíveis a tempo
real/dados reais: recuperação de série por tempo após o app fechar/
reabrir, e regenerar o plano com a colocação real do usuário
prescrevendo corretamente as variações novas por nível. Os únicos
testes manuais ainda não feitos em nenhuma leva são modo avião
explícito, tela bloqueada e toque duplo físico deliberado (ver
`docs/IMPLEMENTATION_BACKLOG.md`, seção P0) — nenhum é bloqueio, o
sistema já foi exercitado de verdade em cenários equivalentes.
