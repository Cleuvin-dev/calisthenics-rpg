# Project Status

**Data:** 2026-07-24
**Responsável:** Claude Code (sessão com Cleuvin)
**Branch/commit:** `main` (working tree com alterações não commitadas — usuário commita manualmente)

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

## Banco/migrations

- Backend Supabase segue pausado (ADR-0006); `supabase/migrations/`
  continua vazio. Sync (`OutboxEvents`) segue reservada e não usada
  (ADR-0005, `core/sync/README.md`).
- Schema local Drift em `schemaVersion = 5` (sem mudança nesta parte da
  sessão — missões/Jornada não têm tabela própria):
  - `1→2`: recria `CapabilityEstimateRecords` (`inputAnchor` opcional).
  - `2→3`: cria `training_plan_records`.
  - `3→4`: cria `workout_session_records` e `set_log_records`.
  - `4→5`: cria `xp_ledger_records`.
  - Todas aceitáveis por não haver dados reais em produção ainda.

## Testes executados

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sem problemas |
| `flutter test` | 84 passed, 0 failed |
| `dart run build_runner build` | OK |
| `flutter build apk --release` | OK (55,6MB) |
| `adb install -r` no aparelho físico | OK, testado manualmente via `adb shell input` |

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
- `JourneyScreen` é a única tela nova de navegação — Habilidades,
  Evolução e Perfil (os outros 3 destinos de SCREENS_AND_FLOWS.md §1)
  não existem, nem navegação por abas.
- Sem timer/descanso, substituição de exercício em tela ou vídeo no
  player (SCREENS_AND_FLOWS.md §4 lista esses itens; ficaram fora do
  escopo da primeira versão do player).
- Promoção de domínio não regenera o plano automaticamente — usuário
  precisa tocar "Gerar novamente" (decisão deliberada, ver acima).
- **Bug pré-existente notado nesta sessão, não corrigido (fora do
  escopo pedido):** `TrainingPlanScreen` recebe o `TrainingPlanRecord`
  por construtor, não observa `latestTrainingPlanProvider` reativamente;
  se o usuário tocar "Gerar novamente" estando dentro dela (chegou via
  `JourneyScreen`, empilhada no Navigator), a tela não atualiza sozinha
  com o novo plano — só reflete ao sair e voltar (quando `JourneyScreen`
  é reconstruída com dados novos). Vale corrigir numa sessão futura.
- **Bug novo encontrado testando no aparelho, não corrigido:** o botão
  de voltar do sistema sai do `WorkoutPlayerScreen` sem marcar a sessão
  como `paused` (fica `inProgress`). Sem perda de dados, mas o status
  fica inconsistente — precisa de `PopScope`/`WillPopScope` chamando a
  mesma lógica do botão de pausar.
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

## Riscos/bloqueios

- Nenhum bloqueio técnico. Supabase CLI/Docker seguem não instalados,
  irrelevante enquanto o backend estiver pausado.

## Próxima tarefa recomendada

Com plano → sessão → registro → domínio → XP → missões → Jornada
fechando o ciclo básico do MVP e o visual já com cara de "game" no
aparelho, as próximas opções naturais são: (a) corrigir os dois bugs
notados em "Pendências" (voltar do sistema não pausa sessão;
`TrainingPlanScreen` não atualiza sozinha após regenerar) — rápido e
evita confusão do usuário; (b) estender avaliação/colocação real para
os demais padrões fundamentais (hoje só push_horizontal tem anchor/
teste), o que destrava progressão, a missão "treinar todos os padrões"
e XP de domínio de verdade neles também; ou (c) uma tela de "Evolução"
(histórico/atributos/recordes, SCREENS_AND_FLOWS.md), que também
destrava a missão "revisar progresso" que ficou de fora desta rodada.

## Critério para retomar

Ler este arquivo e `docs/adr/0006-mvp-local-only.md`. Nada foi instalado
no aparelho físico nesta sessão — qualquer divergência encontrada ao
testar deve ser tratada como bug, não como escopo pendente, a menos que
liste em "Pendências" acima.
